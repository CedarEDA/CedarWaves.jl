
using CedarWaves, Test

@testset "rms" begin
    rms(PWL([1, 1.5, 2, 3], [-1, 0, 1, -1])) ≈ 1/sqrt(3)
    @test rms(Series(1:3, [-1, 1, -1])) ≈ 1.0
    @test rms(PWL([1, 1.5, 2, 3], [-1, 0, 1, -1])) ≈ 1/sqrt(3)
    @test rms(PWC(1:3, [-1, 1, -1])) ≈ 1.0
end