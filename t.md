---
title:  Sims Documentation
---

## Unknowns

Models consist of equations and unknown variables. The number of
equations should match the number of unknowns. In Sims, the type
Unknown is used to define unknown variables. Without the constructor
parts, the definition of Unknown is:

```julia
type Unknown{T<:UnknownCategory} <: UnknownVariable
    sym::Symbol
    value         # holds initial values (and type info)
    label::String 
end
```

```python
i = 32
funcall("test") # hello
```

```javascript
var i = 32;
funcall("test"); // hello
```
