using CedarWaves, Test

@testset "monotonicity" begin
    sigtypes = [PWL, PWC, PWQuadratic, PWCubic, PWAkima, ArraySignal]
    for Sig in sigtypes
        @testset "$Sig" begin
            @test monotonicity(Sig([0, 1, 3, 3.5, 4], [0, 1, 2, 3, 4]), rising) == 1.0
            @test monotonicity(Sig([0, 1, 3, 3.5, 4], [0, 1, 2, 3, 4]), falling) == 0.0
            @test monotonicity(Sig([0, 1, 3, 3.5, 4], [0, 1, 2, 3, 4]), either) == 1.0
            @test monotonicity(Sig([0, 1, 3, 3.5, 4], [0, 1, 2, 3, 4])) == 1.0
            ans = 0.75
            @test monotonicity(Sig([0, 0.5, 1.5, 3, 4], [0, 1, -2, 3, 4]), rising) ≈ ans
            @test monotonicity(Sig([0, 0.5, 1.5, 3, 4], [0, 1, -2, 3, 4]), falling) ≈ 1-ans
            @test monotonicity(Sig([0, 0.5, 1.5, 3, 4], [0, 1, -2, 3, 4]), either) ≈ ans
            @test monotonicity(Sig([0, 0.5, 1.5, 3, 4], [0, 1, -2, 3, 4])) ≈ ans
            ans = 0.8
            @test monotonicity(yvals(Sig([0, 0.5, 1.5, 3, 4], [0, 1, -2, 3, 4])), rising) ≈ ans
            @test monotonicity(yvals(Sig([0, 0.5, 1.5, 3, 4], [0, 1, -2, 3, 4])), falling) ≈ 1-ans
            @test monotonicity(yvals(Sig([0, 0.5, 1.5, 3, 4], [0, 1, -2, 3, 4])), either) ≈ ans
            @test monotonicity(yvals(Sig([0, 0.5, 1.5, 3, 4], [0, 1, -2, 3, 4]))) ≈ ans
            @test monotonicity([0, 1, -2, 3, 4], rising) ≈ ans
            @test monotonicity([0, 1, -2, 3, 4], falling) ≈ 1-ans
            @test monotonicity([0, 1, -2, 3, 4], either) ≈ ans
            @test monotonicity([0, 1, -2, 3, 4]) ≈ ans

            for i in 1:-1
                ys = unique(rand(100))
                xs = 0:length(ys)-1
                @test monotonicity(Sig(xs, ys), rising) + monotonicity(Sig(xs, ys), falling) == 1.0
            end
        end
    end
end