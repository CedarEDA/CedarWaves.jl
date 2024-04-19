using CedarWaves, Test

function idwarn(y)
    @warn "function was called"
    y
end

@testset "memoization" begin
    s = PWL(1:2, 1:2);
    s1 = CedarWaves.cache(ymap_signal(idwarn, s));
    @test ytype(s) == ytype(s1)
    @test_logs (:warn, "function was called") (:warn, "function was called") yvals(s1)
    @test_nowarn yvals(s1)
    @test yvals(s) == yvals(s1)

    s = s*1im # test complex
    s2 = CedarWaves.cache(ymap_signal(idwarn, s));
    @test ytype(s) == ytype(s2)
    @test_logs (:warn, "function was called") (:warn, "function was called") yvals(s2)
    @test_nowarn yvals(s2)
    @test yvals(s) == yvals(s2)
end