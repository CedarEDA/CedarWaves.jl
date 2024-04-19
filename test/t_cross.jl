using CedarWaves, Test

@testset "PWL crosses" begin
    ys = Float64[0,1,0,2,2]
    xs = float.(eachindex(ys))
    s1 = PWL(xs, ys)
    @test crosses(s1, rising(0.5)) == [1.5, 3.25]
    @test crosses(s1, falling(0.5)) == [2.5]
    @test crosses(s1, either(0.5)) == [1.5, 2.5, 3.25]
    @test crosses(s1, 0.5) == [1.5, 2.5, 3.25]
    #@test_broken crosses(s1, 25pct) == [1.5, 2.5, 3.25]
    #@test_broken crosses(s1, either(25pct)) == [1.5, 2.5, 3.25]
    #@test_broken crosses(s1, rising(25pct)) == [1.5, 3.25]
    #@test_broken crosses(s1, either(25pct)) == [1.5, 2.5, 3.25]
    #@test_broken crosses(s1, falling(25pct)) == [2.5]
    #@test_broken crosses(s1, either(25pct), limit=0) == Float64[]
    #@test_broken crosses(s1, either(25pct), limit=1) == [1.5]
    #@test_broken crosses(s1, either(25pct), limit=2) == [1.5, 2.5]
    #@test_broken crosses(s1, either(25pct), limit=3) == [1.5, 2.5, 3.25]
    #@test_broken crosses(s1, either(25pct), limit=4) == [1.5, 2.5, 3.25]

    @test crosses(s1, yth=rising(0.5)) == [1.5, 3.25]
    @test crosses(s1, yth=falling(0.5)) == [2.5]
    @test crosses(s1, yth=either(0.5)) == [1.5, 2.5, 3.25]
    @test crosses(s1, yth=0.5) == [1.5, 2.5, 3.25]
    #@test crosses(s1, yth=25pct) == [1.5, 2.5, 3.25]
    #@test crosses(s1, yth=either(25pct)) == [1.5, 2.5, 3.25]
    #@test crosses(s1, yth=rising(25pct)) == [1.5, 3.25]
    #@test crosses(s1, yth=either(25pct)) == [1.5, 2.5, 3.25]
    #@test crosses(s1, yth=falling(25pct)) == [2.5]
    #@test crosses(s1, yth=either(25pct), limit=0) == Float64[]
    #@test crosses(s1, yth=either(25pct), limit=1) == [1.5]
    #@test crosses(s1, yth=either(25pct), limit=2) == [1.5, 2.5]
    #@test crosses(s1, yth=either(25pct), limit=3) == [1.5, 2.5, 3.25]
    #@test crosses(s1, yth=either(25pct), limit=4) == [1.5, 2.5, 3.25]

    @test crosses(s1, either(0.5), limit=2) == [1.5, 2.5]
    @test cross(s1, rising(0.5)) == 1.5

    # Regular tests (with units)
    #ys = [0,10,0,20,20]V
    #xs = (eachindex(ys))
    #s1 = PWL(xs, ys)
    #@test crosses(s1, 5V) == 1.5s
    #@test crosses(s1, rising(5V)) == 1.5s
    #@test crosses(s1, 5V, n=1) == 1.5s
    #@test crosses(s1, falling(5V)) == 2.5s
    #@test crosses(s1, 5V, n=2) == 2.5s
    #@test crosses(s1, either(5V)) == 2.5s
    #@test crosses(s1, 5V, n=3) == 3.25s

    # Test crossing multiple thresholds in a single datapoint
    @test crosses(s1, [rising(0.5), rising(0.6)]) == [1.5, 1.6, 3.25, 3.3]

    # Test first and last crossing
    s4 = PWL(0.0:5.0, Float64[0, 1, -1, 1, -1, 0])
    @test first(eachcross(s4, 0.5)) == 0.5
    # @test last(eachcross(s4, 0.5), 1) == [3.25]  # last(s) = s[end] which doesn't work
    @test cross(s4, 0.5; N=1) == 0.5
    @test cross(s4, 0.5; N=2) == 1.25
    @test cross(s4, 0.5; N=3) == 2.75
    @test cross(s4, 0.5; N=4) == 3.25
    @test cross(s4, 0.5; N=-4) == 0.5
    @test cross(s4, 0.5; N=-3) == 1.25
    @test cross(s4, 0.5; N=-2) == 2.75
    @test cross(s4, 0.5; N=-1) == 3.25

    # Test cross over periodic boundary #286
    xs = range(0, 1, length=50)
    ys = @. sin(2pi*xs)
    s = repeat(PWL(xs, ys), 3)
    x1 = cross(s, rising(-0.2))
    s1 = clip(s, x1 .. xmax(s))
    ## Cross on next period:
    @test cross(s1, rising(0.2)) > 1


    # Clip containing only one sample point
    pulse = PWL(Float64[0,0.5,1,2,3,4], Float64[1, 1, 0, 0, 1, 1])
    interval = 1.75 .. 2.25
    s = clip(pulse, interval)
    @test ymax(s) == pulse(last(interval))

    # Clip containing no sample points
    pulse = PWL(Float64[0,0.5,1,2,3,4], Float64[1, 1, 0, 0, 1, 1])
    interval = 2.25 .. 2.75
    s = clip(pulse, interval)
    @test collect(eachx(s)) == [2.25, 2.75]
    @test collect(s) == [(2.25, 0.25), (2.75, 0.75)]
    @test ymax(s) == 0.75
    @test ymin(s) == 0.25

    # multiple crossings between sample points:
    s = PWL(0:7, [0, 0, 0.5, 0.15, 1, 1, 0, 0])
    @test length(crosses(s, [falling(0.5), rising(0.1), falling(0.9)])) == 3
    @test length(crosses(s, [falling(0.9), falling(0.5), falling(0.1)])) == 3
end