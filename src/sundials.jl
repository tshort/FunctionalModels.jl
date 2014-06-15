using Sundials

import Sundials.N_Vector, Sundials.nvector

function initfun(u::N_Vector, r::N_Vector, userdata)
    n = length(__sm.y0)
    nu = int(Sundials.nvlength(u))
    y = pointer_to_array(Sundials.N_VGetArrayPointer_Serial(u), (n,))
    yp = nu - n > 0 ? pointer_to_array(Sundials.N_VGetArrayPointer_Serial(u) + n, (nu - n,)) : []
    r = Sundials.asarray(r)
    __sm.F.init(__sm.t[1], y, yp, r)
    return int32(0)   # indicates normal return
end
function daefun(t::Float64, y::N_Vector, yp::N_Vector, r::N_Vector, userdata)
    y = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    r = Sundials.asarray(r)
    __sm.F.resid(t, y, yp, r)
    return int32(0)   # indicates normal return
end
function rootfun(t::Float64, y::N_Vector, yp::N_Vector, g::Ptr{Sundials.realtype}, userdata)
    y = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    g = Sundials.asarray(g, (length(__sm.F.event_pos),))
    __sm.F.event_at(t, y, yp, g)
    return int32(0)   # indicates normal return
end

function inisolve(sm::Sim) # initial conditions
    global __sm = sm
    kmem = Sundials.KINCreate()
    u = [sm.y0, sm.yp0[sm.id .> 0]]
    neq = length(u)
    flag = Sundials.KINInit(kmem, initfun, u)
    flag = Sundials.KINDense(kmem, neq)
    scale = ones(neq)
    flag = Sundials.KINSol(kmem, u, Sundials.KIN_NONE, scale, scale) 
    u
end
inisolve(m::Model)  = sunsim(create_sim(elaborate(m)))

function sunsim(sm::Sim, tstop::Float64, Nsteps::Int)
    # tstop & Nsteps should be in options
println("starting sunsim()")

    tstep = tstop / Nsteps
    function setup_sim(sm::Sim, tstart::Float64, tstop::Float64, Nsteps::Int)
        global __sim_structural_change = false
        neq = length(sm.y0)
        mem = Sundials.IDACreate()
        flag = Sundials.IDAInit(mem, daefun, tstart, sm.y0, sm.yp0)
        global __sm = sm
        reltol = 1e-4
        abstol = 1e-3
        flag = Sundials.IDASStolerances(mem, reltol, abstol)
        flag = Sundials.IDADense(mem, neq)
        flag = Sundials.IDARootInit(mem, int32(length(sm.F.event_pos)), rootfun)
        id = float64(copy(sm.id))
        id[id .< 0] = 0
        flag = Sundials.IDASetId(mem, id)
        rtest = zeros(neq)
        sm.F.resid(tstart, sm.y0, sm.yp0, rtest)
        if any(abs(rtest) .>= reltol)
            flag = Sundials.IDACalcIC(mem, Sundials.IDA_YA_YDP_INIT, tstart + tstep)  # IDA_YA_YDP_INIT or IDA_Y_INIT
        end
        return mem
    end
    mem = setup_sim(sm, 0.0, tstop, Nsteps)
    yidx = sm.outputs .!= ""
    Noutputs = sum(yidx)
    Ncol = Noutputs
    
    yout = zeros(Nsteps, Ncol + 1)
    t = tstep
    tret = [0.0]
    nrt = int32(length(sm.F.event_pos))
    jroot = fill(int32(0), nrt)

    for idx in 1:Nsteps

        flag = Sundials.IDASolve(mem, t, tret, sm.y0, sm.yp0, Sundials.IDA_NORMAL)
        yout[idx, 1] = tret[1]
        yout[idx, 2:(Noutputs + 1)] = sm.y0[yidx]
        t = tret[1] + tstep
        if flag == Sundials.IDA_SUCCESS
            for (k,v) in sm.y_map
                if v.save_history
                    push!(v.t, tret[1])
                    push!(v.x, sm.y0[k])
                end
            end
            continue
        end
        if flag == Sundials.IDA_ROOT_RETURN 
            retvalr = Sundials.IDAGetRootInfo(mem, jroot)
            for ridx in 1:length(jroot)
                if jroot[ridx] == 1
                    sm.F.event_pos[ridx](tret[1], sm.y0, sm.yp0)
                elseif jroot[ridx] == -1
                    sm.F.event_neg[ridx](tret[1], sm.y0, sm.yp0)
                end
                flag = Sundials.IDAReInit(mem, tret[1], sm.y0, sm.yp0)
                flag = Sundials.IDACalcIC(mem, Sundials.IDA_YA_YDP_INIT, tret[1] + tstep/10)  # IDA_YA_YDP_INIT or IDA_Y_INIT
            end
            if __sim_structural_change
                println("structural change event found at t = $(t[1]), restarting")
                # put t, y, and yp values back into original equations:
                for (k,v) in sm.y_map
                    v.value = sm.y0[k]
                end
                for (k,v) in sm.yp_map
                    v.value = sm.yp0[k]
                end
                MTime.value = tret[1]
                # reflatten equations
                sm = create_sim(elaborate(sm.eq))
                global __F = sm.F
                global _sm = sm
                # restart the simulation:
                mem = setup_sim(sm, tret[1]+tstep/50, tstop, int(Nsteps * (tstop - t[1]) / tstop))
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

