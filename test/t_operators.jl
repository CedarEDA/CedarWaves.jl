using CedarWaves, Test

@testset "operators" begin
    R=2000
    C=3e-9
    τ = R*C
    t = range(0, 10τ, length=1001)
    ht = @. 1/τ * exp(-t/τ) # impulse response
    s = PWL(t, ht)
    isdefined(Main, :plot) && plot(s)
    c = s(0)
    # Binary ops
    # signal op signal
    @test (s/s)(0) == 1.0
    @test (s/s)(τ) == 1.0
    @test (s/s)(10τ) == 1.0
    # signal op scalar
    @test s(0)/c == 1.0
    @test (s/c)(0) == 1.0
    @test (s/s(0))(0) == 1.0
    # scalar op signal
    @test c/s(0) == 1.0
    @test (c/s)(0) == 1.0
    @test (s(0)/s)(0) == 1.0

end