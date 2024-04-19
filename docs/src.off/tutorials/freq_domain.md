# Frequency Domain

```@repl freq
using CedarWaves, Plots, Test
fcarrier = 1000
fmodulator = 100
fsample = 2*fcarrier
sa = 1 # 10
smod = 0.5
offset = 1
td = 0.001
tstart = 0e-3
tstep = 10e-6
tstop = 52e-3
t = range(tstart, tstop, step=tstep)
NP = length(t)
freqs = @. fmodulator * (0:NP-1)
y = @. (sa * offset * sind(360*fcarrier*(t - td))) + 
		smod*sa*cosd(360*(fcarrier-fmodulator)*(t-td)) -
		smod*sa*cosd(360*(fcarrier+fmodulator)*(t-td))
s1 = PWL(t, y)
plot(s1, title="Modulated Signal", xlabel="time (s)", ylabel = "Volts (V)", label="s1");
savefig("freq_s1.svg") # hide
nothing # hide
```

![](freq_s1.svg)

Now we will [`clip`](@ref) the signal to restrict the x-axis to a full set of periods of the input frequency components:

```@repl freq
tstart = 10e-3
tstop = 40e-3
s2 = clip(s1, tstart .. tstop);
#plot(s1, title="Modulated Signal (clipped)", xlabel="time (s)", ylabel = "Volts (V)", label="s1"); # hide
plot(s2, title="Modulated Signal (clipped)", xlabel="time (s)", ylabel = "Volts (V)", label="s2");
savefig("freq_s2.svg") # hide
nothing # hide
```

![](freq_s2.svg)

```@repl freq
f2 = dft(s2)
plot(f2);
savefig("freq_s1.svg") # hide
nothing # hide

```

```@repl freq
@test f2[0].x == 0
@test f2[27].x ≈ fcarrier-fmodulator
@test f2[30].x ≈ fcarrier
@test f2[33].x ≈ fcarrier+fmodulator
@test phased(f2(fcarrier)) ≈ -90
@test phased(f2(fcarrier-fmodulator)) ≈ 36°
@test phased(f2(fcarrier+fmodulator)) ≈ 144°
@test phased(f2(fcarrier-fmodulator)) + phased(f2(fcarrier+fmodulator)) ≈ 180°
@test abs(f2(fcarrier)) ≈ sa
@test abs(f2(fcarrier-fmodulator)) ≈ smod
@test abs(f2(fcarrier+fmodulator)) ≈ smod
@test abs(f2(fcarrier-fmodulator)) + abs(f2(fcarrier+fmodulator)) ≈ 2smod

for i in eachindex(f2) 
if i in [27, 30, 33]
		continue
end
@test dB20(f2.y[i]) < -290
end

f2c = clip(f2, fcarrier-2*fmodulator .. fcarrier + 2*fmodulator)
f2ca = abs(f2c)
@test f2ca isa PWL # Should probably fix this so it is still a DFT signal
@test f2ca(fcarrier) ≈ sa
@test f2ca(fcarrier-fmodulator) ≈ smod
@test f2ca(fcarrier+fmodulator) ≈ smod
if isdefined(Main, :plot); plot(abs(f2c)); end
```