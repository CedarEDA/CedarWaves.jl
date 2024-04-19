using Test
using CedarWaves

@testset "Slew" begin
    @testset "PWL" begin
        @testset "rising" begin
            # Regular tests
            ys = [0.0,0,0,0,1,2,3,4,5,6,6,6,6]
            s = PWL(0.0:length(ys)-1, ys)
            @test risetime(s, yths=[1, 5]) == 4
            # With leading glitch
            ys = [0.0,2,0,1,2,3,4,5,6,6,6,6]
            s = PWL(0.0:length(ys)-1, ys)
            @test risetime(s, yths=[1, 5]) == 4
        end
    end
end