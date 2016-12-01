


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

if is_windows()
    const dllname = Pkg.dir() * "/Sims/deps/daskr$(Sys.WORD_SIZE).dll"
elseif is_linux()
    const dllname = Pkg.dir() * "/Sims/deps/daskr.so"
end

hasdassl = true


function dasslfun(t_in, y_in, yp_in, cj, delta_out, ires, rpar, ipar)
    n = convert(Array{Int}, unsafe_wrap(Array, ipar, (3,)))
    index = n[3]
    df = __DF[index]
    t = unsafe_wrap(Array, t_in, (1,))
    y = unsafe_wrap(Array, y_in, (n[1],))
    yp = unsafe_wrap(Array, yp_in, (n[1],))
    delta = unsafe_wrap(Array, delta_out, (n[1],))
    df.resid(t, y, yp, delta)
    return nothing
end
function dasslrootfun(neq, t_in, y_in, yp_in, nrt, rval_out, rpar, ipar)
    n = convert(Array{Int}, unsafe_wrap(Array, ipar, (3,)))
    index = n[3]
    df = __DF[index]
    t = unsafe_wrap(Array, t_in, (1,))
    y = unsafe_wrap(Array, y_in, (n[1],))
    yp = unsafe_wrap(Array, yp_in, (n[1],))
    rval = unsafe_wrap(Array, rval_out, (n[2],))
    df.event_at(t, y, yp, rval) 
    return nothing
end

initdassl = @compat Dict(:none => 0, :Ya_Ydp => 1, :Y => 2)

"""
The solver that uses DASKR, a variant of DASSL.

See [sim](#sim) for the interface.
"""
function dasslsim(ss::SimState, tstop::Float64, Nsteps::Int=500, reltol::Float64=1e-4, abstol::Float64=1e-4, init::Symbol=:Ya_Ydp, alg::Bool = true)
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
    idid = [Int32(0)]
    info = fill(Int32(0), 20)

    constraints = convert(Array{Int32}, copy(sm.constraints))
    constraints[constraints .< -2] = 0
    constraints[constraints .> 2] = 0
    has_constraints = any(x -> x < 0 || x > 0, constraints)
    if has_constraints
        info[10] = 1
    end
    info[11] = initdassl[init]    # calc initial conditions (1 or 2) / don't calc (0)
    info[16] = alg ? 0 : 1    # == 1 to ignore algebraic variables in the error calculation
    info[17] = 0
    info[18] = 2    # more initialization info
    
    function setup_sim(ss::SimState, tstart::Float64, tstop::Float64, Nsteps::Int; reltol::Float64=1e-5, abstol::Float64=1e-3)
        N = [Int32(length(ss.y0))]
        t = [tstart]
        y = ss.y
        yp = ss.yp
        sm = ss.sm
        nrt = [Int32(length(sm.F.event_pos))]
        rpar = [0.0]
        rtol = [reltol]
        atol = [abstol]
        lrw = [Int32(N[1]^3 + 9 * N[1] + 60 + 3 * nrt[1])] 
        rwork = fill(0.0, lrw[1])
        liw = [Int32(2*N[1] + 40)]
        if has_constraints
            liw = [Int32(3*N[1] + 40)]
        end
        iwork = fill(Int32(0), liw[1])
        if has_constraints
            iwork[40 + (1:N[1])] = constraints
            iwork[40 + N[1] + (1:N[1])] = sm.id
        else
            iwork[40 + (1:N[1])] = sm.id
        end
        jac = [Int32(0)]
        psol = [Int32(0)]
        jroot = fill(Int32(0), max(nrt[1], 1))
        ## rtest = zeros(length(sm.y0))
        ## sm.F.resid(tstart, sm.y0, sm.yp0, rtest)
        ## @show rtest

        index = convert(Cint,length(__DF)+1)
        push!(__DF, sm.F)
        ipar = [Int32(length(ss.y0)), nrt[1], index]
         
        # Set up the callback.
        callback = cfunction(dasslfun, Void,
                             (Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64},
                              Ptr{Int32}, Ptr{Float64}, Ptr{Int32}))
        rt = cfunction(dasslrootfun, Void,
                       (Ptr{Int32}, Ptr{Float64}, Ptr{Float64}, Ptr{Float64}, Ptr{Int32},
                        Ptr{Float64}, Ptr{Float64}, Ptr{Int32}))
        (tout) -> begin
            ccall(Libdl.dlsym(lib, :ddaskr_), Void,
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
                    push!(v.t, t[1])
                    push!(v.x, y[k])
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
                    simulate = setup_sim(ss, t[1], tstop, round(Int, Nsteps * (tstop - t[1]) / tstop), reltol=reltol, abstol=abstol)
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
    SimResult(yout, collect(sm.outputs[yidx]))
end
dasslsim(ss::SimState; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(ss, tstop, Nsteps, reltol, abstol, init, alg)
    
dasslsim(m::Model, tstop,       Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(m), tstop, Nsteps, reltol, abstol, init, alg)
dasslsim(m::Model; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(m), tstop, Nsteps, reltol, abstol, init, alg)
    
dasslsim(sm::Sim, tstop,       Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(sm), tstop, Nsteps, reltol, abstol, init, alg)
dasslsim(sm::Sim; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(sm), tstop, Nsteps, reltol, abstol, init, alg)

dasslsim(e::EquationSet, tstop, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(e), tstop, Nsteps, reltol, abstol, init, alg)
dasslsim(e::EquationSet; tstop = 1.0, Nsteps = 500, reltol = 1e-4, abstol = 1e-4, init = :Ya_Ydp, alg = true) =
    dasslsim(create_simstate(e), tstop, Nsteps, reltol, abstol, init, alg)
