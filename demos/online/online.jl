using CedarWaves
using Plots

# this demo shows how to do online measurements of an ongoing simulation
# some care is required with setting up measurements

# creat an online signal factory with a ringbuffer of 50 samples
# the samples of each online signal have to be consumed fully exactly once
sf = OnlineSignalFactory(50)

@sync begin
    # a fully iterative measurement works normally
    @async let lc=0.0
        for cr in eachcross(new_online(sf), 0)
            dt = cr-lc
            lc = cr
            println("frequecy: ", 1/dt)
        end
    end

    @async for (x, y) in eachxy(new_online(sf))
        if y > 0.8 || y < -0.8
            println("signal exceeded limits at ", x)
        end
    end

    # a measurement that consumes samples until it has enough data will work
    # but each new measurement starts where the previous ended
    s1 = new_online(sf)
    @async while true
        try
            rt = risetime(s1, yths=[-0.5, 0.5])
            println("risetime: ", rt)
        catch e
            break
        end
    end

    # a measurement that consumes all samples will block until the end
    @async println("maximum: ", xymax(new_online(sf)))

    # generate some dummy data
    for t in 0:0.1:10
        put!(sf.ch, (t, sinpi(t^1.5)))
        # sleep(0.1)
    end
    # end the simulation
    close(sf.ch)
end

# after the simulation is done, use postprocess to analyse the buffer
pp = postprocess(sf)

# note that the first samples are no longer available
# this is the maximum of the remaining samples
println("maximum: ", xymax(pp))

# some functions are not sample based,
# these should best be used in postprocessing
# or on a clipped segment of the online signal
println("rms: ", rms(pp))

plot(pp)
savefig("online.png")