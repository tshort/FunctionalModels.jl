using ModelingToolkit

@parameters t
const D = Differential(t)
@variables v47(t) v57(t) v66(t) v25(t) i74(t) i75(t) i64(t) i71(t) v1(t) v2(t)

eq = [
 v47 ~ v1
 v47 ~ sin(376.99111843077515t)
 v57 ~ v1 - v2
 v57 ~ 10.0i64
 v66 ~ v2
 v66 ~ 5.0i74
 v25 ~ v2
 i75 ~ 0.005 * D(v25)
 0 ~ i74 + i75 - i64
 0 ~ i64 + i71]


sys = ODESystem(eq, t)
sys1 = structural_simplify(sys)


