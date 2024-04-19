using CedarWaves
#using Unitful: V, s, Hz, ustrip, k, ms, kHz, dBV, °
using Unitful: °
using Test
import FFTW

const Signals = CedarWaves

@testset "DFT types" begin
    d1 = dft(PWL(0:4, [0,1,0,-1,0]))
    @test d1 isa DFT
    @test dftscale(d1) == Signals.DFTRms
    c1 = clip(d1, 0.1)
    @test c1 isa Signals.ClippedExact{DFTKind}
    @test dftscale(c1) == Signals.DFTRms
end
@testset "DFT (even samples)" begin
    # Even samples:
    ys = 1:10
    NP = length(ys)
    @test dftbins(ys) == 0:9
    @test dftbins(ys, UpperMirroredSideband) == 0:9
    @test dftbins(ys, UpperSideband) == 0:5
    d0 = FFTW.fft(ys)

    # Test UpperMirrordSideband (ums) DFT scalings:
    ums_unscaled = dft(ys, sideband=Signals.UpperMirroredSideband, fullperiod=false, scale=Signals.DFTUnscaled)
    @test ums_unscaled.y ≈ d0

    ums_peak = dft(ys, sideband=Signals.UpperMirroredSideband, fullperiod=false, scale=Signals.DFTPeak)
    @test ums_peak.y ≈ d0/NP

    ums_rms = dft(ys, sideband=Signals.UpperMirroredSideband, fullperiod=false, scale=Signals.DFTRms)
    @test ums_rms.y[begin] ≈ ums_peak.y[begin]
    @test ums_rms.y[begin+1:end] ≈ ums_peak.y[begin+1:end]/sqrt(2)

    ums_rms_from_peak = Signals.DFTRms(ums_peak)
    @test ums_rms_from_peak.y ≈ ums_rms.y

    ums_peak_from_rms = Signals.DFTPeak(ums_rms)
    @test ums_peak_from_rms.y ≈ ums_peak.y

    ums_unscaled_from_peak = Signals.DFTUnscaled(ums_peak)
    @test ums_unscaled_from_peak.y ≈ ums_unscaled.y

    ums_unscaled_from_rms = Signals.DFTUnscaled(ums_rms)
    @test ums_unscaled_from_rms.y ≈ ums_unscaled_from_rms.y


    # Test UpperSideband (us) DFT scalings:
    us_unscaled = dft(ys, sideband=Signals.UpperSideband, fullperiod=false, scale=Signals.DFTUnscaled)
    N=length(us_unscaled)
    @test us_unscaled.y[begin] ≈ d0[begin]
    @test us_unscaled.y[begin+1:N] ≈ 2 .* d0[begin+1:N]

    us_peak = dft(ys, sideband=Signals.UpperSideband, fullperiod=false, scale=Signals.DFTPeak)
    NP=length(ys)
    @test us_peak.y[begin] ≈ d0[begin]/NP
    @test us_peak.y[begin+1:N] ≈ 2 .* d0[begin+1:N]/NP

    us_rms = dft(ys, sideband=Signals.UpperSideband, fullperiod=false, scale=Signals.DFTRms)
    @test us_rms.y[begin] ≈ us_peak.y[begin]
    @test us_rms.y[begin+1:end] ≈ us_peak.y[begin+1:end]/sqrt(2)

    us_rms_from_peak = Signals.DFTRms(us_peak)
    @test us_rms_from_peak.y ≈ us_rms.y

    us_peak_from_rms = Signals.DFTPeak(us_rms)
    @test us_peak_from_rms.y ≈ us_peak.y

    us_unscaled_from_peak = Signals.DFTUnscaled(us_peak)
    @test us_unscaled_from_peak.y ≈ us_unscaled.y

    us_unscaled_from_rms = Signals.DFTUnscaled(us_rms)
    @test us_unscaled_from_rms.y ≈ us_unscaled.y
end
@testset "DFT (odd samples)" begin

    # Odd samples:
    ys = 1:9
    NP = length(ys)
    @test dftbins(ys) == 0:8
    @test dftbins(ys, UpperMirroredSideband) == 0:8
    @test dftbins(ys, UpperSideband) == 0:4
    d0 = FFTW.fft(ys)

    # Test UpperMirrordSideband (ums) DFT scalings:
    ums_unscaled = dft(ys, sideband=Signals.UpperMirroredSideband, fullperiod=false, scale=Signals.DFTUnscaled)
    @test ums_unscaled.y ≈ d0

    ums_peak = dft(ys, sideband=Signals.UpperMirroredSideband, fullperiod=false, scale=Signals.DFTPeak)
    @test ums_peak.y ≈ d0/NP

    ums_rms = dft(ys, sideband=Signals.UpperMirroredSideband, fullperiod=false, scale=Signals.DFTRms)
    @test ums_rms.y[begin] ≈ ums_peak.y[begin]
    @test ums_rms.y[begin+1:end] ≈ ums_peak.y[begin+1:end]/sqrt(2)

    ums_rms_from_peak = Signals.DFTRms(ums_peak)
    @test ums_rms_from_peak.y ≈ ums_rms.y

    ums_peak_from_rms = Signals.DFTPeak(ums_rms)
    @test ums_peak_from_rms.y ≈ ums_peak.y

    ums_unscaled_from_peak = Signals.DFTUnscaled(ums_peak)
    @test ums_unscaled_from_peak.y ≈ ums_unscaled.y

    ums_unscaled_from_rms = Signals.DFTUnscaled(ums_rms)
    @test ums_unscaled_from_rms.y ≈ ums_unscaled_from_rms.y


    # Test UpperSideband (us) DFT scalings:
    us_unscaled = dft(ys, sideband=Signals.UpperSideband, fullperiod=false, scale=Signals.DFTUnscaled)
    N=length(us_unscaled.y)
    @test us_unscaled.y[begin] ≈ d0[begin]
    @test us_unscaled.y[begin+1:N] ≈ 2 .* d0[begin+1:N]

    us_peak = dft(ys, sideband=Signals.UpperSideband, fullperiod=false, scale=Signals.DFTPeak)
    NP=length(ys)
    @test us_peak.y[begin] ≈ d0[begin]/NP
    @test us_peak.y[begin+1:N] ≈ 2 .* d0[begin+1:N]/NP

    us_rms = dft(ys, sideband=Signals.UpperSideband, fullperiod=false, scale=Signals.DFTRms)
    @test us_rms.y[begin] ≈ us_peak.y[begin]
    @test us_rms.y[begin+1:end] ≈ us_peak.y[begin+1:end]/sqrt(2)

    us_rms_from_peak = Signals.DFTRms(us_peak)
    @test us_rms_from_peak.y ≈ us_rms.y

    us_peak_from_rms = Signals.DFTPeak(us_rms)
    @test us_peak_from_rms.y ≈ us_peak.y

    us_unscaled_from_peak = Signals.DFTUnscaled(us_peak)
    @test us_unscaled_from_peak.y ≈ us_unscaled.y

    us_unscaled_from_rms = Signals.DFTUnscaled(us_rms)
    @test us_unscaled_from_rms.y ≈ us_unscaled.y
end

@testset "DFT freq modulation test" begin
    # Testing on signals:
    # Without units:
    fcarrier = 1000
    fmodulator = 100
    fsample = 2*fcarrier
    sa = 1 # 10
    smod = 0.5
    offset = 1
    td = 0.001
    tstep = 10e-6
    tstop = 52e-3
    tstart = 0.0
    t = range(tstart, tstop, step=tstep)
    NP = length(t)
    freqs = @. fmodulator * (0:NP-1)
    y = @. (sa * offset * sind(360*fcarrier*(t - td))) +
          smod*sa*cosd(360*(fcarrier-fmodulator)*(t-td)) -
          smod*sa*cosd(360*(fcarrier+fmodulator)*(t-td))
    s1 = PWL(t, y)
    inspect(s1)
    f1 = FFTW.rfft(y[begin:end-1])
    f1dB20 = dB20.(f1)
    inspect(f1dB20)
    tstart = 10e-3
    tstop = 40e-3
    s2 = clip(s1, tstart .. tstop)
    inspect(s1)
    inspect(s2)
    s3 = sample(s2, tstart:0.1e-3:tstop)
    f2 = dft(s3, scale=DFTPeak)
    inspect(dB20(f2))
    inspect(dB20.(f2.y))
    @test f2[1].x == 0
    @test f2[28].x ≈ fcarrier-fmodulator
    @test f2[31].x ≈ fcarrier
    @test f2[34].x ≈ fcarrier+fmodulator
    @test phased(f2(fcarrier)) ≈ -90
    @test phased(f2(fcarrier-fmodulator)) ≈ 36°
    @test phased(f2(fcarrier+fmodulator)) ≈ 144°
    @test phased(f2(fcarrier-fmodulator)) + phased(f2(fcarrier+fmodulator)) ≈ 180°
    @test abs(f2(fcarrier)) ≈ sa
    @test abs(f2(fcarrier-fmodulator)) ≈ smod
    @test abs(f2(fcarrier+fmodulator)) ≈ smod
    @test abs(f2(fcarrier-fmodulator)) + abs(f2(fcarrier+fmodulator)) ≈ 2smod

    for i in eachindex(f2)
        if i in 1 .+ [27, 30, 33]
            continue
        end
        @test dB20(f2.y[i]) < -290
    end
end

@testset "DFT of non-uniformly sampled signal" begin
    x0 = (0:10)/10^9
    y0 = (0:10)/10^9
    s0 = PWL(x0, y0)
    d0 = dft(s0)
    xs = collect(x0)
    ys = collect(y0)
    s1 = PWL(xs, ys)
    @test check_uniformly_sampled(s0)
    @test check_uniformly_sampled(s1)
    @test UniformlySampledStyle(s0) == IsUniformlySampled()
    @test UniformlySampledStyle(s1) == IsUniformlySampled()
    d1 = dft(s1)
    @test d0.x == d1.x
    @test d0.y == d1.y
    # Add some noise to x-axis (except for end points):
    xs2 = xs .+ rand(length(xs))./1e16
    xs2[begin] = xs[begin]
    xs2[end] = xs[end]
    @test check_uniformly_sampled(PWL(xs2, ys), atol=1e-15)
    @test check_uniformly_sampled(PWL(xs2, ys), atol=1e-17) == false
    s2 = PWL(xs2, ys)
    # Noise is below default atol so it should just do a DFT on the y values:
    d2 = dft(s2, atol=1e-15)
    @test d2.x ≈ d0.x
    @test d2.y ≈ d0.y
    # Noise is above default atol so it should just do a DFT:
    # Test with clipping
    c1 = clip(s1, s1.x[begin+1])  # exact
    dc1 = dft(c1)
    c2 = clip(s1, step(x0)/4)  # non-exact
    dc2 = dft(c2)
    @test length(dc2) == length(d1)

    # Test with resampling
    d100 = dft(c2, NP=100)
    # remove DC:
    d99 = clip(d100, d100.x[2])
    d99b = d100[2:end]
    @test signal_type(d99) == signal_type(d99b)
    @test d99.x == d99b.x
    @test d99.y == d99b.y
    @test d99.NP == d99b.NP
end
@testset "non-uniform with NP" begin
    s1 = PWL([0.0, 0.001001, 0.002, 0.003, 0.004], [0,1,0,-1,0])
    d1 = dft(s1)
    d2 = dft(s1, NP=4)  # NP should be after endpoint is removed
    @test length(d1) == length(d2)
end
if false
    f2c = clip(f2, fcarrier-2*fmodulator .. fcarrier + 2*fmodulator)
    f2ca = abs(f2c)
    @test f2ca isa PWL # Should probably fix this so it is still a DFT signal
    @test f2ca(fcarrier) ≈ sa
    @test f2ca(fcarrier-fmodulator) ≈ smod
    @test f2ca(fcarrier+fmodulator) ≈ smod
    inspect(abs(f2c))


    # Test

    ### Testing core fourier transform kernels:
    # without units:
    t = range(0, 1, length=17)[begin:end-1]
    length(t)
    Fₛ = 1/step(t)
    freq2 = 2
    freq4 = 2*freq2
    y = @. 1 + 2sind(360*freq2*t) + 3cosd(360*freq4*t)
    s = PWL(t, y)
    s_us_peak = dft(s)
    s.y
    s.x
    dft(s.y)

    # Inverse DFT:
    sideband=UpperMirroredUnscaledSideband
    @test real.(FFTW.ifft(FFTW.fft(y))) ≈ y
    @test real.(Signals.idft(FFTW.fft(y); sideband)) ≈ y
    @test real.(Signals.idft(Signals.fft(y; sideband); sideband)) ≈ y
    @test FFTW.ifft(FFTW.fft(y)) ≈ Signals.idft(FFTW.fft(y); sideband) atol=1e-13
    @test FFTW.ifft(FFTW.fft(y)) ≈ Signals.idft(Signals.dft(y; sideband); sideband) atol=1e-13

    @test FFTW.ifft(FFTW.fft(y)) ≈ Signals.ifft(FFTW.fft(y); sideband) atol=1e-15
    @test FFTW.ifft(FFTW.fft(y)) ≈ Signals.ifft(Signals.fft(y; sideband); sideband) atol=1e-11


    sideband=UpperMirroredSideband
    @test real.(Signals.idft(Signals.dft(y; sideband); sideband)) ≈ y
    @test real.(Signals.ifft(Signals.fft(y; sideband); sideband)) ≈ y

    sideband=UpperSideband
    @test Signals.idftscale!(Signals.dft(y; sideband), sideband) ≈ FFTW.fft(y)
    Signals.idftscale!(Signals.dft(y; sideband), sideband)
    @test real.(Signals.idft(Signals.fft(y; sideband); sideband)) ≈ y

    # with units:
    @test FFTW.fft(y) ≈ ustrip.(Signals.dft(y .* V).parent)
    @test FFTW.fft(y) ≈ ustrip.(Signals.fft(y .* V).parent)

    # non power of 2
    t = range(0, 1, length=17)
    Fₛ = 1/step(t)
    freq2 = 2
    freq4 = 2*freq2
    y = @. 1 + 2sind(360*freq2*t) + 3cosd(360*freq4*t)
    @test FFTW.fft(y) ≈ Signals.dft(y).parent
    @test_throws DomainError Signals.fft(y)

    # Long vector (power of 2) without units
    t = range(0, 1, length=2^12+1)[begin:end-1]
    length(t)
    Fₛ = 1/step(t)
    freq2 = 2
    freq4 = 2*freq2
    y = @. 1 + 2sind(360*freq2*t) + 3cosd(360*freq4*t)
    @test FFTW.fft(y) ≈ Signals.dft(y).parent
    @test FFTW.fft(y) ≈ Signals.fft(y).parent

    #do_benchmark = false
    ##do_benchmark = true
    #if do_benchmark
    #      using BenchmarkTools
    #      @benchmark FFTW.fft($y)
    #      @benchmark Signals.fft($y)
    #      @benchmark Signals.dft($y)
    #end





    # Inverse DFT:
    @test FFTW.ifft(FFTW.fft(y)) ≈ Signals.idft(FFTW.fft(y)) atol=1e-13
    @test FFTW.ifft(FFTW.fft(y)) ≈ Signals.idft(Signals.dft(y)) atol=1e-13

    @test FFTW.ifft(FFTW.fft(y)) ≈ Signals.ifft(FFTW.fft(y)) atol=1e-15
    @test FFTW.ifft(FFTW.fft(y)) ≈ Signals.ifft(Signals.fft(y)) atol=1e-15

    # Test round trip:
    vin_round_trip = Signals.ifft(freq_vsin)

    # With units:
    t = range(0, 1, length=17)[begin:end-1]s
    length(t)
    Fₛ = 1/step(t)
    freq2 = 2Hz
    freq4 = 2*freq2
    y = (@. 1 + 2sind(360*freq2*t) + 3cosd(360*freq4*t))V

    # DFTs:
    @test FFTW.fft(ustrip.(y)) ≈ Signals.fft(ustrip.(y)).parent
    @test FFTW.fft(ustrip.(y)) ≈ ustrip.(Signals.fft(y).parent)

    # Inverse DFT:
    @test FFTW.ifft(FFTW.fft(ustrip.(y))) ≈ ustrip.(Signals.ifft(FFTW.fft(ustrip.(y)))) atol=1e-13
    @test FFTW.ifft(FFTW.fft(ustrip.(y))) ≈ ustrip.(Signals.idft(Signals.dft(y))) atol=1e-13

    @test FFTW.ifft(FFTW.fft(ustrip.(y))) ≈ ustrip.(Signals.ifft(FFTW.fft(ustrip.(y)))) atol=1e-13
    @test FFTW.ifft(FFTW.fft(ustrip.(y))) ≈ ustrip.(Signals.ifft(Signals.fft(y))) atol=1e-13


    vsin = PWL(t, y)
    Signals.dft(vsin, fullperiod=false).y
    FFTW.rfft(ustrip.(vsin.y))


    t = range(0, 1, length=17)s
    freq2 = 2Hz
    freq4 = 2*freq2
    y = @. 1V + 2sind(360*freq2*t)V + 3cosd(360*freq4*t)V
    yc = @. 1V + 2sind(360*freq2*t)V + im * 3cosd(360*freq4*t)V
    vsin = PWL(t, y)
    vsinc = PWL(t, yc)

    @test UniformlySampledStyle(vsin) == IsUniformlySampled()

    @test UniformlySampledStyle(vsinc) == IsUniformlySampled()

    f = dft(vsin)
    #using Plots
    inspect(f)
    f2 = dft(vsin, fmin=1.5Hz, fmax=3.5Hz)
    inspect(f2)
    f2.index


    @test ustrip.(dft(vsin.y).parent) ≈ FFTW.fft(ustrip.(vsin.y))

    sa=1V
    offset=1V
    fm = 100Hz
    fc = 1kHz
    td = 1ms
    time = (0:0.01:52)ms
    v1 = @. sa * sin(2pi*fc*(time-td)) + 0.5*sa*cos(2pi*(fc - fm)*(time-td)) - 0.5*sa*cos(2pi*(fc + fm)*(time-td))
    v1c = @. sa * sin(2pi*fc*(time-td))
    v1mn = @. 0.5*sa*cos(2pi*(fc - fm)*(time-td))
    v1mp = @. -0.5*sa*cos(2pi*(fc + fm)*(time-td))
    vam = PWL(time, v1)
    inspect(vam)
    v1 = @. sa * (ustrip.(offset) + sin(2pi*fm*(time-td))) * sin(2pi*(fc)*(time-td))
    vam = PWL(time, v1)
    inspect(vam)
    cvam = clip(vam, 10.0ms .. 40.0ms)
    inspect(cvam)
    fmin = fc - 2fm
    fmax = fc + 2fm
    f2 = PWL(dft(cvam; fmin, fmax))
    @test signal_type(f2) == PWL
    Any[f2.index f2.x abs(f2).y dBV(f2).y phased(f2).y]
    inspect(f2)
    @test abs(f2(fc-fm)) ≈ sa/2
    @test abs(f2(fc)) ≈ sa
    @test abs(f2(fc+fm)) ≈ sa/2
    @test dBV(abs(f2.y[begin])) < -300dBV
    @test dBV(abs(f2.y[end])) < -300dBV
    @test f2.x[begin] ≈ fmin
    #@test f2.x[end] ≈ fmax

    @test dBV(f2)(fc) ≈ 0dBV
    @test dBV(f2)(fc-fm) ≈ dBV(sa/2)
    @test dBV(f2)(fc+fm) ≈ dBV(sa/2)

    @test phased(f2)(fc) ≈ -90°
    @test phased(f2)(fc-fm) ≈ 36°
    @test phased(f2)(fc+fm) ≈ 144°

    fmin=0.0
    fmax=10k
    cvamu = ustrip(cvam)
    #f3 = dft(cvamu)
    #cvam3 = clip(cvam, 10ms .. 11ms)
    cvam3 = clip(cvam, 10.0ms .. 11.0ms)

    ustrip.(cvam3.x)
end