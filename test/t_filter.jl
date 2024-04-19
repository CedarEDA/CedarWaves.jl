using Test, CedarWaves

@testset "fir" begin
lp = firfilter(Lowpass(250.0), 0.05)
hp = firfilter(Highpass(750.0), 0.05)
bp = firfilter(Bandpass(250.0, 750.0), 0.05)
bs = firfilter(Bandstop(250.0, 750.0), 0.05)

lptf = abs(sample(FT(sample(lp, 0.001)), 0.0:1000));
hptf = abs(sample(FT(sample(hp, 0.001)), 0.0:1000));
bptf = abs(sample(FT(sample(bp, 0.001)), 0.0:1000));
bstf = abs(sample(FT(sample(bs, 0.001)), 0.0:1000));

@test crosses(lptf, 0.5) ≈ [250] atol=1
@test lptf(0) ≈ 1 atol=1e-5
@test lptf(1000) ≈ 0 atol=1e-5
@test crosses(hptf, 0.5) ≈ [750] atol=1
@test hptf(0) ≈ 0 atol=1e-5
@test hptf(1000) ≈ 1 atol=0.1 # kinda sketchy
@test crosses(bptf, 0.5) ≈ [250, 750] atol=1
@test bptf(0) ≈ 0 atol=1e-5
@test bptf(500) ≈ 1 atol=1e-5
@test bptf(1000) ≈ 0 atol=1e-5
@test crosses(bstf, 0.5) ≈ [250, 750] atol=1
@test bstf(0) ≈ 1 atol=1e-5
@test bstf(500) ≈ 0 atol=0.01
@test bstf(1000) ≈ 1 atol=0.1 # also sketchy

t = PWL(0:0.0001:1, 0:0.0001:1)
s = sinpi(2*100*t)+sinpi(2*1000*t)
lps = sample(filt(lp, s), xvals(s));
err = clip(lps-sinpi(2*100*t), 0.1..0.9);
@test rms(err) < 1e-4
end

@testset "iir" begin
t = PWL(0:1e-5:0.1, 0:1e-5:0.1)
low = sinpi(2*50*t)
high = sinpi(2*5000*t)
band = sinpi(2*500*t)
# s = low + high
s = PWL(Float64[0, 1], Float64[1, 1])


lp = iirfilter(Lowpass(250.0), Butterworth(3))
hp = iirfilter(Highpass(750.0), Butterworth(3))
bp = iirfilter(Bandpass(250.0, 750.0), Butterworth(3))
bs = iirfilter(Bandstop(50.0, 5000.0), Butterworth(5))

lps = filt(lp, s)
hps = filt(hp, s)
bps = filt(bp, s)
bss = filt(bs, s)

@test lps(xmax(lps)) ≈ 1
@test hps(xmax(lps)) ≈ 0 atol=1e-9
@test bps(xmax(lps)) ≈ 0 atol=1e-9
@test bss(xmax(lps)) ≈ 1

lph = clip(filt(lp, high), 0.01..0.1)
lpl = clip(filt(lp, low) , 0.01..0.1)
hpl = clip(filt(hp, low) , 0.01..0.1)
hph = clip(filt(hp, high), 0.01..0.1)
bsb = clip(filt(bs, band), 0.05..0.1)
bpb = clip(filt(bp, band), 0.01..0.1)
@test rms(lph) ≈ 0 atol=1e-3
@test rms(lpl) ≈ sqrt(2)/2 atol=1e-3
@test rms(hpl) ≈ 0 atol=1e-3
@test rms(hph) ≈ sqrt(2)/2 atol=1e-3
@test rms(bsb) ≈ 0 atol=1e-3
@test rms(bpb) ≈ sqrt(2)/2 atol=1e-3
end
