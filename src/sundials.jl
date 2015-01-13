using Sundials

import Sundials.N_Vector, Sundials.nvector


type SimSundials
    mem::Ptr # ptr to sundials memory
    ss::SimState # SimState structure
end

function initfun(u::N_Vector, r::N_Vector, userdata_ptr::Ptr{Void})
    ss::SimState = unsafe_pointer_to_objref(userdata_ptr)
    sm::Sim = ss.sm

    n  = length(ss.y0)
    nu = int(Sundials.nvlength(u))
    y  = pointer_to_array(Sundials.N_VGetArrayPointer_Serial(u), (n,))
    yp = nu - n > 0 ? pointer_to_array(Sundials.N_VGetArrayPointer_Serial(u) + n, (nu - n,)) : []
    r  = Sundials.asarray(r)
    p  = ss.p
    sm.F.init(ss.t[1], y, yp, p, r)
    
    return int32(0)   # indicates normal return
end

function daefun(t::Float64, y::N_Vector, yp::N_Vector, r::N_Vector, userdata_ptr::Ptr{Void})
    ss::SimState = unsafe_pointer_to_objref(userdata_ptr)
    sm::Sim = ss.sm
    
    y  = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    r  = Sundials.asarray(r)
    p  = ss.p
    sm.F.resid(t, y, yp, p, r)
    return int32(0)   # indicates normal return
end

function rootfun(t::Float64, y::N_Vector, yp::N_Vector, g::Ptr{Sundials.realtype}, userdata_ptr::Ptr{Void})
    ss::SimState = unsafe_pointer_to_objref(userdata_ptr)
    sm::Sim = ss.sm

    y  = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    g  = Sundials.asarray(g, (length(sm.F.event_pos),))
    p  = ss.p
    sm.F.event_at(t, y, yp, p, g)
    return int32(0)   # indicates normal return
end

function solve(ss::SimState) # initial conditions
    kmem  = Sundials.KINCreate()
    sm    = ss.sm
    u     = [ss.y0, ss.yp0[sm.id .> 0]]
    neq   = length(u)
    flag  = Sundials.KINInit(kmem, initfun, u)
    flag  = Sundials.KINDense(kmem, neq)
    scale = ones(neq)
    flag  = Sundials.KINSol(kmem, u, Sundials.KIN_NONE, scale, scale)
    u
end
solve(m::Model)  = sunsim(create_sim(elaborate(m)))


function setup_sunsim(ss::SimState; reltol::Float64=1e-4, abstol::Float64=1e-4)
    sm = ss.sm
    sm.reltol = reltol
    sm.abstol = abstol
    tstart = ss.t[1]
    neq   = length(ss.y0)
    mem   = Sundials.IDACreate()
    flag  = Sundials.IDASetUserData(mem, ss)
    flag  = Sundials.IDAInit(mem, daefun, tstart, ss.y0, ss.yp0)
    flag  = Sundials.IDASStolerances(mem, reltol, abstol)
    flag  = Sundials.IDADense(mem, neq)
    flag  = Sundials.IDARootInit(mem, int32(length(sm.F.event_pos)), rootfun)
    id    = float64(copy(sm.id))
    id[id .< 0] = 0
    flag  = Sundials.IDASetId(mem, id)
    return SimSundials (mem, ss)
end
setup_sunsim(sm::Sim; reltol::Float64=1e-4, abstol::Float64=1e-4) = setup_sunsim(create_simstate(sm), reltol=reltol, abstol=abstol)

function reinit_sunsim(smem::SimSundials, ss::SimState, t)

    mem = smem.mem
    sm = ss.sm

    smem.ss = ss
    
    neq   = length(ss.y0)
    
    flag  = Sundials.IDASetUserData(mem, ss)
    flag  = Sundials.IDARootInit(mem, int32(length(sm.F.event_pos)), rootfun)
    id    = float64(copy(sm.id))
    id[id .< 0] = 0
    flag  = Sundials.IDASetId(mem, id)

    flag = Sundials.IDAReInit(mem, t, ss.y0, ss.yp0)
    
    if flag != Sundials.IDA_SUCCESS
        error("IDAReInit error", flag)
    end
end


@doc* """
The solver that uses Sundials.

See [sim](#sim) for the interface.
""" ->
function sunsim(smem::SimSundials, tstop::Float64, Nsteps::Int)

    sim_info("starting sunsim()")


    ss = smem.ss
    sm = ss.sm

    tstart = ss.t[1]
    tstep = (tstop - tstart) / Nsteps
    yidx = sm.outputs .!= ""
    Noutputs = sum(yidx)
    Ncol = Noutputs

    yout = zeros(Nsteps, Ncol + 1)
    t = tstep
    tret = [0.0]
    nrt = int32(length(sm.F.event_pos))
    jroot = fill(int32(0), nrt)

    neq   = length(ss.y0)
    rtest = zeros(neq)

    sm.F.resid(tstart, ss.y0, ss.yp0, ss.p, rtest)

    mem = smem.mem
    
    flag = Sundials.IDAReInit(mem, tstart, ss.y0, ss.yp0)

    if any(abs(rtest) .>= sm.reltol)
        flag = Sundials.IDACalcIC(mem, Sundials.IDA_YA_YDP_INIT, tstart + tstep)  # IDA_YA_YDP_INIT or IDA_Y_INIT
    end
    
    for idx in 1:Nsteps

        flag = Sundials.IDASolve(mem, t, tret, ss.y0, ss.yp0, Sundials.IDA_NORMAL)
        yout[idx, 1] = tret[1]
        yout[idx, 2:(Noutputs + 1)] = ss.y0[yidx]
        t = tret[1] + tstep
        if flag == Sundials.IDA_SUCCESS
            for (k,v) in sm.y_map
                if v.save_history
                    push!(ss.history.t[k], tret[1])
                    push!(ss.history.x[k], ss.y0[k])
                end
            end
            continue
        end
        if flag == Sundials.IDA_ROOT_RETURN 
            retvalr = Sundials.IDAGetRootInfo(mem, jroot)
            for ridx in 1:length(jroot)
                if jroot[ridx] == 1
                    sm.F.event_pos[ridx](tret[1], ss.y0, ss.yp0, ss.p, ss)
                elseif jroot[ridx] == -1
                    sm.F.event_neg[ridx](tret[1], ss.y0, ss.yp0, ss.p, ss)
                end
                flag = Sundials.IDAReInit(mem, tret[1], ss.y0, ss.yp0)
                flag = Sundials.IDACalcIC(mem, Sundials.IDA_YA_YDP_INIT, tret[1] + tstep/10)  # IDA_YA_YDP_INIT or IDA_Y_INIT
            end
            if ss.structural_change
                sim_info("structural change event found at t = $(t[1]), restarting")
                
                MTime.value = tret[1]

                ## TODO: avoid reflattening, if possible precompute
                ## all possible equations ahead of time

                ## preserve any modifications to parameters
                p = copy(ss.p)
                ## reflatten equations
                eq = sm.eq
                ss = create_simstate(create_sim(elaborate(eq)))
                ss.p = p
                sm = ss.sm

                ## restart the simulation:
                reinit_sunsim (smem, ss, tret[1])
                
                nrt = int32(length(sm.F.event_pos))
                jroot = fill(int32(0), nrt)
                yidx = sm.outputs .!= ""
                
            elseif any(jroot .!= 0)
                sim_info("event found at t = $(tret[1]), restarting")
            end
        ## elseif flag == Sundials.IDA_??
        ##     println("restarting")
        else
            error("SUNDIALS failed prematurely (flag = ", flag, ")")
            break
        end
    end
    SimResult(yout, [sm.outputs[yidx]])
end
sunsim(ss::SimState, tstop::Float64, Nsteps::Int; reltol::Float64=1e-4, abstol::Float64=1e-4) =
    sunsim(setup_sunsim(ss,reltol=reltol,abstol=abstol), tstop, Nsteps)
sunsim(sm::Sim, tstop::Float64, Nsteps::Int; reltol::Float64=1e-4, abstol::Float64=1e-4) =
    sunsim(create_simstate(sm), tstop, Nsteps, reltol=reltol, abstol=abstol)
sunsim(sm::Sim; reltol::Float64=1e-4, abstol::Float64=1e-4) =
    sunsim(sm, 1.0, 500, reltol=reltol, abstol=abstol)
sunsim(sm::Sim, tstop::Float64; reltol::Float64=1e-4, abstol::Float64=1e-4) =
    sunsim(sm, tstop, 500, reltol=reltol, abstol=abstol)
sunsim(m::Model, tstop::Float64, nsteps::Int; reltol::Float64=1e-4, abstol::Float64=1e-4)  =
    sunsim(create_sim(elaborate(m)), tstop, nsteps, reltol=reltol, abstol=abstol)
sunsim(m::Model; reltol::Float64=1e-4, abstol::Float64=1e-4) =
    sunsim(m, 1.0, 500, reltol=reltol, abstol=abstol)
sunsim(m::Model, tstop::Float64; reltol::Float64=1e-4, abstol::Float64=1e-4) =
    sunsim(m, tstop, 500, reltol=reltol, abstol=abstol)


