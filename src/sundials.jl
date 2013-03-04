using Sundials

import Sundials.N_Vector, Sundials.nvector

function daefun(t::Float64, y::N_Vector, yp::N_Vector, r::N_Vector, fn::SimFunctions)
    y = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    r = Sundials.asarray(r)
    fn.resid(t, y, yp, r)
    return int32(0)   # indicates normal return
end
function rootfun(t::Float64, y::N_Vector, yp::N_Vector, g::Ptr{Sundials.realtype}, fn::SimFunctions)
    y = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    g = Sundials.asarray(g, (length(fn.event_pos),))
    fn.event_at(t, y, yp, g)
    return int32(0)   # indicates normal return
end


function sunsim(sm::Sim, tstop::Float64, Nsteps::Int)
    # tstop & Nsteps should be in options
println("starting sunsim()")

    tstep = tstop / Nsteps
    nrt = int32(length(sm.F.event_pos))
    global __sim_structural_change = false
    function setup_sim(sm::Sim, tstart::Float64, tstop::Float64, Nsteps::Int, doinit::bool)
        neq = length(sm.y0)
        mem = Sundials.IDACreate()
        flag = Sundials.IDAInit(mem, cfunction(daefun, Int32, (Sundials.realtype, N_Vector, N_Vector, N_Vector, SimFunctions)),
                                0.0, nvector(sm.y0), nvector(sm.yp0))
        flag = Sundials.IDASetUserData(mem, sm.F)
        reltol = 1e-4
        abstol = 1e-3
        flag = Sundials.IDASStolerances(mem, reltol, abstol)
        flag = Sundials.IDADense(mem, neq)
        flag = Sundials.IDARootInit(mem, int32(2),
                                    cfunction(rootfun, Int32, (Sundials.realtype, N_Vector, N_Vector,
                                                               Ptr{Sundials.realtype}, SimFunctions)))
        id = float64(copy(sm.id))
        id[id .< 0] = 0
        flag = Sundials.IDASetId(mem, id)
        if doinit
            flag = Sundials.IDACalcIC(mem, Sundials.IDA_Y_INIT, tstep)  # IDA_YA_YDP_INIT or IDA_Y_INIT
        end
        return mem
    end
    mem = setup_sim(sm, 0.0, tstop, Nsteps, true)
    yidx = sm.outputs .!= ""
    Noutputs = sum(yidx)
    Ncol = Noutputs
    
    yout = zeros(Nsteps, Ncol + 1)
    t = tstep
    tout = [0.0]
    jroot = fill(int32(0), nrt)

    for idx in 1:Nsteps

        flag = Sundials.IDASolve(mem, t, tout, sm.y0, sm.yp0, Sundials.IDA_NORMAL)
        yout[idx, 1] = tout[1]
        yout[idx, 2:(Noutputs + 1)] = sm.y0[yidx]
        t = tout[1] + tstep
        if flag == Sundials.IDA_SUCCESS
            for (k,v) in sm.y_map
                if v.save_history
                    push!(v.t, tout[1])
                    push!(v.x, sm.y0[k])
                end
            end
            continue
        end
        if flag == Sundials.IDA_ROOT_RETURN 
            retvalr = Sundials.IDAGetRootInfo(mem, jroot)
            println("roots = ", jroot)
            for ridx in 1:length(jroot)
                if jroot[ridx] == 1
                    sm.F.event_pos[ridx](t, sm.y0, sm.yp0)
                elseif jroot[ridx] == -1
                    sm.F.event_neg[ridx](t, sm.y0, sm.yp0)
                end
            end
            if __sim_structural_change
                println("")
                println("structural change event found at t = $(t[1]), restarting")
                # put t, y, and yp values back into original equations:
                for (k,v) in sm.y_map
                    v.value = sm.y0[k]
                end
                for (k,v) in sm.yp_map
                    v.value = sm.yp0[k]
                end
                MTime.value = tout[1]
                # reflatten equations
                sm = create_sim(elaborate(sm.eq))
                global _sm = sm
                # restart the simulation:
                mem = setup_sim(sm, tout[1], tstop, int(Nsteps * (tstop - t[1]) / tstop), false)
                nrt = int32(length(sm.F.event_pos))
                jroot = fill(int32(0), nrt)
                yidx = sm.outputs .!= ""
            elseif any(jroot .!= 0)
                println("event found at t = $(t[1]), restarting")
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

