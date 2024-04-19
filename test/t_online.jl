using CedarWaves, Test

function test_online(x, y, f, interp=CedarWaves.LinearInterpolation)
    @sync begin
        s = SampledSignal(x, y; interp)
        sf = OnlineSignalFactory()

        @async @testset "$(f)" begin
            @test f(s) == f(new_online(sf))
        end

        yield()
        for xy in zip(x, y)
            put!(sf.ch, xy)
        end
        close(sf.ch)
    end
end

# this looks like it runs zero tests but failing tests do show up
@testset "online" begin
    x = 0:0.1:10
    y = sinpi.(x)
    test_online(x, y, xvals)
    test_online(x, y, yvals)
    test_online(x, y, yvals, CedarWaves.QuadraticInterpolation)
    test_online(x, y, s->yvals(s*2))
    test_online(x, y, s->map(float, eachcross(s, 0))) # Measure messes it up
    test_online(x, y, ymax)
    test_online(x, y, ymin)
end