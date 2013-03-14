


########################################
## Simulation with DASSL              ##
########################################

#
# This uses an interface to the DASSL library to solve a DAE using the
# residual function from above.
# 
# This is quite kludgy and should get better when Julia's C interface
# improves. I use global variables for the callback function and for
# the main variables used in the residual function callback.
#

dllname = Pkg.dir() * "/Sims/lib/daskr.so"
if !isfile(dllname)
    println("*********************************************")
    println("Can't find daskr.so; attempting to compile...")
    println("*********************************************")
    compile_daskr() 
end    
const lib = dlopen(dllname)

function dasslfun(t_in, y_in, yp_in, cj, delta_out, ires, rpar, ipar)
    n = int(unsafe_ref(ipar))
    t = pointer_to_array(t_in, (1,))
    y = pointer_to_array(y_in, (n,))
    yp = pointer_to_array(yp_in, (n,))
    delta = pointer_to_array(delta_out, (n,))
    __DF.resid(t, y, yp, delta)
    return nothing
end
function dasslrootfun(neq, t_in, y_in, yp_in, nrt, rval_out, rpar, ipar)
    n = int(pointer_to_array(ipar, (2,)))
    t = pointer_to_array(t_in, (1,))
    y = pointer_to_array(y_in, (n[1],))
    yp = pointer_to_array(yp_in, (n[1],))
    rval = pointer_to_array(rval_out, (n[2],))
    __DF.event_at(t, y, yp, rval) 
    return nothing
end


function dasslsim(sm::Sim, tstop::Float64, Nsteps::Int)
    # tstop & Nsteps should be in options
println("starting sim()")

    yidx = sm.outputs .!= ""
    ## yidx = map((s) -> s != "", sm.outputs)
    Noutputs = sum(yidx)
    Ncol = Noutputs
    tstep = tstop / Nsteps
    tout = [tstep]
    idid = [int32(0)]
    info = fill(int32(0), 20)
    info[11] = 1    # calc initial conditions (1 or 2) / don't calc (0)
    info[18] = 2    # more initialization info
    
    function setup_sim(sm::Sim, tstart::Float64, tstop::Float64, Nsteps::Int)
        global __sim_structural_change = false
        N = [int32(length(sm.y0))]
        t = [tstart]
        y = copy(sm.y0)
        yp = copy(sm.yp0)
        nrt = [int32(length(sm.F.event_pos))]
        rpar = [0.0]
        rtol = [1e-5]
        atol = [1e-3]
        lrw = [int32(N[1]^2 + 9 * N[1] + 60 + 3 * nrt[1])] 
        rwork = fill(0.0, lrw[1])
        liw = [int32(2*N[1] + 40)] 
        iwork = fill(int32(0), liw[1])
        iwork[40 + (1:N[1])] = sm.id
        ipar = [int32(length(sm.y0)), nrt[1]]
        jac = [int32(0)]
        psol = [int32(0)]
        jroot = fill(int32(0), max(nrt[1], 1))
        ## rtest = zeros(length(sm.y0))
        ## sm.F.resid(tstart, sm.y0, sm.yp0, rtest)
        ## @show rtest

        global __DF = sm.F
         
        # Set up the callback.
        callback = cfunction(dasslfun, Nothing,
                             (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64},
                              Ptr{Int32}, Ptr{Float64}, Ptr{Int32}))
        rt = cfunction(dasslrootfun, Nothing,
                             (Ptr{Int32}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Int32},
                              Ptr{Float64}, Ptr{Float64}, Ptr{Int32}))
        (tout) -> begin
            ccall(dlsym(lib, :ddaskr_), Void,
                  (Ptr{Void}, Ptr{Int32}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, # RES, NEQ, T, Y, YPRIME
                   Ptr{Float64}, Ptr{Int32}, Ptr{Float64}, Ptr{Float64},            # TOUT, INFO, RTOL, ATOL
                   Ptr{Int32}, Ptr{Float64}, Ptr{Int32}, Ptr{Int32},                # IDID, RWORK, LRW, IWORK
                   Ptr{Int32}, Any, Ptr{Int32}, Ptr{Void}, Ptr{Void},      # LIW, RPAR, IPAR, JAC, PSOL
                   Ptr{Void}, Ptr{Int32}, Ptr{Int32}),                              # RT, NRT, JROOT
                  callback, N, t, y, yp, tout, info, rtol, atol,
                  idid, rwork, lrw, iwork, liw, rpar, ipar, jac, psol,
                  rt, nrt, jroot)
             (t,y,yp,jroot)
         end
    end

    simulate = setup_sim(sm, 0.0, tstop, Nsteps)
    yout = zeros(Nsteps, Ncol + 1)

    for idx in 1:Nsteps

        (t,y,yp,jroot) = simulate(tout)

        ## if t[1] * 1.01 > tstop
        ##     break
        ## end
        ## if t[1] > 0.005     #### DEBUG
        ##     break
        ## end
        ## println(y)
        if idid[1] >= 0 && idid[1] <= 5 
            yout[idx, 1] = t[1]
            yout[idx, 2:(Noutputs + 1)] = y[yidx]
            tout = t + tstep
            for (k,v) in sm.y_map
                if v.save_history
                    push!(v.t, t[1])
                    push!(v.x, y[k])
                end
            end
            if idid[1] == 5 # Event found
                for ridx in 1:length(jroot)
                    if jroot[ridx] == 1
                        sm.F.event_pos[ridx](t, y, yp)
                    elseif jroot[ridx] == -1
                        sm.F.event_neg[ridx](t, y, yp)
                    end
                end
                if __sim_structural_change
                    println("")
                    println("Structural change event found at t = $(t[1]), restarting")
                    # Put t, y, and yp values back into original equations:
                    for (k,v) in sm.y_map
                        v.value = y[k]
                    end
                    for (k,v) in sm.yp_map
                        v.value = yp[k]
                    end
                    MTime.value = t[1]
                    # Reflatten equations
                    sm = create_sim(elaborate(sm.eq))
                    global _sm = sm
                    # Restart the simulation:
                    info[1] = 0
                    info[11] = 1    # do/don't calc initial conditions
                    simulate = setup_sim(sm, t[1], tstop, int(Nsteps * (tstop - t[1]) / tstop))
                    yidx = sm.outputs .!= ""
                elseif any(jroot .!= 0)
                    println("event found at t = $(t[1]), restarting")
                    info[1] = 0
                    info[11] = 1    # do/don't calc initial conditions
                end
            end
        elseif idid[1] < 0 && idid[1] > -11
            println("RESTARTING")
            info[1] = 0
        else
            println("DASKR failed prematurely")
            break
        end
    end
    SimResult(yout, [sm.outputs[yidx]])
end
dasslsim(sm::Sim) = dasslsim(sm, 1.0, 500)
dasslsim(sm::Sim, tstop::Float64) = dasslsim(sm, tstop, 500)
dasslsim(m::Model, tstop::Float64, Nsteps::Int)  = dasslsim(create_sim(elaborate(m)), tstop, Nsteps)
dasslsim(m::Model) = dasslsim(m, 1.0, 500)
dasslsim(m::Model, tstop::Float64) = dasslsim(m, tstop, 500)
