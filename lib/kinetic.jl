
########################################
## Chemical Kinetic equations
########################################


@doc """
# Chemical kinetic reaction system

""" -> type DocKinetic <: DocTag end


function Reaction (M,F,X,i)
    r = size(M,1) ## number of reactions
    Equation[der(X[i]) - sum([ M[i,j] * F[j] for j = 1:r ])]
end

function reactionFlux (K,S,X)
    n = size(S,2) ## number of species
    r = size(S,1) ## number of reactions

    F = cell(r)
    
    for j = 1:r
        ## (reaction rate) * (reactant concentrations)
        F[j] = K[j] * prod ([ S[i,j] == 0.0 ? 1.0 : (X[i] ^ S[i,j]) for i = 1:n])
    end

    F
end
    
function ReactionSystem (X, ## state vector
                         S,  ## stoichiometric coefficients for reactants
                         R,  ## stoichiometric coefficients for products
                         K)  ## reaction rates
    assert(typeof(S) == typeof(R))
    assert(size(K,1) == size(S,1))
    assert(size(X,1) == size(S,2))
    M = sparse(R - S) ## stoichiometric matrix
    n = size(M,2) ## number of species
    r = size(M,1) ## number of reactions
    F = reactionFlux (K,S,X)
    [ Reaction(M,F,X,i) for i=1:n ]
end



