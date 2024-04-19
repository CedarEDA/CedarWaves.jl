using CedarWaves, Test
@testset "convolution" begin
    # Impulse
    s = impulse(1e-12);
    @test integral(s) ≈ 1

    # Conv centered around 0
    s1 = PWL(-1:1, [0,1,0])
    s2 = convolution(s1, s1)
    @test s2(0) ≈ 2/3
    @test s2(-1) ≈ 1/6
    @test s2(1) ≈ 1/6

    s1 = PWL(5:7, [0,1,0])
    s2 = PWL(5:7, [0,1,0])
    s3 = convolution(s1, s2)
    @test s3(12) ≈ 2/3
    @test s3(11) ≈ 1/6
    @test s3(13) ≈ 1/6

    s1 = PWL(5:7, [0,1,0])
    s2 = PWL(-7:-5, [0,1,0])
    s3 = convolution(s1, s2)
    @test s3(0) ≈ 2/3
    @test s3(1) ≈ 1/6
    @test s3(-1) ≈ 1/6
end