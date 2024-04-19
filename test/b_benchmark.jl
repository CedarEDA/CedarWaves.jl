using CedarWaves
using BenchmarkTools
using Plots

# Create 1GB of samples of a piece-wise linear interpolated, continuous sampled signal
N = round(Int, 8e8/sizeof(Float64))
xs = range(0, N, length=N+1)
@time ys = sin.(xs);  # use sin for y values
@time s = PWL(xs, ys);  # create a continuous (piecewise linear) sampled signal
@time s = PWL(xs, ys);
function bench1(s::Signal)
    10s + s^3 - sin(s)^2 +10 + s/2
end
@time s2 = bench1(s);
@time s2 = bench1(s);
@time display(inspect(s2)))
@time display(inspect(bench1(s)))

@time bench1(s)
x = 1e6
@benchmark s2($(Ref(x))[])
@benchmark bench1($s)

# Convolution
s1 = xscale(PWL(5:7, [0,1,0]), 1)
s2 = xscale(PWL(5:7, [0,1,0]),10)
s3 = convolution(s1, s2)
@benchmark s3(55)
inspect(s3)

s1 = xscale(PWL(5:7, [0,1,0]),10)
s2 = xscale(PWL(5:7, [0,1,0]),1)
s3 = convolution(s1, s2)
@benchmark s3(55)
display(inspect(s3))

# Fourier transform:
t = 0:1e-7:1
@time y = 0.5 .+ 3sinpi.(2*10t)
@time s = PWL(t, y)

@time abs(FT(s, 0)) ≈ 0.5 # DC
@time abs(FT(s, 10)) ≈ 3 # 10 Hz
@time abs(FT(s, 12))
@time abs(FT(s, 0:1000, atol=1e-14))
@time abs(FT(s, 0:2:2000))

# Fourier transform (non-range x-axis):
t2 = unique(sort!(rand(length(t))))
t2[1] = 0.0
t2[end] = 1.0
@show length(t2)
@time y2 = s.(t2)
@time s2 = PWL(t2, y2)

@time abs(FT(s2, 0)) ≈ 0.5 # DC
@time abs(FT(s2, 10)) ≈ 3 # 10 Hz
@time abs(FT(s2, 0:100))
@time abs(FT(s2, 0:1000))
@time abs(FT(s2, 0:2:2000))

@benchmark abs(FT(s2, 10))

# Std
@benchmark std(s)