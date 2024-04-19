using CedarWaves
using Test 

@testset "phase" begin
    xs = 0:3
    ys = [0+0im, 1+1im, -1+0im, 0-1im]
    s1 = PWL(xs, ys)

    # phased
    @test phased(2) == 0
    @test phased(-2) == 180
    @test phased(im) == 90
    @test phased(-im) == -90
    @test phased(s1).(xs) == [0.0, 45.0, 180.0, -90.0]
    # phase
    @test phase(2) == 0
    @test phase(-2) ≈ pi
    @test phase(im) ≈ pi/2
    @test phase(-im) ≈ -pi/2
    @test phase(s1).(xs) ≈ [0.0, pi/4, pi, -pi/2]
    # angle
    @test angle(s1).(xs) ≈ [0.0, pi/4, pi, -pi/2]
end