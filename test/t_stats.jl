using CedarWaves, Test
@testset "stats" begin
    # Advesarial testcase for ymin:
    t = range(0.25, 0.75, length=9)
    y = sinpi.(2*t)
    #ser = Series(t, y)
    s = PWL(t, y)
    s2 = s^2
    @test ymax(s2) ≈ s2(0.25)
    @test ymin(s2) ≈ s2(0.5) # adversarial
    @test ymax(s2) ≈ s2(0.75) # adversarial
    @test collect(extrema(s2)) ≈ [s2(0.5), s2(0.75)] # adversarial
    @test peak2peak(s2) ≈ s2(0.25) - s2(0.5) # adversarial
    @test mean(s2) ≈ 0.487 rtol=1e-3
    @test std(s2) ≈ 0.3446 rtol=1e-3
    @test rms(s2) ≈ 0.5968 rtol=1e-3
    @test integral(s2) ≈ 0.2436 rtol=1e-3
    @test xmax(s2) ≈ 0.75
    @test xmin(s2) ≈ 0.25
    @test xspan(s2) ≈ 0.5

end