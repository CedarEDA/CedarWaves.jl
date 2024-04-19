using CedarWaves
using Test

@testset "Mapped Signals" begin
    s1 = PWL(0:3, [0,1,0,-1])

    # simple map
    m1 = MappedYSignal(y->2y, s1)
    @test m1.x == s1.x
    @test m1.y == s1.y .* 2
    @test m1(0.5) == 1
    @test m1(1.5) == 1
    @test m1(2.5) == -1
    @test m1[1].x == xmin(m1)
    @test m1[begin].x == xmin(m1)
    @test m1[end].x == xmax(m1)

    # multi-level map
    m2 = MappedYSignal(abs, m1)
    @test m2.x == s1.x
    @test m2.y == abs.(s1.y .* 2)

    # Exact clip:
    c2 = clip(m2, 1 .. 3)
    @test c2[1].x == 1
    @test c2[end].y == 2

    # Approx clip:
    c3 = clip(float(m2), 0.5 .. 2.5)
    @test c3[begin].x == 0.5
    @test c3[end].x == 2.5
    @test length(c3) == 4

    # Conversions
    f2 = float(m2)
    typeof(f2) <: MappedYSignal
    f2[begin] === (x=0.0, y=0.0)
    f2[end] === (x=3.0, y=2.0)

    # clamp
    cl1 = clamp(s1, -0.5 .. 0.5)
    @test x_eltype(cl1) == Int64
    @test y_eltype(cl1) == Float64
    # Test interpolation
    @test cl1(1) == 0.5
    @test cl1(0.25) == 0.25
    @test cl1(0.5) == 0.5
    @test cl1(0.9) == 0.5
    @test cl1(1.1) == 0.5
    @test cl1(1.5) == 0.5
    @test cl1(2.9) == -0.5
    @test cl1(2.125) == -0.125

    # Scalar ops:
    # +
    ad1 = s1 + 1
    @test ad1(0.5) == 1.5
    ad2 = 1+s1
    @test ad2(0.5) == 1.5
    @test (+s1).y == s1.y
    # -
    su1 = s1 - 1
    @test su1(0.5) == -0.5
    su2 = 1 - s1
    @test su2(0.5) == 0.5
    @test (-s1).y == -(s1.y)
    # *
    mu1 = 2 * s1
    @test mu1(2.5) == -1
    mu2 = s1 * 2
    @test mu2(2.5) == -1
    @test mu1.y == mu2.y
    # /
    di1 = 2 / s1
    @test di1(0) == Inf
    di2 = s1 / 2
    @test di2(1.5) == 0.25
    # ÷
    dv1 = 5 ÷ (s1+2)
    @test dv1(0) == 2
    dv2 = (s1+5) ÷ 2
    @test dv2(1) == 3
    @test dv2(1.1) == 2
    # ^
    sq1 = s1^2
    @test sq1(0.5) == 0.25
    @test sq1(1.5) == 0.25
    @test sq1(2.5) == 0.25
    sq2 = 2^float(s1)
    @test sq2(0) == 1
    @test sq2(1) == 2
    @test sq2(2) == 1
    @test sq2(3) == 0.5


    s2 = PWL(0:3, [0+0im, 1+1im, 0+0im, -1-1im])
    ph1 = phased(s2)
    @test ph1(0.5) == 45  # See issue #50

end
