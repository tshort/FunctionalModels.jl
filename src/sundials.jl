using Sundials

import Sundials.N_Vector, Sundials.nvector


## Conventions:
##
## __ss is a global array of SimState structures
##
##

__ss = {}

function initfun(u::N_Vector, r::N_Vector, userdata_ptr::Ptr{Void})
    userdata = unsafe_pointer_to_objref(userdata_ptr)
    ss::SimState = __ss[userdata]
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
    userdata = unsafe_pointer_to_objref(userdata_ptr)
    ss::SimState = __ss[userdata]
    sm::Sim = ss.sm
    
    y  = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    r  = Sundials.asarray(r)
    sm.F.resid(t, y, yp, r)
    return int32(0)   # indicates normal return
end

function rootfun(t::Float64, y::N_Vector, yp::N_Vector, g::Ptr{Sundials.realtype}, userdata_ptr::Ptr{Void})
    userdata = unsafe_pointer_to_objref(userdata_ptr)
    ss::SimState = __ss[userdata]
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


function setup_sunsim(ss::SimState, reltol::Float64, abstol::Float64)
    sm = ss.sm
    sm.reltol = reltol
    sm.abstol = abstol
    tstart = ss.t[1]
    index = convert(Cint,length(__ss)+1)
    push!(__ss, ss)
    neq   = length(ss.y0)
    mem   = Sundials.IDACreate()
    flag  = Sundials.IDASetUserData(mem, index)
    flag  = Sundials.IDAInit(mem, daefun, tstart, ss.y0, ss.yp0)
    flag  = Sundials.IDASStolerances(mem, reltol, abstol)
    flag  = Sundials.IDADense(mem, neq)
    flag  = Sundials.IDARootInit(mem, int32(length(sm.F.event_pos)), rootfun)
    id    = float64(copy(sm.id))
    id[id .< 0] = 0
    flag  = Sundials.IDASetId(mem, id)
    return mem
end


function reinit_sunsim(mem, ss::SimState, t)
    sm = ss.sm

    index = convert(Cint,length(__ss)+1)
    push!(__ss, ss)
    neq   = length(ss.y0)
    
    flag  = Sundials.IDASetUserData(mem, index)
    flag  = Sundials.IDARootInit(mem, int32(length(sm.F.event_pos)), rootfun)
    id    = float64(copy(sm.id))
    id[id .< 0] = 0
    flag  = Sundials.IDASetId(mem, id)

    flag = Sundials.IDAReInit(mem, t, ss.y0, ss.yp0)
    
    if flag != Sundials.IDA_SUCCESS
        error("IDAReInit error", flag)
    end
end


function sunsim(mem::Ptr, ss::SimState, tstop::Float64, Nsteps::Int)

    println("starting sunsim()")

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
    sm.F.resid(tstart, ss.y0, ss.yp0, rtest)
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
                    push!(v.t, tret[1])
                    push!(v.x, ss.y0[k])
                end
            end
            continue
        end
        if flag == Sundials.IDA_ROOT_RETURN 
            retvalr = Sundials.IDAGetRootInfo(mem, jroot)
            for ridx in 1:length(jroot)
                if jroot[ridx] == 1
                    sm.F.event_pos[ridx](tret[1], ss.y0, ss.yp0, ss)
                elseif jroot[ridx] == -1
                    sm.F.event_neg[ridx](tret[1], ss.y0, ss.yp0, ss)
                end
                flag = Sundials.IDAReInit(mem, tret[1], ss.y0, ss.yp0)
                flag = Sundials.IDACalcIC(mem, Sundials.IDA_YA_YDP_INIT, tret[1] + tstep/10)  # IDA_YA_YDP_INIT or IDA_Y_INIT
            end
            if ss.structural_change
                println("structural change event found at t = $(t[1]), restarting")
                
                MTime.value = tret[1]

                ## TODO: avoid reflattening, if possible precompute
                ## all possible equations ahead of time
                
                ## reflatten equations
                eq = sm.eq
                ss = create_sim(elaborate(eq))
                sm = ss.sm
                
                ## restart the simulation:
                reinit_sunsim (mem, ss, tret[1])
                
                nrt = int32(length(sm.F.event_pos))
                jroot = fill(int32(0), nrt)
                yidx = sm.outputs .!= ""
                
            elseif any(jroot .!= 0)
                println("event found at t = $(tret[1]), restarting")
            end
        ## elseif flag == Sundials.IDA_??
        ##     println("restarting")
        else
            println("SUNDIALS failed prematurely")
            break
        end
    end
    SimResult(yout, [sm.outputs[yidx]])
end
sunsim(sm::Sim) = sunsim(sm, 1.0, 500)
sunsim(sm::Sim, tstop::Float64) = sunsim(sm, tstop, 500)
sunsim(m::Model, tstop::Float64, nsteps::Int)  = sunsim(create_sim(elaborate(m)), tstop, nsteps)
sunsim(m::Model) = sunsim(m, 1.0, 500)
sunsim(m::Model, tstop::Float64) = sunsim(m, tstop, 500)

