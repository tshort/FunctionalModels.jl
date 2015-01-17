########################################
## Example of a chemical reaction     ##
########################################

export Concentration


@doc* """
A pair of forward and reverse reactions.
The reactions start with an initial concentration of A, A0,
and an initial concentration of 0 for B at time t=0.
""" ->
function Concentration(; A0 = 0.25, rateA = 3.33e-5, rateB = 1.6e-5)

    X= { Unknown(A0), Unknown(0.0) }

    S = [ [1, 0] [0, 1] ] ## stoichiometric coefficients for reactants
    R = [ [0, 1] [1, 0] ] ## stoichiometric coefficients for products
    K = [rateA , rateB] ## reaction rates
    
    ReactionSystem (X, S, R, K)
end
