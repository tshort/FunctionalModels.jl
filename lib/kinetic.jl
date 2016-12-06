
########################################
## Chemical Kinetic equations
########################################

@comment """
# Chemical kinetics
"""

"""
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
    
    return ReactionSystem(X, S, R, K)

end
y = sim(concentration())
```

```julia
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

    return parse_reactions(reactions)
end

y = sim(simpleConcentration())
```
"""

function ReactionEquation(M,F,X,j)
    r = size(M,1) ## number of reactions
    Equation[der(X[j]) - sum(filter(x -> !(x == 0.0),
                                     [(M[i,j] == 0 ? 0.0 : M[i,j] * F[i]) for i in 1:r]))]
end

function reaction_flux(K,S,X)

    function f(S,X,i,j)
        if S[i,j] == 0.0
            return 1.0
        elseif S[i,j] == 1.0
            return X[j]
        else
            return X[j] ^ S[i,j]
        end
    end
    
    n = size(S,2) ## number of species
    r = size(S,1) ## number of reactions

    F = Array{Any}(r)
    
    for i = 1:r
        ## (reaction rate) * (reactant concentrations)
        F[i] = K[i] * prod(filter(x -> !(x == 1.0),
                                   [ f(S,X,i,j) for j = 1:n]))
    end

    F
end
    
function ReactionSystem(X, ## state vector
                        S,  ## stoichiometric coefficients for reactants
                        R,  ## stoichiometric coefficients for products
                        K)  ## reaction rates
    assert(typeof(S) == typeof(R))
    assert(size(K,1) == size(S,1))
    assert(size(X,1) == size(S,2))
    M = (R - S) ## stoichiometric matrix
    n = size(M,2) ## number of species
    r = size(M,1) ## number of reactions
    F = reaction_flux(K,S,X)
    return Equation[ ReactionEquation(M,F,X,i) for i=1:n ]
end

## 
##
##
    
"""
Parses reactions of the form

```julia
Any[ :-> a b rate ]
Any[ :→ a b rate  ]
Any[ :⇄ a b rate1 rate2 ]
```

### Arguments

* `V` : Vector of reactions

### Example

```julia
    A0 = 0.25
    rateA = 0.333
    rateB = 0.16

    A = Unknown(A0)
    B = Unknown(0.0)

    reactions = Any[
                     [ :⇄ A B rateA rateB ]
                   ]

    parse_reactions(reactions)
```

"""
function parse_reactions(V)

    X = Any[] ## species
    K = Any[] ## reaction rates

    for i = 1:size(V)[1]

        reaction = V[i,:]
        if reaction[1] == :-> || reaction[1] == :→ 
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
        elseif reaction[1] == :⇄
            assert(length(reaction) == 5)
            x = reaction[2]
            y = reaction[3]
            rate1 = reaction[4]
            rate2 = reaction[5]
            if (!(x in X))
                push!(X, x)
            end
            if (!(y in X))
                push!(X, y)
            end
            push!(K, rate1)
            push!(K, rate2)
        else
            error("Unknown reaction type", reaction)
        end
    end

    r = size(V,1) ## number of reactions
    n = size(X,1) ## number of species
    
    ## Stoichiometric coefficients of reactants
    S = Array{Any}(0,n)
    ## Stoichiometric coefficients of products
    R = Array{Any}(0,n)
    c = Array{Any}(1,n)
    c[:] = 0
    i = 1

    for j = 1:size(V)[1]
        reaction = V[j,:]

        if reaction[1] == :-> || reaction[1] == :→ 
            
            x = reaction[2]
            y = reaction[3]

            xi = find(indexin(X, Any[x]))[1]
            yi = find(indexin(X, Any[y]))[1]
            
            S = vcat(S,c)
            R = vcat(R,c)

            S[i,xi] = 1
            R[i,yi] = 1

            i = i + 1
        elseif reaction[1] == :⇄
            
            x = reaction[2]
            y = reaction[3]

            xi = find(indexin(X, Any[x]))[1]
            yi = find(indexin(X, Any[y]))[1]
            
            S = vcat(S,c)
            R = vcat(R,c)

            S[i,xi] = 1
            R[i,yi] = 1

            S = vcat(S,c)
            R = vcat(R,c)

            S[i+1,yi] = 1
            R[i+1,xi] = 1

            i = i + 2
        else 
            error("Unknown reaction type", reaction)
        end
              
    end

    return ReactionSystem(X,S,R,K)
end


