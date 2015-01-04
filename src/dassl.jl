


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

global __DF = Any[]

dllname = Pkg.dir() * "/Sims/deps/daskr.so"
if !isfile(dllname)
    println("*********************************************")
    println("Can't find daskr.so                          ")
    println("*********************************************")
end    
const lib = dlopen(dllname)

function dasslfun(t_in, y_in, yp_in, cj, delta_out, ires, rpar, ipar)
    n = int(pointer_to_array(ipar, (3,)))
    index = n[3]
    df = __DF[index]
    t = pointer_to_array(t_in, (1,))
    y = pointer_to_array(y_in, (n[1],))
    yp = pointer_to_array(yp_in, (n[1],))
    delta = pointer_to_array(delta_out, (n[1],))
    df.resid(t, y, yp, rpar, delta)
    return nothing
end
function dasslrootfun(neq, t_in, y_in, yp_in, nrt, rval_out, rpar, ipar)
    n = int(pointer_to_array(ipar, (3,)))
    index = n[3]
    df = __DF[index]
    t = pointer_to_array(t_in, (1,))
    y = pointer_to_array(y_in, (n[1],))
    yp = pointer_to_array(yp_in, (n[1],))
    rval = pointer_to_array(rval_out, (n[2],))
    df.event_at(t, y, yp, rpar, rval) 
    return nothing
end


function dasslsim(ss::SimState, tstop::Float64, Nsteps::Int; reltol::Float64=1e-4, abstol::Float64=1e-4)
    # tstop & Nsteps should be in options
    sim_info("starting sim()")

    sm = ss.sm
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
    
    function setup_sim(ss::SimState, tstart::Float64, tstop::Float64, Nsteps::Int; reltol::Float64=1e-5, abstol::Float64=1e-3)
        N = [int32(length(ss.y0))]
        t = [tstart]
        y = copy(ss.y0)
        yp = copy(ss.yp0)
        sm = ss.sm
        nrt = [int32(length(sm.F.event_pos))]
        rpar = copy(ss.p)
        rtol = [reltol]
        atol = [abstol]
        lrw = [int32(N[1]^2 + 9 * N[1] + 60 + 3 * nrt[1])] 
        rwork = fill(0.0, lrw[1])
        liw = [int32(2*N[1] + 40)] 
        iwork = fill(int32(0), liw[1])
        iwork[40 + (1:N[1])] = sm.id
        jac = [int32(0)]
        psol = [int32(0)]
        jroot = fill(int32(0), max(nrt[1], 1))
        ## rtest = zeros(length(sm.y0))
        ## sm.F.resid(tstart, sm.y0, sm.yp0, rtest)
        ## @show rtest

        index = convert(Cint,length(__DF)+1)
        push!(__DF, sm.F)
        ipar = [int32(length(ss.y0)), nrt[1], index]
         
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

    simulate = setup_sim(ss, 0.0, tstop, Nsteps, reltol=reltol, abstol=abstol)
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
                    push!(ss.history.t[k], t[1])
                    push!(ss.history.x[k], y[k])
                end
            end
            if idid[1] == 5 # Event found
                for ridx in 1:length(jroot)
                    if jroot[ridx] == 1
                        sm.F.event_pos[ridx](t, y, yp, ss.p, ss)
                    elseif jroot[ridx] == -1
                        sm.F.event_neg[ridx](t, y, yp, ss.p, ss)
                    end
                end
                if ss.structural_change
                    sim_info("Structural change event found at t = $(t[1]), restarting")
                    # Put t, y, and yp values back into original equations:
                    MTime.value = t[1]
                    ## preserve any modifications to parameters
                    p = copy(ss.p)
                    # Reflatten equations
                    ss = create_simstate(create_sim(elaborate(sm.eq)))
                    ss.p = p
                    sm = ss.sm
                    
                    # Restart the simulation:
                    info[1] = 0
                    info[11] = 1    # do/don't calc initial conditions
                    simulate = setup_sim(ss, t[1], tstop, int(Nsteps * (tstop - t[1]) / tstop), reltol=reltol, abstol=abstol)
                    yidx = sm.outputs .!= ""
                elseif any(jroot .!= 0)
                    sim_info("event found at t = $(t[1]), restarting")
                    info[1] = 0
                    info[11] = 1    # do/don't calc initial conditions
                end
            end
        elseif idid[1] < 0 && idid[1] > -11
            sim_info("RESTARTING")
            info[1] = 0
        else
            error("DASKR failed prematurely")
            break
        end
    end
    SimResult(yout, [sm.outputs[yidx]])
end
dasslsim(ss::SimState; reltol::Float64=1e-5, abstol::Float64=1e-3) =
    dasslsim(ss, 1.0, 500, reltol=reltol, abstol=abstol)
dasslsim(ss::SimState, tstop::Float64; reltol::Float64=1e-5, abstol::Float64=1e-3) =
    dasslsim(ss, tstop, 500, reltol=reltol, abstol=abstol)
dasslsim(sm::Sim, tstop::Float64, Nsteps::Int; reltol::Float64=1e-5, abstol::Float64=1e-3) =
    dasslsim(create_simstate(sm), tstop, Nsteps, reltol=reltol, abstol=abstol)
dasslsim(sm::Sim, tstop::Float64; reltol::Float64=1e-5, abstol::Float64=1e-3) =
    dasslsim(create_simstate(sm), tstop, 500, reltol=reltol, abstol=abstol)
dasslsim(m::Model, tstop::Float64, Nsteps::Int; reltol::Float64=1e-5, abstol::Float64=1e-3)  =
    dasslsim(create_sim(elaborate(m)), tstop, Nsteps, reltol=reltol, abstol=abstol)
dasslsim(m::Model; reltol::Float64=1e-5, abstol::Float64=1e-3) =
    dasslsim(m, 1.0, 500, reltol=reltol, abstol=abstol)
dasslsim(m::Model, tstop::Float64; reltol::Float64=1e-5, abstol::Float64=1e-3) =
    dasslsim(m, tstop, 500, reltol=reltol, abstol=abstol)
