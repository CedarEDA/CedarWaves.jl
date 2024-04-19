using CedarWaves, Test

@testset "transitions" begin
    s = PWL(0:11, [0, 0, 50, 15, 75, 100, 100, 75, 15, 50, 0, 0])
    # One threshold (error):
    th = [rising(90)]
    cr = crosses(s, th)
    inspect(cr)
    tr = TransitionMeasure(cr)
    inspect(tr)
    @test_throws AssertionError RisetimeMeasure(tr)

    th = [falling(90)]
    s = PWL(0:11, [0, 0, 50, 15, 75, 100, 100, 75, 15, 50, 0, 0])
    cr = crosses(s, th)
    inspect(cr)
    tr = TransitionMeasure(cr)
    inspect(tr)
    @test_throws AssertionError FalltimeMeasure(tr)

    # Two thresholds:
    th2 = [rising(90), rising(10)]
    s = PWL(0:11, [0, 0, 50, 15, 75, 100, 100, 75, 15, 50, 0, 0])
    cr = crosses(s, th2)
    inspect(cr)
    tr = TransitionMeasure(cr)
    inspect(tr)
    rt = RisetimeMeasure(tr)
    inspect(rt)
    @test rt ≈ 3.4
    @test rt.low_threshold == rising(10)
    @test rt.high_threshold == rising(90)

    th2 = [falling(90), falling(10)]
    s = PWL(0:11, [0, 0, 50, 15, 75, 100, 100, 75, 15, 50, 0, 0])
    cr = crosses(s, th2)
    inspect(cr)
    tr = TransitionMeasure(cr)
    inspect(tr)
    ft = FalltimeMeasure(tr)
    inspect(ft)
    @test ft ≈ 3.4
    @test ft.low_threshold == falling(10)
    @test ft.high_threshold == falling(90)

    th2 = [falling(10), falling(90)]
    s = PWL(0:11, [0, 0, 50, 15, 75, 100, 100, 75, 15, 50, 0, 0])
    cr = crosses(s, th2)
    inspect(cr)
    tr = TransitionMeasure(cr)
    inspect(tr)
    ft = FalltimeMeasure(tr)
    inspect(ft)
    @test ft ≈ 3.4
    @test ft.low_threshold == falling(10)
    @test ft.high_threshold == falling(90)

    # Three thresholds:
    th3 = [rising(50), rising(20), rising(80)]
    s = PWL(0:11, [0, 0, 50, 15, 75, 100, 100, 75, 15, 50, 0, 0])
    cr = crosses(clip(s, 0..8), th3)
    inspect(cr)
    tr = TransitionMeasure(cr)
    inspect(tr)
    rt = RisetimeMeasure(tr)
    inspect(rt)
    @test rt ≈ 2.8

    # Four thresholds:
    th4 = [rising(10), either(20), either(80), rising(90)]
    s = PWL(0:11, [0, 0, 50, 15, 75, 100, 100, 75, 15, 50, 0, 0])
    cr = crosses(clip(s, 0..6), th4)
    inspect(cr)
    tr = TransitionMeasure(cr)
    inspect(tr)
    rt = RisetimeMeasure(tr)
    inspect(rt)
    @test rt ≈ 2.8
    @test minimum(rt.values) ≈ 67/60

    th4 = [falling(10), either(20), either(80), falling(90)]
    s = PWL(0:11, [0, 0, 50, 15, 75, 100, 100, 75, 15, 50, 0, 0])
    cr = crosses(clip(s, 5..xmax(s)), th4)
    inspect(cr)
    tr = TransitionMeasure(cr)
    inspect(tr)
    t = FalltimeMeasure(tr)
    inspect(t)
    @test t ≈ 2.8
    @test minimum(t.values) ≈ 67//60

    s = PWL(0:47, repeat([0, 0, 80, 20, 80, 20, 80, 100, 100, 80, 20, 80, 20, 80, 0, 0], outer=3))
    rts = risetimes(s, risetime_low_pct=0.3, select=minimum)
    @test rts[1].value ≈ rts[2].value ≈ rts[3].value
    @test rts[1].pt2 - rts[1].pt1 == rts[1].value
    @test rts[2].pt2 - rts[2].pt1 == rts[2].value
    @test rts[3].pt2 - rts[3].pt1 == rts[3].value

    rts = risetimes(s, risetime_low_pct=0.3, select=maximum)
    @test rts[1].value ≈ rts[2].value ≈ rts[3].value
    @test rts[1].pt2 - rts[1].pt1 == rts[1].value
    @test rts[2].pt2 - rts[2].pt1 == rts[2].value
    @test rts[3].pt2 - rts[3].pt1 == rts[3].value

    fts = falltimes(s, falltime_low_pct=0.3, select=minimum)
    @test fts[1].value ≈ fts[2].value ≈ fts[3].value
    @test fts[1].pt2 - fts[1].pt1 == fts[1].value
    @test fts[2].pt2 - fts[2].pt1 == fts[2].value
    @test fts[3].pt2 - fts[3].pt1 == fts[3].value

    fts = falltimes(s, falltime_low_pct=0.3, select=maximum)
    @test fts[1].value ≈ fts[2].value ≈ fts[3].value
    @test fts[1].pt2 - fts[1].pt1 == fts[1].value
    @test fts[2].pt2 - fts[2].pt1 == fts[2].value
    @test fts[3].pt2 - fts[3].pt1 == fts[3].value

    @test_throws ArgumentError falltimes(s, falltime_low_pct=30, select=minimum)
    @test_throws ArgumentError risetimes(s, risetime_low_pct=30, select=minimum)

    s = PWL(0:47, repeat([0, 15, 0, 80, 20, 80, 20, 80, 100, 100, 80, 20, 80, 20, 80, 0], outer=3))
    cr = crosses(s, [either(10), either(50), either(90)])
    risepat = [ThresholdGroup(rising(10)), ThresholdGroup(either(50), 0:10000), ThresholdGroup(rising(90))]
    fallpat = [ThresholdGroup(falling(90)), ThresholdGroup(either(50), 0:10000), ThresholdGroup(falling(10))]
    rfpat = ThresholdGroup([risepat, fallpat])
    matches = CedarWaves.findall(cr, rfpat) |> collect
    @test length(matches) == 6
    @test matches[1][1].yth == rising(10)
    @test matches[1][1].x == 2.125
    @test matches[1][end].yth == rising(90)
    @test matches[1][end].x == 7.5
    @test matches[2][1].yth == falling(90)
    @test matches[2][1].x == 9.5
    @test matches[2][end].yth == falling(10)
    @test matches[2][end].x == 14.875
    @test matches[3][1].yth == rising(10)
    @test matches[3][1].x == 18.125
    @test matches[3][end].yth == rising(90)
    @test matches[3][end].x == 23.5

    # Multiple transitions between samples should respect transition type
    s = PWL(0:1, [0, 100])
    mixedyth = [falling(10), rising(50)]
    cr = crosses(s, mixedyth)
    @test length(cr) == 1

    s = PWL(0:1, [0, 100])
    mixedyth = [rising(10), falling(50)]
    cr = crosses(s, mixedyth)
    @test length(cr) == 1

    # Multiple transitions between samples should be reported in order of occurrence
    s = PWL(0:1, [0, 100])
    riseyth = [rising(10), rising(50)]
    cr = crosses(s, riseyth)
    @test length(cr) == 2
    @test cr[1].x < cr[2].x

    @test cr[1].x < cr[2].x
    s = PWL(0:1, [100, 0])
    fallyth = [falling(10), falling(50)]
    cr = crosses(s, fallyth)
    @test length(cr) == 2
    @test cr[1].x < cr[2].x

    # (Partially) redundant thresholds should merge appropriately
    s = PWL(0:2, [0, 100, 0])
    mixedyth = [either(50), rising(50)]
    cr = crosses(s, mixedyth)
    println(cr)
    @test length(cr) == 2

    s = PWL(0:2, [0, 100, 0])
    riseyth = [rising(50), either(50)]
    cr = crosses(s, mixedyth)
    println(cr)
    @test length(cr) == 2

    # Repeating elements in a crosspattern should behave as expected
    s = PWL(0:5, [0, 100, 0, 100, 0, 100])
    repeated_rising = CedarWaves.crosspatterns(s, [rising(50), rising(50), rising(50)])
    @test length(repeated_rising) == 1

    s = PWL(0:16, [0, 15, 0, 100, 20, 80, 20, 80, 100, 100, 80, 0, 80, 20, 80, 0, 0])
    riseyth = rising.([10, 50, 90])
    cr = crosses(s, riseyth)
    inspect(cr)
    risepat = ThresholdGroup.(riseyth)
    matches = CedarWaves.findall(cr, risepat) |> collect
    inspect(matches)
    @test length(matches) == 1
    @test length(matches[1]) == 3

    fallyth = falling.([90, 50, 10])
    cr = crosses(s, fallyth)
    inspect(cr)
    fallpat = ThresholdGroup.(fallyth)
    matches = CedarWaves.findall(cr, fallpat) |> collect
    @test length(matches) == 1
    @test length(matches[1]) == 3

    rfyth = either.([10, 50, 90])
    cr = crosses(s, rfyth)
    inspect(cr)
    rfpat = ThresholdGroup([risepat, fallpat])
    matches = CedarWaves.findall(cr, rfpat) |> collect
    inspect(matches)
    @test length(matches) == 2

    #This finds a rising transition with fallback at 50%:
    s = PWL(0:5, [0, 0, 60, 40, 100, 100])
    fallback_rising_yths = [rising(10), either(50), rising(90)]
    crs = crosses(s, fallback_rising_yths)
    inspect(crs)
    # the `ThresholdGroup([rising(50), falling(50)], 1:10000)` I want the thresholds to be in order but not sure how to expresse this:
    CedarWaves.findall(crs, ([ThresholdGroup(rising(10)), ThresholdGroup([rising(50), falling(50)], 1:10000), ThresholdGroup(rising(50)), ThresholdGroup(rising(90))])) |> collect
    # I'd like to express it like:
    #in_sequence(rising(10), one_or_more(in_sequence(rising(50), falling(50))), rising(50), rising(90))

    s = PWL(0:15, repeat([0, 100, 100, 0, 0, 100, 100, 0], outer=2))
    riseperiods = periods(s)
    @test length(riseperiods) == 3
    riseperiods = periods(s, dir=rising)
    @test length(riseperiods) == 3

    fallperiods = periods(s, dir=falling)
    @test length(fallperiods) == 3

    eitherperiods = periods(s, dir=either)
    @test length(eitherperiods) == 6

    risefreqs = frequencies(s)
    @test length(risefreqs) == 3
    risefreqs = frequencies(s, dir=rising)
    @test length(risefreqs) == 3

    fallfreqs = frequencies(s, dir=falling)
    @test length(fallfreqs) == 3
    eitherfreqs = frequencies(s, dir=either)
    @test length(eitherfreqs) == 6
end
