#####################################################################
## Example of a chemical reaction with non-negative constraints    ##
#####################################################################

export ConcentrationWithConstraints, SimpleConcentrationWithConstraints

typealias Species Unknown{DefaultUnknown,NonNegative}


"""
A pair of forward and reverse reactions.
The reactions start with an initial concentration of A, A0,
and an initial concentration of 0 for B at time t=0.
"""
function ConcentrationWithConstraints(; A0 = 0.25, rateA = 0.333, rateB = 0.16)

    X= Any[ Species("A", A0), Species("B", 0.0) ]

    S = [ 1 0; 0 1 ] ## stoichiometric coefficients for reactants
    R = [ 0 1; 1 0 ] ## stoichiometric coefficients for products
    K = [rateA , rateB] ## reaction rates
    
    return ReactionSystem(X, S, R, K)
end

"""
A pair of forward and reverse reactions, using the simple reaction syntax.
The reactions start with an initial concentration of A, A0,
and an initial concentration of 0 for B at time t=0.
"""
function SimpleConcentrationWithConstraints(; A0 = 0.25, rateA = 0.333, rateB = 0.16)

    A = Species("A", A0)
    B = Species("B", 0.0)
    
    reactions = Any[
                     [ :-> A B rateA ]
                     [ :-> B A rateB ]
                   ]

    return parse_reactions(reactions)
end
