using CedarWaves, Plots

xs = [0, 1, 2]
ys = [0, 1, 0]

signal = PWL(xs, ys)
plot(signal)

# get the y-value at a specific x
signal(0)
signal(1)

# Iteration:
for (x, y) in eachxy(signal)
    println("x=$x, y=$y")
end

# Indexing:
signal[1]
signal[2]
signal[3]
signal[2:end]

# Continuous interpolation
integral(signal)
sqr = signal^2
integral(sqr)
integral(sqr) |> rationalize
derivative(sqr)

t1 = cross(sqr, rising(0.25))
inspect(t1)
t1.slope

# Measurements
t2 = cross(sqr, falling(0.5))
inspect(t2)

delay = t2 - t1
inspect(delay)
delay.value

# easily create own measurement functions
function mydelay(sig; yth1, yth2)
    cross(sig, yth1) - cross(sig, yth2)
end

d1 = mydelay(sqr; yth1=rising(0.25), yth2=falling(1.5))
inspect(d1)
inspect(d1.pt1)
inspect(d1.pt2)

d2 = mydelay(sqr; yth1=rising(0.25), yth2=falling(0.5))
inspect(d2)

# Robust measurements with patterns
ys2 = repeat([0, 0.3, 0, 1, 1], 2)
xs2 = 1:length(ys2)
glitchy = PWL(xs2, ys2)
edges = crosspatterns(glitchy, [rising(0.1), rising(0.9)])
inspect(edges)

# Find glitches (that don't reach 0.5)
glitch_crosses = crosspatterns(glitchy, [rising(0.1), falling(0.1)], exclude=[rising(0.5)])
inspect(glitch_crosses)

# Interpolation methods
linear = PWL(glitchy)
akima = PWAkima(glitchy)
quad = PWQuadratic(glitchy)
cubic = PWCubic(glitchy)


f(x) = 2x^2 - 3x
f(1)
f(10)

# Get native machine code for ultra low-level debugging:
@code_native f(3)
@code_native f(3.0)

s2 = derivative(cubic)
s3 = f(s2)
integral(s3)





