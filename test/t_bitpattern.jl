using CedarWaves, Test

@testset "bitpattern" begin
    seq = Bool[1, 0, 0, 1, 0, 1]
    vdd = 1.2
    vss = 0.0
    supply_levels=(vss, vdd)
    trise = 1
    tfall = 3
    tdelay = 1
    tbit = 10
    s = bitpattern(seq; tbit, trise, tfall, tdelay, supply_levels)
    s2 = sample(s, 0.1)
    @test cross(s2, vdd/2) ≈ 11.0
    @test cross(s2, rising(vdd/2)) ≈ 31.0
    ft = falltime(s2; supply_levels)
    @test ft ≈ tfall*(0.8-0.2)
    rt = risetime(s2; supply_levels)
    @test rt ≈ trise*(0.8-0.2)

    s3 = s |> sample(0.1)
    @test cross(s3, vdd/2) ≈ 11.0
    @test cross(s3, rising(vdd/2)) ≈ 31.0
    ft = falltime(s3; supply_levels)
    @test ft ≈ tfall*(0.8-0.2)
    rt = risetime(s3; supply_levels)
    @test rt ≈ trise*(0.8-0.2)
end