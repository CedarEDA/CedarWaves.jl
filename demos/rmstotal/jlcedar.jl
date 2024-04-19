using CedarWaves

points = 10^parse(Int64, ARGS[1])
factor = parse(Int64, ARGS[2])
f1 = 5*factor
f2 = 7*factor

t = range(0, 1, length=points)
y = @. cospi(2*f1*t) * cospi(2*f2*t)

s = PWL(t, y)

println("julia cedar")
@time rms(s)
@time for _ in 1:10
    rms(s)
end
