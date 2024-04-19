using CedarWaves, Test

@testset "find_min_itr" begin
    s = PWL(0:3, [0.0, 1, -1, 0])
    y, x = CedarWaves.find_min_itr(s)
    @test y == -1.0
    @test x == 2.0
    y, x = CedarWaves.find_min_itr(s, -)
    @test y == 1.0
    @test x == 1.0
end

@testset "segments" begin
    s = sample(PWL(0.0:3.0, [0.0, 1.0, -1.0, 0.0]), 0.1)
    segs = collect(CedarWaves.eachcross(s, [-0.9999, 0.9999], tol=nothing))
    @test length(segs) == 4
    segs = collect(CedarWaves.eachcross(s, [-0.9999, 0.9999], tol=0.1))
    @test length(segs) == 0
end