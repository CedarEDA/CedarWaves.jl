using Test
using CedarWaves

@testset "ClippedVector" begin
    v1 = 1:2000
    c1 = ClippedVector(v1, firstindex=3, lastindex=5, first_value=30, last_value=50)
    @test firstindex(c1) == 1
    @test lastindex(c1) == 3
    @test eltype(c1) == Int64
    @test length(c1) == 3
    @test size(c1) == (3, )
    @test c1[begin] == 30
    @test c1[1] == 30
    @test c1[2] == 4
    @test c1[3] == 50
    @test c1[end] == 50
    @test c1[1:3] == [30, 4, 50]
    @test c1[2:2] == [4]  # fast path (no first or last index)
    @test_throws ErrorException c1[2] = 40
    @test eltype(c1) == Int
end