
########################################
## Chemical Kinetic equations
########################################


@doc """
Chemical kinetic reaction system

```julia
ReactionSystem(X, S, R, K)
```

### Arguments

* `X` : State vector (array of unknowns N x 1)
* `S` : stoichiometric coefficients for reactants (array M x N)
* `R` : stoichiometric coefficients for products (array M x N)
* `K` : reaction rates (array M x 1)

### Example

```julia
function concentration()

    A0 = 0.25
    rateA = 0.333
    rateB = 0.16

    X= { Unknown(A0), Unknown(0.0) }

    S = [ [1, 0] [0, 1] ] ## stoichiometric coefficients for reactants
    R = [ [0, 1] [1, 0] ] ## stoichiometric coefficients for products
    K = [rateA , rateB] ## reaction rates
    
    return ReactionSystem (X, S, R, K)

end
y = sim(model())

""" -> type DocKinetic <: DocTag end


function ReactionEquation (M,F,X,i)
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
    return Equation[ ReactionEquation(M,F,X,i) for i=1:n ]
end



