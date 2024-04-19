using CedarWaves, Test


const MO = CedarWaves.MeasureOptions
@testset "MeasureOptions" begin
    mo = MO(Dict(:a=>5, :b=>12))
    @test mo.a == 5
    @test mo.b == 12
    @test mo.dict == Dict(:a=>5, :b=>12)
    # Test defaults:
    @test mo.sigdigits == 5
    @test mo.trace == true
    # Change defaults:
    CedarWaves.MEASURE_DEFAULTS[:sigdigits] = 6
    CedarWaves.MEASURE_DEFAULTS[:trace] = false
    # Existing options update to new defaults:
    @test mo.sigdigits == 6
    @test mo.trace == false

    # Reset defaults back to original:
    CedarWaves.MEASURE_DEFAULTS[:sigdigits] = 5
    CedarWaves.MEASURE_DEFAULTS[:trace] = true
    @test CedarWaves.MEASURE_DEFAULTS[:sigdigits] == 5 # add property dict in future
    @test CedarWaves.MEASURE_DEFAULTS[:trace] == true # add property dict in future

    # Test kwargs method
    mo = MO(c=10, d=12)
    @test mo.c == 10
    @test mo.d == 12
    @test_throws ErrorException mo.missing

    # Passed in options take precedence over defaults (without changing the defaults):
    mo = MO(sigdigits = 20, trace = false)
    @test mo.sigdigits == 20
    @test mo.trace == false
    @test CedarWaves.MEASURE_DEFAULTS[:trace] == true
    @test CedarWaves.MEASURE_DEFAULTS[:sigdigits] == 5

    # Test propertynames
    mo = MO(a=5, b=12, c=10)
    @test propertynames(mo) == [:a, :b, :c, :sigdigits, :trace]
    # Test getindex
    mo = MO(c=10, d=12)
    @test mo[:c] == 10
    @test mo[:d] == 12
    @test mo[:sigdigits] == 5
    @test mo[:trace] == true

    @test length(mo) == 4
    p = propertynames(mo)
    @test mo[1] == mo[p[1]]
    @test mo[2] == mo[p[2]]
    @test mo[3] == mo[p[3]]
    @test mo[4] == mo[p[4]]
    @test_throws BoundsError mo[5]

    # Test haskey
    mo = MO(a=1, b=2, c=3)
    @test haskey(mo, :a)
    @test haskey(mo, :sigdigits)
    @test !haskey(mo, :value)
    @test !haskey(mo, :d)

    # Iteration
    mo = MO(a=1)
    p = propertynames(mo)
    @test iterate(mo) == (p[1] => mo[p[1]], 2)
    @test iterate(mo, 2) == (p[2] => mo[p[2]], 3)
    @test iterate(mo, 3) == (p[3] => mo[p[3]], 4)
    @test iterate(mo, 4) === nothing

    # setindex!
    mo = MO()
    mo.max = 1.2
    @test mo.max == 1.2
    mo.min = 0.2
    @test mo.min == 0.2
end

using CedarWaves, Test
@testset "Measure Primatives" begin
    s1 = PWL(Float64[-2, 2], Float64[-10, 10])
    x = 5/9
    y = 5x
    x1 = XMeasure(s1, x)
    @test CedarWaves.get_value(x1) == x
    @test x1.name == "XMeasure"
    @test x1 == x
    @test x1.value == x
    @test x1.x == x
    @test x1.y ≈ y
    @test x1.slope == 5.0
    @test propertynames(x1) == [:value, :name, :signal, :x, :options, :y, :slope]
    inspect(x1)
    x1 = XMeasure(s1, x, name="x1", sigdigits=3)
    @test x1.name == "x1"
    inspect(x1)

    s1 = PWL(Float64[-2, 2], Float64[-10, 10])
    x = NaN
    x1 = XMeasure(s1, x, name="XMeasure NaN")
    @test CedarWaves.get_value(x1) === x
    @test x1.name == "XMeasure NaN"
    @test isnan(x1)
    @test isnan(x1.value)
    @test isnan(x1.x)
    # @test isnan(x1.y)
    # @test isnan(x1.slope)
    @test propertynames(x1) == [:value, :name, :signal, :x, :options, :y, :slope]
    # inspect(x1)

    s1 = PWL(Float64[-2, 2], Float64[-10, 10])
    x = 5/9
    y = 5x
    x1 = YMeasure(s1, x)
    @test CedarWaves.get_value(x1) ≈ y
    @test x1.name == "YMeasure"
    @test x1 ≈ y
    @test x1.value ≈ y
    @test x1.x == x
    @test x1.y ≈ y
    @test x1.slope == 5.0
    @test propertynames(x1) == [:value, :name, :signal, :x, :options, :y, :slope]
    inspect(x1)
    x1 = YMeasure(s1, 5/9, name="x1", sigdigits=3)
    @test x1.name == "x1"
    inspect(x1)

    # x = NaN
    # y = NaN
    # x1 = YMeasure(s1, x, name="YMeasure NaN")
    # @test isnan(CedarWaves.get_value(x1))
    # @test x1.name == "YMeasure NaN"
    # @test isnan(x1)
    # @test isnan(x1.value)
    # @test isnan(x1.x)
    # @test isnan(x1.y)
    # @test isnan(x1.slope)
    # @test propertynames(x1) == [:value, :name, :signal, :x, :options, :y, :slope]
    # inspect(x1)


    s1 = PWL(Float64[-2, 2], Float64[-10, 10])
    x = 5/9
    y = 5x
    x1 = YLevelMeasure(s1, y)
    @test CedarWaves.get_value(x1) ≈ y
    @test x1.name == "YLevelMeasure"
    @test x1 ≈ y
    @test x1.value ≈ y
    @test_throws ErrorException x1.x
    @test x1.y ≈ y
    @test_throws ErrorException x1.slope
    @test propertynames(x1) == [:value, :name, :signal, :y, :options]
    inspect(x1)
    x1 = YLevelMeasure(s1, x, name="x1", sigdigits=3)
    @test x1.name == "x1"
    inspect(x1)

    s1 = PWL(Float64[-2, 2], Float64[-10, 10])
    x = NaN
    y = NaN
    x1 = YLevelMeasure(s1, y)
    @test isnan(CedarWaves.get_value(x1))
    @test x1.name == "YLevelMeasure"
    @test isnan(x1)
    @test isnan(x1.value)
    @test_throws ErrorException x1.x
    @test isnan(x1.y)
    @test_throws ErrorException x1.slope
    @test propertynames(x1) == [:value, :name, :signal, :y, :options]
    inspect(x1)

    s1 = PWL(Float64[-2, 2], Float64[-10, 10])
    x = 5/9
    y = 5x
    m1 = XMeasure(s1, -x)
    m2 = XMeasure(s1, x)
    dm = DelayMeasure(m1, m2)
    @test CedarWaves.get_value(dm) == 2x
    @test dm.name == "DelayMeasure"
    @test dm ≈ 2x
    @test dm.value ≈ 2x
    @test dm.pt1.x == -x
    @test dm.pt2.x == x
    @test dm.pt1.y ≈ -y
    @test dm.pt2.y ≈ y
    @test dm.slope ≈ 5.0
    @test propertynames(dm) == [:value, :name, :pt1, :pt2, :options, :dx, :dy, :slope]
    inspect(dm)

    s1 = PWL(Float64[-2, 2], Float64[-10, 10])
    x = NaN
    y = 5x
    m1 = XMeasure(s1, -x)
    m2 = XMeasure(s1, x)
    dm = DelayMeasure(m1, m2)
    @test isnan(CedarWaves.get_value(dm))
    @test dm.name == "DelayMeasure"
    @test isnan(dm)
    @test isnan(dm.value)
    @test isnan(dm.pt1.x)
    @test isnan(dm.pt2.x)
    # @test isnan(dm.pt1.y)
    # @test isnan(dm.pt2.y)
    # @test isnan(dm.slope)
    @test propertynames(dm) == [:value, :name, :pt1, :pt2, :options, :dx, :dy, :slope]
    # inspect(dm)

    s1 = PWL(Float64[-2, 2], Float64[-10, 10])
    x = 5/9
    y = 5x
    m1 = YMeasure(s1, -x)
    m2 = YMeasure(s1, x)
    dm = DyMeasure(m1, m2)
    @test CedarWaves.get_value(dm) ≈ 5*2x
    @test dm.name == "DyMeasure"
    @test dm ≈ 5*2x
    @test dm.value ≈ 5*2x
    @test dm.pt1.x == -x
    @test dm.pt2.x == x
    @test dm.pt1.y ≈ -y
    @test dm.pt2.y ≈ y
    @test dm.slope ≈ 5.0
    @test propertynames(dm) == [:value, :name, :pt1, :pt2, :options, :dx, :dy, :slope]
    inspect(dm)
    x = NaN
    y = 5x
    m1 = YMeasure(s1, -x)
    m2 = YMeasure(s1, x)
    dm = DyMeasure(m1, m2)
    # @test isnan(CedarWaves.get_value(dm))
    @test dm.name == "DyMeasure"
    # @test isnan(dm)
    # @test isnan(dm.value)
    @test isnan(dm.pt1.x)
    @test isnan(dm.pt2.x)
    # @test isnan(dm.pt1.y)
    # @test isnan(dm.pt2.y)
    # @test isnan(dm.slope)
    @test propertynames(dm) == [:value, :name, :pt1, :pt2, :options, :dx, :dy, :slope]
    # inspect(dm)
end

@testset "Measure zero, one, oneunit" begin
    using CedarWaves, Test
    s1 = PWL([0, 1], [-10, 1.0])
    m = cross(s1, 0.5)
    @test zero(m) == 0.0
    @test one(m) == 1.0
    @test oneunit(m) == 1.0

    m = XMeasure(s1, 0.5)
    @test zero(m) == 0.0
    @test one(m) == 1
    @test oneunit(m) == 1

    m = YMeasure(s1, 0.5)
    @test_throws ErrorException zero(m) == 0.0
    @test_throws ErrorException one(m) == 1.0
    @test_throws ErrorException oneunit(m) == 1.0

    m = YLevelMeasure(s1, 0.5)
    @test zero(m) == 0.0
    @test one(m) == 1
    @test oneunit(m) == 1

    m = DerivedMeasure(m, 0.5)
    @test zero(m) == 0.0
    @test one(m) == 1
    @test oneunit(m) == 1

    m1 = cross(s1, 0.25)
    m2 = cross(s1, 0.75)
    m = DelayMeasure(m1, m2)
    @test zero(m) == 0.0
    @test one(m) == 1
    @test oneunit(m) == 1

    m1 = ymax(s1)
    m2 = ymin(s1)
    m = DyMeasure(m1, m2)
    @test_throws ErrorException zero(m) == 0.0
    @test_throws ErrorException one(m) == 1
    @test_throws ErrorException oneunit(m) == 1

    m1 = cross(s1, 0.25)
    m2 = cross(s1, 0.75)
    m = DyMeasure(m1, m2)
    @test_throws ErrorException zero(m) == 0.0
    @test_throws ErrorException one(m) == 1
    @test_throws ErrorException oneunit(m) == 1

    m1 = cross(s1, 0.25)
    m2 = cross(s1, 0.75)
    m = SlopeMeasure(m1, m2)
    @test_throws ErrorException zero(m) == 0.0
    @test_throws ErrorException one(m) == 1
    @test_throws ErrorException oneunit(m) == 1

    m1 = cross(s1, 0.25)
    m2 = cross(s1, 0.75)
    m = CedarWaves.RatioMeasure(m1, m2)
    @test zero(m) == 0.0
    @test one(m) == 1
    @test oneunit(m) == 1

end
using CedarWaves, Test
@testset "Measures" begin
    s1 = PWL(Float64[-2, 2], Float64[-10, 10])
    #y1a, x1a = CedarWaves.optimize_min_point(s1, +)
    y1 = ymin(s1)
    inspect(y1)
    @test y1 == -10.0
    @test y1.value == -10.0
    @test y1.x == -2.0
    @test y1.y == -10.0
    @test y1.options.sigdigits == 5
    @test y1.name == "ymin"
    y2 = ymax(s1)
    inspect(y2)
    @test y2 == 10.0
    @test y2.value == 10.0
    @test y2.x == 2.0
    @test y2.y == 10.0
    @test y2.options.sigdigits == 5
    @test y2.name == "ymax"
    s1 = PWL([-2.0, -1, 2, 3, 4], [-10, -5, NaN, 5, 10])
    #y1a, x1a = CedarWaves.optimize_min_point(s1, +)
    y1 = ymin(s1)
    inspect(y1)
    @test isnan(y1)
    @test isnan(y1.value)
    @test y1.x == 2
    @test isnan(y1.y)
    @test y1.options.sigdigits == 5
    @test y1.name == "ymin"
    y2 = ymax(s1)
    inspect(y2)
    @test isnan(y2)
    @test isnan(y2.value)
    @test y2.x == 2.0
    @test isnan(y2.y)
    @test y2.options.sigdigits == 5
    @test y2.name == "ymax"

    t = -2:0.1:2; y = @. 10*sinpi(2t/4 + 2); s1 = PWL(t, y)
    y1 = CedarWaves.YMeasure(s1, 1, name="ymax", sigdigits=6)
    inspect(y1)
    @test y1 == s1(1)
    @test y1.value == s1(1)
    @test y1.x == 1
    @test y1.name == "ymax"
    @test y1.options.sigdigits == 6
    y2 = CedarWaves.XMeasure(s1, 1, name="cross")
    inspect(y2)
    @test y2 == 1
    @test y2.value == 1
    @test y2.name == "cross"
    @test y2.options.sigdigits == 5
    @test y2.x == 1
    @test y2.y == s1(1)
    x1 = CedarWaves.XMeasure(s1, -1)
    x2 = CedarWaves.XMeasure(s1, 1)
    y3 = CedarWaves.DyMeasure(x1, x2, name="peak2peak")
    inspect(y3)
    @test y3 == s1(1) - s1(-1)
    @test y3.value == s1(1) - s1(-1)
    @test y3.name == "peak2peak"
    @test y3.options.sigdigits == 5
    @test y3.x1 == -1
    @test y3.y1 == s1(-1)
    @test y3.x2 == 1
    @test y3.y2 == s1(1)
    @test y3.dx == 2
    @test y3.dy == s1(1) - s1(-1)
    @test y3.slope == (s1(1) - s1(-1)) / 2
    y4 = CedarWaves.DelayMeasure(XMeasure(s1, -1), XMeasure(s1, 1), name="period")
    inspect(y4)
    @test y4 == 1 - -1
    @test y4.value == 1 - -1
    @test y4.name == "period"
    @test y4.options.sigdigits == 5
    @test y4.x1 == -1
    @test y4.y1 == s1(-1)
    @test y4.x2 == 1
    @test y4.y2 == s1(1)
    @test y4.dx == 2
    @test y4.dy == s1(1) - s1(-1)
    @test y4.slope == (s1(1) - s1(-1)) / 2
    rmsval = 10/sqrt(2)
    y5 = CedarWaves.YLevelMeasure(s1, rmsval, name="rms", sigdigits=6)
    inspect(y5)
    @test y5 == rmsval
    @test y5.value == rmsval
    @test y5.name == "rms"
    @test y5.options.sigdigits == 6
    y6 = CedarWaves.SlopeMeasure(x1, x2, name="slope")
    inspect(y6)
    @test y6 == (s1(1) - s1(-1)) / 2
    @test y6.value == (s1(1) - s1(-1)) / 2
    @test y6.name == "slope"
    @test y6.options.sigdigits == 5
    @test y6.x1 == -1
    @test y6.y1 == s1(-1)
    @test y6.x2 == 1
    @test y6.y2 == s1(1)
    @test y6.dx == 2
    @test y6.dy == s1(1) - s1(-1)
    @test y6.slope == (s1(1) - s1(-1)) / 2
    m1 = mean(s1)
    inspect(m1)
    @test m1 ≈ 0.0 atol=1e-15
    @test m1.value ≈ 0.0 atol=1e-15
    @test m1.name == "mean"
    @test m1.options.sigdigits == 5
    @test m1.y ≈ 0.0 atol=1e-15
    y7 = cross(s1, rising(m1))
    inspect(y7)
    @test y7 ≈ 0.0 atol=1e-15
    @test y7.value ≈ 0.0 atol=1e-15
    @test y7.name == "cross"
    @test y7.options.sigdigits == 5
    @test y7.x ≈ 0.0 atol=1e-15
    @test y7.y ≈ 0.0 atol=1e-15
    y8 = cross(s1, falling(m1))
    inspect(y8)
    @test y8 ≈ 2.0 atol=1e-15
    @test y8.value ≈ 2.0 atol=1e-15
    @test y8.name == "cross"
    @test y8.options.sigdigits == 5
    @test y8.x ≈ 2.0 atol=1e-15
    @test y8.y ≈ 0.0 atol=1e-15
    y9 = cross(s1, either(m1))
    inspect(y9)
    @test y9 ≈ 0.0 atol=1e-15
    @test y9.value ≈ 0.0 atol=1e-15
    @test y9.name == "cross"
    @test y9.options.sigdigits == 5
    @test y9.x ≈ 0.0 atol=1e-15
    @test y9.y ≈ 0.0 atol=1e-15
    y10 = cross(s1, rising(0))
    inspect(y10)
    @test y10 ≈ 0.0 atol=1e-15
    @test y10.value ≈ 0.0 atol=1e-15
    @test y10.name == "cross"
    @test y10.options.sigdigits == 5
    @test y10.x ≈ 0.0 atol=1e-15
    @test y10.y ≈ 0.0 atol=1e-15
    # this is now a crossing at 0 because we're less picky about
    # the signal having to start strictly above the threshold
    # y11 = cross(s1, falling(0))
    # inspect(y11)
    # @test isnan(y11)
    # @test isnan(y11.value)
    # @test y11.name == "cross"
    # @test y11.options.sigdigits == 5
    # @test isnan(y11.x)
    # @test isnan(y11.y)
    # y12 = cross(s1, either(0))
    # inspect(y12)
    # @test y12 ≈ -0.0
    # @test y12.value ≈ 0.0
    # @test y12.name == "cross"
    # @test y12.options.sigdigits == 5
    # @test y12.x ≈ -0
    # @test y12.y ≈ 0.0
    s2 = xshift(s1, 1) + 2.0
    y10s = cross(s2, falling(-5))
    inspect(y10s)
    y13 = CedarWaves.DelayMeasure(y10, y10s, name="two_signal_dx")
    inspect(y13)
    @test y13.signal1 == y10.signal
    @test y13.signal2 == y10s.signal
    @test y13 ≈ -0.5059559923950158
    @test y13.value ≈ -0.5059559923950158
    @test y13.name == "two_signal_dx"
    @test y13.options.sigdigits == 5
    @test y13.x1 ≈ 0.0
    @test y13.y1 ≈ s1(0.0)
    @test y13.x2 ≈ -0.5059559923950158
    @test y13.y2 ≈ s2(-0.5059559923950158)
    @test y13.dx ≈ -0.5059559923950158
    @test y13.dy ≈ s2(-0.5059559923950158) - s1(0)
    @test y13.slope ≈ (s2(-0.5059559923950158) - s1(0)) / (-0.5059559923950158 - 0)
    y14 = CedarWaves.DyMeasure(y10, y10s, name="two_signal_dy")
    inspect(y14)
    @test y14.signal1 == y10.signal
    @test y14.signal2 == y10s.signal
    @test y14 == s2(y10s.x) - s1(y10.x)
    @test y14.value == s2(y10s.x) - s1(y10.x)
    @test y14.name == "two_signal_dy"
    @test y14.options.sigdigits == 5
    @test y14.x1 == y10.x
    @test y14.y1 == s1(y10.x)
    @test y14.x2 == y10s.x
    @test y14.y2 == s2(y10s.x)
    @test y14.dx == y10s.x - y10.x
    @test y14.dy == y10s.y - y10.y
    @test y14.slope == (y10s.y - y10.y) / (y10s.x - y10.x)
    y15 = CedarWaves.SlopeMeasure(y10, y10s, name="two_signal_slope")
    inspect(y15)
    @test y15.signal1 == y10.signal
    @test y15.signal2 == y10s.signal
    @test y15 == (y10s.y - y10.y) / (y10s.x - y10.x)
    @test y15.value == y15
    @test y15.name == "two_signal_slope"
    @test y15.options.sigdigits == 5
    @test y15.x1 == y10.x
    @test y15.y1 == y10.y
    @test y15.x2 == y10s.x
    @test y15.y2 == y10s.y
    @test y15.dx == y10s.x - y10.x
    @test y15.dy == y10s.y - y10.y
    @test y15.slope == y15.value


    t = 0:0.005:1
    freq = 2
    y = @. 0.5*(1 + sin(2pi*freq*t) + 1/3*sin(2pi*freq*3t) + 1/5*sin(2pi*freq*5t));
    s1 = PWL(t, y)
    y1, y2 = extrema(s1)
    supply_levels = (0, 1)
    @test risetime(s1; supply_levels) ≈ 0.035183889689773595

    t = 0:0.00005:1
    siny(; t, phase, freq) = (d = phase/(2pi*freq); PWL(t, @.(0.5*(1 + sin(2pi*freq*(t+d)) + 1/3*sin(2pi*freq*3(t+d)) + 1/5*sin(2pi*freq*5(t+d))))))
    s1 = siny(; t, phase=0, freq=3)
    s2 = siny(; t, phase=-pi/4, freq=3)

    # We are shifting in time by (1/freq)/(phase/2pi)
    t_shift = (1/3)/8
    ds = delays(s1, s2; supply_levels, dir1=falling, dir2=falling)
    @test length(ds) == 3
    @test allequal(round.(ds, sigdigits=4))
    @test round(ds[1], sigdigits=4) == round(t_shift, sigdigits=4)
    @test round(delay(s1, s2; supply_levels), sigdigits=4) == round(t_shift, sigdigits=4)

    d1 = delay(s1, s2; supply_levels)
    inspect(d1)
    d1 =  delay(s1, s2; supply_levels, dir1=falling, dir2=falling)
    d1 ≈ 0.25
    inspect(d1)
    rt = risetime(s1; supply_levels)
    @test round(rt.value, sigdigits=5) == 0.023302
    ft = falltime(s1; supply_levels)
    @test round(ft.value, sigdigits=5) == 0.023302
    @test (rt + ft)/2 == (rt.value + ft.value)/2

    tri = PWL(1:3, [-1, 1, -1])
    @test dutycycle(tri, 0) == 0.5
    @test dutycycle(tri, 0.5) == 0.25
    @test dutycycle(tri, -0.5) == 0.75

end

@testset "Measures Plot" begin
    using CedarWaves, Test, Plots
    s0 = PWL([-2, 2], [-10, 10])
    y1 = ymin(s0)
    inspect(y1)
    #plot(y1)
    y2 = ymax(s0)
    #plot(y2)
    t = -2:0.1:2; y = @. 10*sinpi(2t/4 + 2); s1 = PWL(t, y)
    y1 = CedarWaves.YMeasure(s1, 1, name="ymax", sigdigits=6)
    inspect(y1)
    #plot(y1)
    y2 = CedarWaves.XMeasure(s1, 1, name="cross")
    inspect(y2)
    #plot(y2)
    x1 = CedarWaves.XMeasure(s1, -1)
    x2 = CedarWaves.XMeasure(s1, 1)
    x3 = CedarWaves.XMeasure(s0, 1)
    y3 = CedarWaves.DyMeasure(x1, x2, name="peak2peak")
    inspect(y3)
    #plot(y3)
    y3 = CedarWaves.DyMeasure(x1, x3)
    inspect(y3)
    #plot(y3)
    y4 = CedarWaves.DelayMeasure(x1, x2, name="period")
    #plot(y4)
    y4 = CedarWaves.DelayMeasure(x1, x3, name="a measure")
    inspect(y4)
    #plot(y4)
    rmsval = 10/sqrt(2)
    y5 = CedarWaves.YLevelMeasure(s1, rmsval, name="rms", sigdigits=6)
    inspect(y5)
    #plot(y5)

    y6 = CedarWaves.SlopeMeasure(x1, x2, name="slope")
    inspect(y6)
    #plot(y6)
    y6 = CedarWaves.SlopeMeasure(x1, x3, name="slope")
    inspect(y6)
    #plot(y6)
    m1 = mean(s1)
    inspect(m1)
    #plot(m1)
    @test m1 ≈ 0.0 atol=1e-15
    y7 = cross(s1, rising(m1))
    inspect(y7)
    #plot(y7)
    y8 = cross(s1, falling(m1))
    #plot(y8)
    y9 = cross(s1, either(m1))
    #plot(y9)
    y10 = cross(s1, rising(0))
    #plot(y10)
    y11 = cross(s1, falling(0))
    #plot(y11)
    y12 = cross(s1, either(0))
    #plot(y12)
    s2 = xshift(s1, 1) + 2.0
    y10s = cross(s2, falling(-5))
    #plot(y10s)
    y13 = CedarWaves.DelayMeasure(y10, y10s, name="two_signal_dx")
    inspect(y13)
    #plot(y13)
    y14 = CedarWaves.DyMeasure(y10, y10s, name="two_signal_dy")
    inspect(y14)
    #plot(y14)
    y15 = CedarWaves.SlopeMeasure(y10, y10s, name="two_signal_slope")
    inspect(y14)
    #plot(y15)

    t = 0:0.005:1
    freq = 2
    y = @. 0.5*(1 + sin(2pi*freq*t) + 1/3*sin(2pi*freq*3t) + 1/5*sin(2pi*freq*5t));
    s1 = PWL(t, y)
    y1, y2 = extrema(s1)

    s3 = sample(PWL([0.0, 1.0, 2.0], [0.0, 1.0, 0.0]), 0.1)
    supply_levels = extrema(s3)
    @test delay(s3, s3, dir1=rising, dir2=rising; supply_levels) ≈ 0.0
    @test cross(s3, 0.0).value === 0.0
    @test cross(s3, 0.0, N=2).value === 2.0

    tri = PWL(1:3, [-1, 1, -1])
    @test dutycycle(tri, 0) ≈ 0.5
    @test dutycycle(tri, 0.5) ≈ 0.25
    @test dutycycle(tri, -0.5) ≈ 0.75

end

@testset "Measure math" begin
    using CedarWaves, Test
    s1 = PWL([-2, 2], [-10, 10])
    m1 = cross(s1, 5)
    inspect(m1)
    @test m1 == 1

    m2 = m1 - 0.5
    inspect(m2)
    @test m2 == 0.5
    @test m2 isa DelayMeasure
    m2n = 2 - m1
    inspect(m2n)
    @test m2n == 1
    @test m2n isa DelayMeasure

    # Out of domain should convert to Float64:
    m2 = m1 - 100
    @test typeof(m2) == Float64


    m3 = cross(s1, -5)
    inspect(m3)
    m4 = m1 - m3
    inspect(m4)
    @test m4 == 2
    @test m4 isa DelayMeasure

end
