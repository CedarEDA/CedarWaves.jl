using CedarWaves
using Test

@testset "Mapped Vectors" begin
    s1 = [0,1,0,-1]

    # simple map
    m1 = MappedVector(y->2y, s1)
    @test m1 == s1 .* 2

    # multi-level map
    m2 = MappedVector(abs, m1)
    @test m2 == abs.(s1 .* 2)

    # interfaces:
    m3 = MappedVector(float, m2)
    @test firstindex(m1) == 1
    @test lastindex(m1) == 4
    @test eltype(m3) == Float64
    @test size(m3) == (4,)
    @test size(m3, 1) == 4
    @test length(m3) == size(m3, 1)
    @test [el for el in m3] == m3
    @test_throws ErrorException m3[1] = 5

end
