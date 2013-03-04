using Sundials

function daefun(t::Float64, y::N_Vector, yp::N_Vector, r::N_Vector, fns::SimFunctions)
    y = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    r = Sundials.asarray(r)
    fns.resid(t, y, yp, r)
    return int32(0)   # indicates normal return
end
function rootfun(t::Float64, y::N_Vector, yp::N_Vector, g::N_Vector, fns::SimFunctions)
    y = Sundials.asarray(y) 
    yp = Sundials.asarray(yp) 
    g = Sundials.asarray(g)
    fns.event_at(t, y, yp, g) 
    return int32(0)   # indicates normal return
end


function sunsim(sm::Sim, tstop::Float64, Nsteps::Int)
    # tstop & Nsteps should be in options
println("starting sunsim()")

    y = sm.y
    yp = sm.yp
    neq = length(y0)
    mem = Sundials.IDACreate()
    flag = Sundials.IDAInit(mem, cfunction(daefun, Int32, (realtype, N_Vector, N_Vector, N_Vector, Function)), tstart, nvector(sm.y0), nvector(sm.yp0))
    flag = Sundials.IDASetUserData(mem, sm.F)
    flag = Sundials.IDARootInit(mem, int32(2), rootfun)
    reltol = 1e-4
    abstol = 1e-6
    flag = Sundials.IDASStolerances(mem, reltol, abstol)
    flag = IDADense(mem, neq)
    
    yidx = sm.outputs .!= ""
    Noutputs = sum(yidx)
    Ncol = Noutputs
    tstep = tstop / Nsteps
    tout = [tstep]
    
    simulate = setup_sim(sm, 0.0, tstop, Nsteps)
    yout = zeros(Nsteps, Ncol + 1)

    for idx in 1:Nsteps

        flag = Sundials.IDASolve(mem, t[k], tout, y, yp, Sundials.IDA_NORMAL)

        yout[idx, 1] = t[1]
        yout[idx, 2:(noutputs + 1)] = y[yidx]
        tout = t + tstep
        for (k,v) in sm.y_map
            if v.save_history
                push!(v.t, t[1])
                push!(v.x, y[k])
            end
        end
        if flag == Sundials.IDA_ROOT_RETURN 
            retvalr = Sundials.IDAGetRootInfo(mem, rootsfound)
            println("roots = ", jroot)
            for ridx in 1:length(jroot)
                if jroot[ridx] == 1
                    sm.f.event_pos[ridx](t, y, yp)
                elseif jroot[ridx] == -1
                    sm.f.event_neg[ridx](t, y, yp)
                end
            end
            if __sim_structural_change
                println("")
                println("structural change event found at t = $(t[1]), restarting")
                # put t, y, and yp values back into original equations:
                for (k,v) in sm.y_map
                    v.value = y[k]
                end
                for (k,v) in sm.yp_map
                    v.value = yp[k]
                end
                mtime.value = t[1]
                # reflatten equations
                sm = create_sim(elaborate(sm.eq))
                global _sm = sm
                # restart the simulation:
                info[1] = 0
                info[11] = 1    # do/don't calc initial conditions
                simulate = setup_sim(sm, t[1], tstop, int(nsteps * (tstop - t[1]) / tstop))
                yidx = sm.outputs .!= ""
            elseif any(jroot .!= 0)
                println("event found at t = $(t[1]), restarting")
                info[1] = 0
                info[11] = 1    # do/don't calc initial conditions
            end
        elseif idid[1] < 0 && idid[1] > -11
            println("restarting")
        else
            println("SUNDIALS failed prematurely")
            break
        end
    end
    simresult(yout, [sm.outputs[yidx]])
end
sunsim(sm::sim) = sunsim(sm, 1.0, 500)
sunsim(sm::sim, tstop::float64) = sunsim(sm, tstop, 500)
sunsim(m::model, tstop::float64, nsteps::int)  = sunsim(create_sim(elaborate(m)), tstop, nsteps)
sunsim(m::model) = sunsim(m, 1.0, 500)
sunsim(m::model, tstop::float64) = sunsim(m, tstop, 500)

