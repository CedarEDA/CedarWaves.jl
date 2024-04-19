points = 10^parse(Int64, ARGS[1])
factor = parse(Int64, ARGS[2])
f1 = 5*factor
f2 = 7*factor

function rms_signal(xs, ys)
	area = 0.0
	@inbounds @simd for i in 2:length(xs)
		dx = xs[i] - xs[i-1]
		y1 = ys[i-1]
		y2 = ys[i]
		dy = y2 - y1
		area += dx*(dy^2/3 + y1*y2) # quadratic shape
	end
	sqrt(area/(xs[end]-xs[begin]))
end

t = range(0, 1, length=points)
y = @. cospi(2*f1*t) * cospi(2*f2*t)

println("julia plain")
@time rms_signal(t, y)
@time for _ in 1:10
    rms_signal(t, y)
end