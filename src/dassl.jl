


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

@windows_only dllname = Pkg.dir() * "/Sims/deps/daskr$WORD_SIZE.dll"
@unix_only dllname = Pkg.dir() * "/Sims/deps/daskr.so"

hasdassl = true

try
    global lib = dlopen(dllname)
catch
    hasdassl = false
    println("*********************************************")
    println("DASKR not available; dasslsim not available  ")
    println("*********************************************")
end    

function dasslfun(t_in, y_in, yp_in, cj, delta_out, ires, rpar, ipar)
    n = int(pointer_to_array(ipar, (3,)))
    index = n[3]
    (df,history) = __DF[index]
    t = pointer_to_array(t_in, (1,))
    y = pointer_to_array(y_in, (n[1],))
    yp = pointer_to_array(yp_in, (n[1],))
    delta = pointer_to_array(delta_out, (n[1],))
    df.resid(t, y, yp, delta, history)
    return nothing
end
function dasslrootfun(neq, t_in, y_in, yp_in, nrt, rval_out, rpar, ipar)
    n = int(pointer_to_array(ipar, (3,)))
    index = n[3]
    (df,history) = __DF[index]
    t = pointer_to_array(t_in, (1,))
    y = pointer_to_array(y_in, (n[1],))
    yp = pointer_to_array(yp_in, (n[1],))
    rval = pointer_to_array(rval_out, (n[2],))
    df.event_at(t, y, yp, rval, history) 
    return nothing
end

initdassl = @compat Dict(:none => 0, :Ya_Ydp => 1, :Y => 2)

@doc* """
The solver that uses DASKR, a variant of DASSL.

See [sim](#sim) for the interface.
""" ->
function dasslsim(ss::SimState, tstop::Float64=1.0, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool = true)
    # tstop & Nsteps should be in options
    sim_info("starting dasslsim()", 1)

    sm = ss.sm
    for x in sm.discrete_inputs
        push!(x.signal, x.initialvalue)
    end
    ss.y[:] = ss.y0
    ss.yp[:] = ss.yp0
    yidx = sm.outputs .!= ""
    ## yidx = map((s) -> s != "", sm.outputs)
    Noutputs = sum(yidx)
    Ncol = Noutputs
    tstep = tstop / Nsteps
    tout = [tstep]
    idid = [int32(0)]
    info = fill(int32(0), 20)

    constraints = float64(copy(sm.constraints))
    constraints[constraints .< -2] = 0.0
    constraints[constraints .> 2] = 0.0
    has_constraints = any(x -> x < 0.0 || x > 0.0, constraints)
    if has_constraints
        info[10] = 3
    end
    info[11] = initdassl[init]    # calc initial conditions (1 or 2) / don't calc (0)
    info[16] = alg ? 0 : 1    # == 1 to ignore algebraic variables in the error calculation
    info[18] = 2    # more initialization info
    
    function setup_sim(ss::SimState, tstart::Float64, tstop::Float64, Nsteps::Int; reltol::Float64=1e-5, abstol::Float64=1e-3)
        N = [int32(length(ss.y0))]
        t = [tstart]
        y = ss.y
        yp = ss.yp
        sm = ss.sm
        nrt = [int32(length(sm.F.event_pos))]
        rpar = [0.0]
        rtol = [reltol]
        atol = [abstol]
        lrw = [int32(N[1]^3 + 9 * N[1] + 60 + 3 * nrt[1])] 
        rwork = fill(0.0, lrw[1])
        if has_constraints
            liw = [int32(3*N[1] + 40)]
        else
            liw = [int32(2*N[1] + 40)]
        end
        iwork = fill(int32(0), liw[1])
        if has_constraints
            iwork[40 + (1:N[1])] = constraints
            iwork[40 + N[1] + (1:N[1])] = sm.id
        else
            iwork[40 + (1:N[1])] = sm.id
        end
        jac = [int32(0)]
        psol = [int32(0)]
        jroot = fill(int32(0), max(nrt[1], 1))
        ## rtest = zeros(length(sm.y0))
        ## sm.F.resid(tstart, sm.y0, sm.yp0, rtest)
        ## @show rtest

        index = convert(Cint,length(__DF)+1)
        push!(__DF, (sm.F,ss.history))
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
    for (k,v) in sm.y_map
        if v.save_history
            push!(ss.history.t[k], 0.0)
            push!(ss.history.x[k], ss.y0[k])
        end
    end
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
                        sm.F.event_pos[ridx](t, y, yp, ss)
                    elseif jroot[ridx] == -1
                        sm.F.event_neg[ridx](t, y, yp, ss)
                    end
                end
                if ss.structural_change
                    sim_info("Structural change event found at t = $(t[1]), restarting", 2)
                    # Put t, y, and yp values back into original equations:
                    MTime.value = t[1]
                    # Reflatten equations
                    ss = create_simstate(create_sim(elaborate(sm.eq)))
                    sm = ss.sm
                    
                    # Restart the simulation:
                    info[1] = 0
                    info[11] = initdassl[init]    # do/don't calc initial conditions
                    simulate = setup_sim(ss, t[1], tstop, int(Nsteps * (tstop - t[1]) / tstop), reltol=reltol, abstol=abstol)
                    yidx = sm.outputs .!= ""
                elseif any(jroot .!= 0)
                    sim_info("event found at t = $(t[1]), restarting", 2)
                    info[1] = 0
                    info[11] = initdassl[init]    # do/don't calc initial conditions
                end
            end
        elseif idid[1] < 0 && idid[1] > -11
            sim_info("RESTARTING", 2)
            info[1] = 0
        else
            error("DASKR failed prematurely")
            break
        end
    end
    SimResult(yout, [sm.outputs[yidx]])
end
dasslsim(ss::SimState; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(ss, tstop, Nsteps, reltol, abstol, init, alg)
    
dasslsim(m::Model, tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(m), tstop, Nsteps, reltol, abstol, init, alg)
dasslsim(m::Model; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(m), tstop, Nsteps, reltol, abstol, init, alg)
    
dasslsim(sm::Sim, tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(sm), tstop, Nsteps, reltol, abstol, init, alg)
dasslsim(sm::Sim; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(sm), tstop, Nsteps, reltol, abstol, init, alg)

dasslsim(e::EquationSet, tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(e), tstop, Nsteps, reltol, abstol, init, alg)
dasslsim(e::EquationSet; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(e), tstop, Nsteps, reltol, abstol, init, alg)
