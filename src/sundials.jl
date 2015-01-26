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
    sm.F.init(ss.t[1], y, yp, r)
    
    return int32(0)   # indicates normal return
end

function daefun(t::Float64, y::N_Vector, yp::N_Vector, r::N_Vector, userdata_ptr::Ptr{Void})
    ss::SimState = unsafe_pointer_to_objref(userdata_ptr)
    sm::Sim = ss.sm

    y  = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    r  = Sundials.asarray(r)
    sm.F.resid(t, y, yp, r)
    return int32(0)   # indicates normal return
end

function rootfun(t::Float64, y::N_Vector, yp::N_Vector, g::Ptr{Sundials.realtype}, userdata_ptr::Ptr{Void})
    ss::SimState = unsafe_pointer_to_objref(userdata_ptr)
    sm::Sim = ss.sm

    y  = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    g  = Sundials.asarray(g, (length(sm.F.event_pos),))
    sm.F.event_at(t, y, yp, g)
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


function setup_sunsim(ss::SimState, reltol, abstol)
    sm = ss.sm
    sm.reltol = reltol
    sm.abstol = abstol
    tstart = ss.t[1]
    neq   = length(ss.y0)
    mem   = Sundials.IDACreate()
    flag  = Sundials.IDASetUserData(mem, ss)
    flag  = Sundials.IDAInit(mem, daefun, tstart, ss.y, ss.yp)
    flag  = Sundials.IDASStolerances(mem, reltol, abstol)
    flag  = Sundials.IDADense(mem, neq)
    flag  = Sundials.IDARootInit(mem, int32(length(sm.F.event_pos)), rootfun)
    id    = float64(copy(sm.id))
    id[id .< 0] = 0.0
    flag  = Sundials.IDASetId(mem, id)
    return SimSundials (mem, ss)
end

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

    flag = Sundials.IDAReInit(mem, t, ss.y, ss.yp)
    
    if flag != Sundials.IDA_SUCCESS
        error("IDAReInit error", flag)
    end
end


@doc* """
The solver that uses Sundials.

See [sim](#sim) for the interface.
""" ->
function sunsim(smem::SimSundials, tstop::Float64, Nsteps::Int, init::Symbol)

    sim_info("starting sunsim()")


    ss = smem.ss
    sm = ss.sm

    # fix up initial values
    for x in sm.discrete_inputs
        push!(x, x.initialvalue)
    end
    ss.y[:] = ss.y0
    ss.yp[:] = ss.yp0

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

    sm.F.resid(tstart, ss.y, ss.yp, rtest)

    mem = smem.mem
    
    flag = Sundials.IDAReInit(mem, tstart, ss.y, ss.yp)

    if any(abs(rtest) .>= sm.reltol)
        flag = Sundials.IDACalcIC(mem, init == :Ya_Ydp ? Sundials.IDA_YA_YDP_INIT : Sundials.IDA_Y_INIT, tstart + tstep)
    end
    
    for idx in 1:Nsteps

        flag = Sundials.IDASolve(mem, t, tret, ss.y, ss.yp, Sundials.IDA_NORMAL)
        yout[idx, 1] = tret[1]
        yout[idx, 2:(Noutputs + 1)] = ss.y[yidx]
        t = tret[1] + tstep
        if flag == Sundials.IDA_SUCCESS
            for (k,v) in sm.y_map
                if v.save_history
                    push!(ss.history.t[k], tret[1])
                    push!(ss.history.x[k], ss.y[k])
                end
            end
            continue
        end
        if flag == Sundials.IDA_ROOT_RETURN 
            retvalr = Sundials.IDAGetRootInfo(mem, jroot)
            for ridx in 1:length(jroot)
                if jroot[ridx] == 1
                    sm.F.event_pos[ridx](tret[1], ss.y, ss.yp, ss)
                elseif jroot[ridx] == -1
                    sm.F.event_neg[ridx](tret[1], ss.y, ss.yp, ss)
                end
                flag = Sundials.IDAReInit(mem, tret[1], ss.y, ss.yp)
                flag = Sundials.IDACalcIC(mem, init == :Ya_Ydp ? Sundials.IDA_YA_YDP_INIT : Sundials.IDA_Y_INIT, tret[1] + tstep/10)
            end
            if ss.structural_change
                sim_info("structural change event found at t = $(t[1]), restarting")
                
                MTime.value = tret[1]

                ## TODO: avoid reflattening, if possible precompute
                ## all possible equations ahead of time

                ## reflatten equations
                eq = sm.eq
                ss = create_simstate(create_sim(elaborate(eq)))
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

sunsim(ss::SimState, tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp) =
    sunsim(setup_sunsim(ss, reltol, abstol), tstop, Nsteps, init)
sunsim(ss::SimState; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp) =
    sunsim(setup_sunsim(ss, reltol, abstol), tstop, Nsteps, init)
    
sunsim(m::Model, tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp) =
    sunsim(create_simstate(m), tstop, Nsteps, reltol, abstol, init)
sunsim(m::Model; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp) =
    sunsim(create_simstate(m), tstop, Nsteps, reltol, abstol, init)
    
sunsim(sm::Sim, tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp) =
    sunsim(create_simstate(sm), tstop, Nsteps, reltol, abstol, init)
sunsim(sm::Sim; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp) =
    sunsim(create_simstate(sm), tstop, Nsteps, reltol, abstol, init)

sunsim(e::EquationSet, tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp) =
    sunsim(create_simstate(e), tstop, Nsteps, reltol, abstol, init)
sunsim(e::EquationSet; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp) =
    sunsim(create_simstate(e), tstop, Nsteps, reltol, abstol, init)

