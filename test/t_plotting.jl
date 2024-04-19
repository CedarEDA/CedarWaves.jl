using CedarWaves, Test
using WGLMakie

const CW = CedarWaves
@testset "Plotting" begin
    @test CW.idx2str(4) == "[4]"
    @test CW.idx2str(CartesianIndex(3,4,3)) == "[3,4,3]"

    s = PWL(0:10, 10:-1:0)
    m = XMeasure(s, 5)
    @test CW.default_title(s) isa AbstractString
    @test CW.default_title(m) isa AbstractString
    @test CW.default_title([s, 2s]) isa AbstractString
    # @test CW.default_title([m, m]) isa AbstractString

    @test CW.allsame(length, ["a", "b", "c"], 0) == 1
    @test CW.allsame(length, ["aa", "b", "c"], 0) == 0

    @test CW.is_freq_signal(s) == false
    sfreq = PWL(1:10000, complex.(rand(10000), rand(10000)))
    @test CW.is_freq_signal(sfreq) == true
    # Time domain quadrature signal
    t = range(0, 1e-6, length=101)
    yreal = range(0.0, 10.0, length=101)
    yimag = range(10, 0.0, length=101)
    squadrature = PWL(t, complex.(yreal, yimag))
    @test CW.is_freq_signal(squadrature) == false

    @test CW.default_xtickformat() isa Function
    @test CW.default_ytickformat() isa Function



    @test CW.default_transform(s) == identity
    @test CW.default_transform2(s) == identity
    @test CW.default_xscale(s) == identity
    @test CW.default_yscale(s) == identity
    @test CW.default_yscale2(s) == identity
    @test CW.default_xlabel(s) == ""
    @test CW.default_ylabel(s) == "Amplitude"
    @test inspect(s) isa Figure

    @test CW.default_transform(sfreq) == dB10
    @test CW.default_transform2(sfreq) == phased
    @test CW.default_xscale(sfreq) == log10
    @test CW.default_yscale(sfreq) == identity
    @test CW.default_yscale2(sfreq) == identity
    @test CW.default_xlabel(sfreq) == "Frequency (Hz)"
    @test CW.default_ylabel(sfreq) == "Magnitude (dB10)"
    @test inspect(sfreq) isa Figure

    @test CW.default_transform(squadrature) == abs
    @test CW.default_transform2(squadrature) == phased
    @test CW.default_xscale(squadrature) == identity
    @test CW.default_yscale(squadrature) == identity
    @test CW.default_yscale2(squadrature) == identity
    @test CW.default_xlabel(squadrature) == ""
    @test CW.default_ylabel(squadrature) == "Magnitude"
    @test inspect(squadrature) isa Figure

    @test CW.default_transform(m) == identity
    @test CW.default_transform2(m) == identity
    @test CW.default_xscale(m) == identity
    @test CW.default_yscale(m) == identity
    @test CW.default_yscale2(m) == identity
    @test CW.default_xlabel(m) == ""
    @test CW.default_ylabel(m) == "Amplitude"
    @test inspect(m) isa Figure

    @test CW.default_transform([s, s]) == identity
    @test CW.default_transform2([s, s]) == identity
    @test CW.default_xscale([s, s]) == identity
    @test CW.default_yscale([s, s]) == identity
    @test CW.default_yscale2([s, s]) == identity
    @test CW.default_xlabel([s, s]) == ""
    @test CW.default_ylabel([s, s]) == "Amplitude"
    @test inspect([s, 2s]) isa Figure

    @test CW.default_transform([sfreq, m]) == identity
    @test CW.default_transform2([sfreq, m]) == identity
    @test CW.default_xscale([sfreq, m]) == identity
    @test CW.default_yscale([sfreq, m]) == identity
    @test CW.default_yscale2([sfreq, m]) == identity
    @test CW.default_xlabel([sfreq, m]) == ""
    @test CW.default_ylabel([sfreq, m]) == ""
    @test_broken inspect([sfreq, m]) isa Figure

    @test CW.default_transform([sfreq, sfreq]) == dB10
    @test CW.default_transform2([sfreq, sfreq]) == phased
    @test CW.default_xscale([sfreq, sfreq]) == log10
    @test CW.default_yscale([sfreq, sfreq]) == identity
    @test CW.default_yscale2([sfreq, sfreq]) == identity
    @test CW.default_xlabel([sfreq, sfreq]) == "Frequency (Hz)"
    @test CW.default_ylabel([sfreq, sfreq]) == "Magnitude (dB10)"
    @test inspect([sfreq, sfreq]) isa Figure

    @test CW.default_transform([m, m]) == identity
    @test CW.default_transform2([m, m]) == identity
    @test CW.default_xscale([m, m]) == identity
    @test CW.default_yscale([m, m]) == identity
    @test CW.default_yscale2([m, m]) == identity
    @test CW.default_xlabel([m, m]) == ""
    @test CW.default_ylabel([m, m]) == "Amplitude"
    @test inspect([m, m]) isa Figure

    ss = [s 2s; 3s 4s]
    @test CW.default_transform(ss) == identity
    @test CW.default_transform2(ss) == identity
    @test CW.default_xscale(ss) == identity
    @test CW.default_yscale(ss) == identity
    @test CW.default_yscale2(ss) == identity
    @test CW.default_xlabel(ss) == ""
    @test CW.default_ylabel(ss) == "Amplitude"
    @test inspect(ss) isa Figure

    sv = [[s], [2s, 3s], [4s, 5s]]
    @test CW.default_transform(sv) == identity
    @test CW.default_transform2(sv) == identity
    @test CW.default_xscale(sv) == identity
    @test CW.default_yscale(sv) == identity
    @test CW.default_yscale2(sv) == identity
    @test CW.default_xlabel(sv) == ""
    @test CW.default_ylabel(sv) == "Amplitude"
    @test inspect(sv) isa Figure

end
