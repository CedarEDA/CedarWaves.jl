using CedarWaves
#using Unitful: V, s, Hz, ustrip, k, ms, kHz, dBV, °
using Test
import FFTA

# Invariants:
for x in [1:5, 1:6, 1:7, 1:8]
    for sb in subtypes(Sideband)
        @test length(dftbins(x, sb)) == length(dftfreqs(x, sb))
    end
end

# Converting sidebands:
@test UpperMirroredSideband(0:9, UpperMirroredSideband(10)) == 0:9
@test UpperMirroredSideband(0:10, UpperMirroredSideband(11)) == 0:10
@test UpperSideband(0:5, UpperSideband(10)) == 0:5
@test UpperSideband(0:5, UpperSideband(11)) == 0:5
@test LowerSideband(-5:0, LowerSideband(10)) == -5:0
@test LowerSideband(-5:0, LowerSideband(11)) == -5:0
@test DualSideband(-5:5, DualSideband(10)) == -5:5
@test DualSideband(-5:5, DualSideband(11)) == -5:5
# Convert from UpperMirroredSideband
@test UpperSideband(0:9, UpperMirroredSideband(10)) == 0:5
@test UpperSideband(0:10, UpperMirroredSideband(11)) == 0:5
@test LowerSideband(0:10, UpperMirroredSideband(11)) == -5:0

@testset "dftbins" begin
    ## dftbins:
    # Even case:
    NP=10
    x = range(0, 0.9, length=NP)
    Fs=1/(x[2]-x[1])  # sampling rate
    @test dftbins(x, UpperMirroredSideband) == 0:NP-1
    @test dftbins(x, DualSideband) == -NP÷2:NP÷2
    @test dftbins(x, DualUnscaledSideband) == -NP÷2:NP÷2
    @test dftbins(x, UpperSideband) == 0:NP÷2
    @test dftbins(x, UpperUnscaledSideband) == 0:NP÷2
    @test dftbins(x, LowerSideband) == -NP÷2:0
    @test dftbins(x, LowerUnscaledSideband) == -NP÷2:0
    # Odd case:
    NP=11
    x = range(0, 1, length=NP)
    Fs=1/(x[2]-x[1])  # sampling rate
    @test dftbins(x, UpperMirroredSideband) == 0:NP-1
    @test dftbins(x, DualSideband) == -NP÷2:NP÷2
    @test dftbins(x, DualUnscaledSideband) == -NP÷2:NP÷2
    @test dftbins(x, UpperSideband) == 0:NP÷2
    @test dftbins(x, UpperUnscaledSideband) == 0:NP÷2
    @test dftbins(x, LowerSideband) == -NP÷2:0
    @test dftbins(x, LowerUnscaledSideband) == -NP÷2:0
end

@testset "dftfreqs" begin
    # DFT freqs:
    # Even case:
    NP=10
    x = range(0, 0.9, length=NP)
    ΔT = x[2] - x[1] # sample time
    Tperiod = ΔT*NP
    Fs=1/ΔT  # sampling rate
    ΔF = Fs/NP # frequency steps of FFT
    ΔF = 1/(NP*ΔT)
    Fmax = Fs - ΔF
    Fmax_Nyquist = Fs/2
    @test dftfreqs(x, UpperMirroredUnscaledSideband) == 0:ΔF:Fmax
    @test dftfreqs(x, UpperMirroredSideband) == 0:ΔF:Fmax
    @test dftfreqs(x, DualSideband) == -Fs/2:ΔF:Fs/2
    @test dftfreqs(x, DualUnscaledSideband) == -Fs/2:ΔF:Fs/2
    @test dftfreqs(x, UpperSideband) == 0:ΔF:(Fs+ΔF/2)/2
    @test dftfreqs(x, UpperUnscaledSideband) == 0:ΔF:Fs/2
    @test dftfreqs(x, LowerSideband) == -Fs/2:ΔF:0
    @test dftfreqs(x, LowerUnscaledSideband) == -Fs/2:ΔF:0
    # Odd case:
    NP=11
    x = range(0, 1, length=NP)
    ΔT = x[2] - x[1] # sample time
    Tperiod = ΔT*NP
    Fs=1/ΔT  # sampling rate
    ΔF = Fs/NP # frequency steps of FFT
    ΔF = 1/(NP*ΔT)
    Fmax = Fs - ΔF
    @test dftfreqs(x, UpperMirroredSideband) ≈ 0.0:ΔF:Fmax
    @test dftfreqs(x, DualSideband) ≈ -Fmax/2:ΔF:Fmax/2
    @test dftfreqs(x, DualUnscaledSideband) ≈ -Fmax/2:ΔF:Fmax/2
    @test dftfreqs(x, UpperSideband) == 0:ΔF:Fmax/2
    @test dftfreqs(x, UpperUnscaledSideband) == 0:ΔF:Fmax/2
    @test dftfreqs(x, LowerSideband) ≈ -Fmax/2:ΔF:0
    @test dftfreqs(x, LowerUnscaledSideband) ≈ -Fmax/2:ΔF:0
end

x = 0:10
y = 2 .* x
H = FFTA.fft(y)
Hr = FFTA.rfft(y)
su = DFT(x, H, NP=length(y), signal_type=PWL, sideband=UpperMirroredSideband, scale=DFTUnscaled)
su(0.5)
DFT(x, Hr, NP=length(y), kind=PWLKind, sideband=UpperUnscaledSideband)