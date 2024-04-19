using CedarWaves
using Test
x = 0:0.2:2pi
y = 10*sin.(x)
s1 = PWL(x, y)
@test round(s1).y == round.(y)
@test round(s1, digits=2).y == round.(y, digits=2)
@test round(Int, s1).y == round.(Int, y)