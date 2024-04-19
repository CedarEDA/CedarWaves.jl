using CedarWaves, Test

@testset "Float32 Float32" begin
    s = PWL(Float32.(0:3), Float32.([0,1,0,1]));
    @test s(0.5) === 0.5
    @test s(0.5f0) === 0.5f0
    @test ymin(s) == 0.0
    @test ymax(s) == 1.0
end

@testset "Int64 Bool" begin
    dig = PWC(0:4, [true, false, false, true, false]);
    @test dig(0) == true
    @test dig(1) == false
    @test dig(0.5) == true
    @test ymin(dig) == false
    @test ymax(dig) == true
end

@testset "FT complex" begin
    pulse = zeropad(PWL(-0.5:0.5, [1, 1]), -1 .. 1)
    ft = sample(FT(pulse), -1:0.1:1)
    @test ytype(ft) == ComplexF64
    yl =  abs(ft)
    @test derivative(yl)(0) == 0
    @test derivative(ft)(0) == 0
end