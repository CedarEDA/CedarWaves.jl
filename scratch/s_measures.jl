using CedarWaves


# Generate input data (should call CedarSim)
freq = 1000
cycles = 400
tstop = (cycles+2)/freq
t = 0:0.01/freq:tstop

noise1 = rand(length(t)) ./ 100
noise2 = rand(length(t)) ./ 100

# Base waveforms from simulator:
s1pos = PWL(t, @.(+sinpi(2*freq*t) + noise1))
s1neg = PWL(t, @.(-sinpi(2*freq*t) - noise2))

# Simple measure:
s1diff = s1pos - s1neg # signal math
rt = risetime(s1diff, yths=[-1.5, 1.5])  # src/measure.jl:1408
inspect(rt)
rt.pt1.x
rt.pt1.y
rt.pt2.x
rt.pt2.y

# More complex measure (max error of last N cycles):
crosses = last(eachcross(s1diff, rising(0.0)), cycles+1)
inspect(crosses[1])
inspect(crosses[2])
inspect(crosses[3])
inspect(crosses[4])
inspect(crosses[5])
inspect(crosses[end])


function cycle_to_cycle_jitter(signal; yth, cycles)
    periods = last(eachcross(signal, yth), cycles+1)
    diff(periods)
end

jtrs = cycle_to_cycle_jitter(s1diff; yth=rising(0.0), cycles)

function max_cycle_to_cycle_jitter(signal; yth, cycles)
    jitters = cycle_to_cycle_jitter(signal; yth, cycles)
    val, idx = findmax(abs, jitters)
    jitters[idx]
end

jitters = PWL(1:length(jtrs), jtrs)
max_cycle_to_cycle_jitter(s1diff; yth=rising(0.0), cycles)
