
###########################################################
## Integrate-and-fire neuron model with refractory period.
###########################################################

export RefractoryLeakyIaF




function RefractoryLeakyIaF(;
                            I   = Parameter(10.0),
                            
                            gL     = 0.1,
                            vL     = -70.0,
                            C      = 1.0,
                            theta  = 20.0 ,
                            vreset = -65.0,
                            trefractory = 5.0,
                            
                            v = Unknown(vreset, "v")
                            )


    function Subthreshold(v)
        @equations begin
            der(v) = ( ((- gL) * (v - vL)) + I) / C
        end
    end

    function RefractoryEq(v)
        @equations begin
            v = vreset
        end
    end    

    function Refractory(v,trefr)
        @equations begin
            StructuralEvent(MTime - trefr,
                            # when the end of refractory period is reached,
                            # switch back to subthreshold mode
                            RefractoryEq(v),
                            () -> Main(v))
        end
    end

    function Main(v)
        @equations begin
            StructuralEvent(v-theta,
                        # when v crosses the threshold,
                            # switch to refractory mode
                            Subthreshold(v),
                            () -> begin
                                trefr = value(MTime)+trefractory
                                Refractory(v,trefr)
                            end)
            
        end
    end

    Main (v)
end


