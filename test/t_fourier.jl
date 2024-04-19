using CedarWaves, Test
const ACS = CedarWaves

@testset "interval_to_grid_range" begin
    @test ACS.interval_to_grid_range(0.0 .. 10.0, 1) == 0:10
    @test ACS.interval_to_grid_range(0.0 .. 1.0, 0.1) == range(0, 1, length=11)
    @test ACS.interval_to_grid_range(0.05 .. 1.0, 0.1) == range(0.1, 1, length=10)
    @test ACS.interval_to_grid_range(0.05 .. 0.95, 0.1) == range(0.1, 0.9, length=9)
end
@testset "fourier transform" begin
    for m in [1, 1e-12]  # test accuracy for small currents
        t = PWL(0:0.1:10, 0:0.1:10)
        s = ymap_signal(t->m * (0.5 + 2cospi(2*2t) + 3sinpi(2*3t) + 10sinpi(2*10t)), t)
        #plot(s)
        ft = sample(FT(s; atol=1e-12*m), -10:0.1:10)/xspan(s);
        #plot(ft)
        @test abs(ft(0)) ≈ 0.5*m atol=1e-9 # DC
        @test abs(ft(1)) + abs(ft(-1)) < 1e-12*m
        @test abs(ft(2)) + abs(ft(-2)) ≈ 2*m
        @test abs(ft(3)) + abs(ft(-3)) ≈ 3*m
        @test abs(ft(4)) + abs(ft(-4)) < 1e-12*m
        @test abs(ft(5)) + abs(ft(-5)) < 1e-12*m
        @test abs(ft(6)) + abs(ft(-6)) < 1e-12*m
        @test abs(ft(7)) + abs(ft(-7)) < 1e-12*m
        @test abs(ft(8)) + abs(ft(-8)) < 1e-12*m
        @test abs(ft(9)) + abs(ft(-9)) < 1e-12*m
        @test abs(ft(10))+ abs(ft(-10)) ≈ 10*m # 10 Hz
    end

    #atols = vcat(0, 10.0 .^ (-17:-3))
    #ts =[@elapsed(FT(s, freq, atol=atol)) for freq in 0:5, atol in atols]
    #plot(ts, yaxis=:log, label=atols')
    #mags =[abs(FT(s, freq, atol=atol)) for freq in 0:5, atol in 10.0 .^ (-9:-3)]

    #####
    # Inverse Fourier Transform
    #####
    s = PWL(-1:1, [0, 1, 0])
    #plot(s)
    # TODO: windowing?
    ft = PWL(-20:20, FT(s))
    @test ytype(ft) == Complex{Float64}
    @test iscontinuous(ft)
    ift = PWL(-1:1, iFT(ft, mode=real)) # the entpoints have a large error
    err = ift-s
    @test rms(err) < 1e-9
    @test iscontinuous(ift)
end

@testset "fourier series" begin
    for m in [1, 1e-12]  # test accuracy for small currents
        T=10
        t = PWL(0:0.1:T, 0:0.1:T)
        s = m * ymap_signal(t->0.5 + 2cospi(2*2t) + 3sinpi(2*3t) + 10sinpi(2*10t), t)
        #plot(s)
        fs = clip(FS(s; atol=1e-12*m), -10 .. 10);
        # TODO: bug with plotting
        #plot(fs)
        @test abs(fs(0)) ≈ 0.5*m atol=1e-9 # DC
        @test abs(fs(1)) + abs(fs(-1)) < 1e-9 * m
        @test abs(fs(2)) + abs(fs(-2)) ≈ 2 * m
        @test abs(fs(3)) + abs(fs(-3)) ≈ 3 * m
        @test abs(fs(4)) + abs(fs(-4)) < 1e-9 * m
        @test abs(fs(5)) + abs(fs(-5)) < 1e-9 * m
        @test abs(fs(6)) + abs(fs(-6)) < 1e-9 * m
        @test abs(fs(7)) + abs(fs(-7)) < 1e-9 * m
        @test abs(fs(8)) + abs(fs(-8)) < 1e-9 * m
        @test abs(fs(9)) + abs(fs(-9)) < 1e-9 * m
        @test abs(fs(10))+ abs(fs(-10)) ≈ 10 * m # 10 Hz
    end

    T=10
    t = PWL(0:0.1:T, 0:0.1:T)
    s = ymap_signal(t->0.5 + 2cospi(2*2t) + 3sinpi(2*3t) + 10sinpi(2*10t), t)
    fs = clip(FS(s), -10 .. 10);

    @test ytype(fs) == Complex{Float64}
    @test !iscontinuous(fs)

    #atols = vcat(0, 10.0 .^ (-320:10:-3))
    #ts =[@elapsed(FS(s, atol=atol)) for freq in 0:10, atol in atols]
    #plot(ts, yaxis=:log, label=atols')
    #mags =[abs(FS(s, freq, atol=atol)) for freq in 0:5, atol in 10.0 .^ (-9:-3)]

    ## Try with smaller amplitudes (for currents)
    #@time s2 = s/1e-9

    fsk = freq2k(fs);
    for f in 0:10
        @test fsk(f*T) == fs(f)
    end

    #####
    # Inverse Fourier Series
    #####
    ifs = iFS(fs);
    dx = ℯ/2  # choose odd/non-periodic step size
    @test yvals(sample(ifs, dx)) ≈ yvals(sample(s, dx))
    @test iscontinuous(ifs)
end


@testset "discrete fourier transform" begin
    for m in [1, 1e-12] # second test for small currents
        T=10
        t = PWL(0:0.01:T, 0:0.01:T)
        sb = ymap_signal(t->m*(0.5 + 2cospi(2*2t) + 3sinpi(2*3t) + 10sinpi(2*10t)), t)
        # For lossless sampling need integer number of
        # samples of all freqs and 2 samples per cycle
        N = 2*lcm(10T, 3T, 2T)
        dft = DFT(sb; N);
        Fmin = 1/T
        #plot(dft)
        @test abs(dft(0)) ≈ 0.5*m atol=1e-9 # DC
        @test abs(dft(1))*2 < 1e-14*m
        @test abs(dft(2))*2 ≈ 2*m
        @test abs(dft(3))*2 ≈ 3*m
        @test abs(dft(4))*2 < 1e-14*m
        @test abs(dft(5))*2 < 1e-14*m
        @test abs(dft(6))*2 < 1e-13*m
        @test abs(dft(7))*2 < 1e-13*m
        @test abs(dft(8))*2 < 1e-14*m
        @test abs(dft(9))*2 < 1e-14*m
        @test abs(dft(10))*2 ≈ 10*m # 10 Hz

        @test ytype(dft) == Complex{Float64}

        dftk = freq2k(dft);
        for f in 0:10
            @test dftk(f*T) == dft(f)
        end
    end

    #atols = vcat(0, 10.0 .^ (-17:-3))
    #ts =[@elapsed(FS(s, freq, atol=atol)) for freq in 0:5, atol in atols]
    #plot(ts, yaxis=:log, label=atols')
    #mags =[abs(FS(s, freq, atol=atol)) for freq in 0:5, atol in 10.0 .^ (-9:-3)]

    #####
    # Inverse Discrete Fourier Transform
    #####
    T=10
    t = PWL(0:0.1:T, 0:0.1:T)
    s = ymap_signal(t->0.5 + 2cospi(2*2t) + 3sinpi(2*3t) + 10sinpi(2*10t), t)
    # For lossless sampling need integer number of samples of all freqs and 2 samples per cycle
    N = 2*lcm(10T, 3T, 2T)
    dft = DFT(s; N);
    @test !iscontinuous(dft)
    Fmin = 1/T
    Tstep = T/N
    idft = iDFT(dft, mode=complex);
    @test ytype(idft) == Complex{Float64}
    @test !iscontinuous(idft)
    dx = ℯ/2
    @test yvals(idft) ≈ yvals(sample(s, xvals(idft)))
    idft = iDFT(dft, mode=real);
    @test ytype(idft) == Float64
    @test !iscontinuous(idft)
    @test yvals(idft) ≈ yvals(sample(s, xvals(idft)))
end


@testset "convolution" begin
    # Example of RC circuit response:
    R=2000
    C=3e-8
    τ = R*C
    α = 1/τ
    fcorner = 1/τ
    t = range(0, 10τ, length=1001)
    h(t, τ) = 1/τ * exp(-t/τ) # impulse response
    ht = PWL(t, h.(t, τ))
    #plot(ht)
    c = ht(0)
    ht_scaled = (ht/ht(0))
    #@test ht.(t) / ht(0) == ht_scaled
    #plot(ht_scaled, label="impulse response")
    #plot(ht.(t) / ht(0))

    square_wave = PWL([0, eps(0.0), τ - eps(τ), τ], [0,1,1,0])
    yt = convolution(square_wave, ht)
    #plot(square_wave, label="input")
    #plot!(yt, label="output")
    @test yt(τ) ≈ 1 - exp(-1) atol=0.001

    # test scaled convolution
    s = PWL(1.0:4.0, Float64[0, 1, 1, 0])
    c = convolution(s, s)
    ss = xshift(xscale(s, 2), 2)
    cs = convolution(ss, ss)
    @test yvals(sample(c, 0.1)) ≈ yvals(sample(cs/2, 0.2))

    #freqs = 10 .^(0.0001:0.1:log10(6000))
    #analytic_mag(f, τ) = (1/τ)/sqrt((1/τ)^2 + (2pi*f)^2)
    #analytic_phase(f, τ) = atan(-2pi*f*τ)
    #an_mag = PWL(freqs, analytic_mag.(freqs, α))
    #an_ph = PWL(freqs, analytic_phase.(freqs, α))
    #plot(an_mag, label="theory")
    #f1 = clip(FT(s), extrema(freqs)...)
    #plot!(abs(f1), label="calculated")
    #plot(an_ph)

    #f = 1
    #f1 = FT(s, f)
    #a1m = analytic_mag(f, α)
    #a1p = analytic_phase(f, α)
    #f = 100
    #f1 = FT(s, f)
    #a1m = analytic_mag(f, α)
    #a1p = analytic_phase(f, α)

    #plot(mag, xaxis=:log)
    #ph = phased(fs)
    #plot(ph, xaxis=:log)
    #s = ZeroPad(ContinuousFunction(t->α * exp(-α*t)), 0..Inf)
    #plot(clip(s, 0 .. 1), xaxis=:log)
    #@time fs = abs(FT(clip(s, 0), 0:10))
    #@time abs(FT(s, 0:2:2000))
end