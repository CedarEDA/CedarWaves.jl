
using Test, CedarWaves

@testset "transitions" begin
    s = sample(PWAkima(collect(0:21.0), [0, 0, 0.5, 0, 1, 0, 0.6, 0.2, 0.5, 0.0, 0.0, 0.0, 0.5, 0.2, 1, 0.08, 0.5, 0, 1, 0.5, 1, 0]), 0.00005)
    supply_levels=(0, 1)
    trs = transitions(s; supply_levels, dir=rising)
    @test length(trs) == 3
    trs = transitions(s; supply_levels, dir=falling)
    @test length(trs) == 3

    rts = risetimes(s; supply_levels)
    @test length.(getproperty.(rts, :values)) == [1, 2, 1]
    @test maximum(rts[2].values) == rts[2].value
    @test rts[2].value == rts[2].pt2 - rts[2].pt1

    fts = falltimes(s; supply_levels)
    @test length.(getproperty.(fts, :values)) == [1, 1, 1]
    @test maximum(fts[2].values) == fts[2].value
    @test fts[2].value == fts[2].pt2 - fts[2].pt1
end

@testset "delay" begin
                       #  1   2   3   4   5   6   7   8   9   10  11  12
    none_in  = PWL(1:24, [0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.,
                       #  13  14  15  16  17  18  19  20  21  22  23  24
                          0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.])

                       #  1   2   3   4   5   6   7   8   9   10  11  12
    one_in   = PWL(1:24, [0., 0., 0., 0., 0., 0., 0., 0., 0., 1., 1., 0.,
                       #  13  14  15  16  17  18  19  20  21  22  23  24
                          0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.])

                       #  1   2   3   4   5   6   7   8   9   10  11  12
    many_in  = PWL(1:24, [0., 1., 1., 0., 0., 1., 1., 0., 0., 1., 1., 0.,
                       #  13  14  15  16  17  18  19  20  21  22  23  24
                          0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.])

                       #  1   2   3   4   5   6   7   8   9   10  11  12
    none_out = PWL(1:24, [0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.,
                       #  13  14  15  16  17  18  19  20  21  22  23  24
                          0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.])

                       #  1   2   3   4   5   6   7   8   9   10  11  12
    one_out  = PWL(1:24, [0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.,
                       #  13  14  15  16  17  18  19  20  21  22  23  24
                          0., 1., 1., 0., 0., 0., 0., 0., 0., 0., 0., 0.])

                       #  1   2   3   4   5   6   7   8   9   10  11  12
    many_out = PWL(1:24, [0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0., 0.,
                       #  13  14  15  16  17  18  19  20  21  22  23  24
                          0., 1., 1., 0., 0., 1., 1., 0., 0., 1., 1., 0.])

    # Each transition in the output signal should measure delay against the most recent input edge.
    for in_signal in (none_in, one_in, many_in)
        for out_signal in (none_out, one_out, many_out)
            for dir1 in (rising, falling, either)
                for dir2 in (rising, falling, either)
                    base_delay = 2.0
                    (dir1 === rising) && (base_delay += 2.0)
                    (dir2 === falling) && (base_delay += 2.0)

                    values = delays(in_signal, out_signal; supply_levels=[0., 1.], dir1, dir2)
                    observed = Float64[v.pt2.x - v.pt1.x for v in values]
                    if (out_signal === none_out) || (in_signal === none_in)
                        # An input/output signal with no transitions should measure no delays.
                        expected = Float64[]
                    elseif (out_signal === one_out) && (dir2 !== either)
                        # One output + one transition => one delay
                        expected = base_delay .+ [0.]
                    elseif (out_signal === one_out) && (dir2 === either)
                        # One output + two transitions => two delays
                        expected = base_delay .+ [0., 2.]
                    elseif (out_signal === many_out) && (dir2 !== either)
                        # Three outputs + one transition => three delays
                        expected = base_delay .+ [0., 4., 8.]
                    elseif (out_signal === many_out) && (dir2 === either)
                        # Three outputs + two transitions => six delays
                        expected = base_delay .+ [0., 2., 4., 6., 8., 10.]
                    else
                        @assert false # unreachable
                    end

                    @test length(observed) == length(expected) && observed ≈ expected
                end
            end
        end
    end

    # An output that transitions only before any input transitions should be ignored.
    for in_signal in (none_out, one_out, many_out)
        for out_signal in (none_in, one_in, many_in)
            for dir1 in (rising, falling, either)
                for dir2 in (rising, falling, either)
                    base_delay = 2.0
                    (dir1 === rising) && (base_delay += 2.0)
                    (dir2 === falling) && (base_delay += 2.0)

                    values = delays(in_signal, out_signal; supply_levels=[0., 1.], dir1, dir2)
                    @test length(values) == 0
                end
            end
        end
    end
end
