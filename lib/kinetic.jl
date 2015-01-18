
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
y = sim(concentration())
```


### Simple reaction syntax parser

function simpleConcentration()

    A0 = 0.25
    rateA = 0.333
    rateB = 0.16

    A = Unknown(A0)
    B = Unknown(0.0)
    
    reactions = Any[
                     [ :-> A B rateA ]
                     [ :-> B A rateB ]
                   ]

    return parseReactionSystem (reactions)
end

y = sim(simpleConcentration())



""" ->

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
    M = (R - S) ## stoichiometric matrix
    n = size(M,2) ## number of species
    r = size(M,1) ## number of reactions
    F = reactionFlux (K,S,X)
    return Equation[ ReactionEquation(M,F,X,i) for i=1:n ]
end

## Parses reactions of the form
##
## :-> a b rate 
##
function parseReactionSystem (V)

    X = Any[] ## species
    K = Any[] ## reaction rates
    
    for reaction in V

        if reaction[1] == :-> 
            assert(length(reaction) == 4)
            x = reaction[2]
            y = reaction[3]
            rate = reaction[4]
            if (!(x in X))
                push!(X, x)
            end
            if (!(y in X))
                push!(X, y)
            end
            push!(K, rate)
            
        else
            error("Unknown reaction type", reaction)
        end
    end

    r = size(V,1) ## number of reactions
    n = size(X,1) ## number of species
    
    ## Stoichiometric coefficients of reactants
    S = cell(0,n)
    ## Stoichiometric coefficients of products
    R = cell(0,n)
    c = cell(1,n)
    c[:] = 0
    i = 1
    
    for reaction in V
        if reaction[1] == :->
            
            x = reaction[2]
            y = reaction[3]

            xi = find(indexin(X, Any[x]))[1]
            yi = find(indexin(X, Any[y]))[1]
            
            S = vcat(S,c)
            R = vcat(R,c)

            S[i,xi] = 1
            R[i,yi] = 1

            i = i + 1
        else 
            error("Unknown reaction type", reaction)
        end
              
    end

    return ReactionSystem (X,S,R,K)
end


