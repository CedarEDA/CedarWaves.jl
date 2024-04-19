using CedarWaves, Test

@testset "glitches" begin
    supply_levels=(0.0, 1.0)
    s = PWL(0:21.0, [0, 0, 0.5, 0, 1, 0, 0.5, 0.2, 0.5, 0.2, 0.5, 0.0, 0.5, 0.2, 1, 0.08, 0.5, 0, 1, 0.5, 1, 0])
    gs = glitches(s; supply_levels, full_swing_low_pct=0.1, glitch_max_height_low_pct=0.3)
    @test length(gs) == 4
end

@testset "over/undershoot" begin
    supply_levels = (0, 0.8)
    s = sample(PWL(0:21.0, [0, 0, 0.5, -0.10, 1, 0, 0.5, 0.2, 0.5, 0.2, 0.5, 0.0, 0.5, 0.2, 1, 0.08, 0.5, -0.10, 1, 0.5, 1, 0]), 0.005)
    ov = overshoots(s; supply_levels)
    @test length(ov) == 4
    un = undershoots(s; supply_levels)
    @test length(un) == 2
end