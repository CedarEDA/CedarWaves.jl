module CedarWaves
using TestItems
import RecipesBase
import DataInterpolations
import ForwardDiff
import QuadGK
import Statistics
import Statistics: mean, std # needed for docstring definitions
export mean, std
import FunctionWrappers: FunctionWrapper
using Requires
import ScaledNumbersOutput
export AbstractSignal, AbstractIterableSignal, AbstractArraySignal, AbstractContinuousSignal
export AbstractMeasure, FunctionMeasure
export ymin, ymax
export XMeasure, YMeasure, YLevelMeasure, DxMeasure, DyMeasure
export DerivedMeasure
export CrossMeasure, eachcross, crosses, cross, clipcrosses
# Internal API, don't export:
#export eachcrosspattern, crosspatterns, crosspattern
export Threshold, rising, falling, either, ThresholdGroup, rel2abs_thresholds
export TransitionMeasure, transitions, eachtransition, transition
export RisetimeMeasure, eachrisetime, risetimes, risetime
export FalltimeMeasure, eachfalltime, falltimes, falltime
export PeriodMeasure, eachperiod, periods, period, eachfrequency, frequencies, frequency
export SlopeMeasure, eachslewrate, slewrates, slewrate
export DelayMeasure, eachdelay, delays, delay
export BandwidthMeasure, bandwidth
export dutycycle, dutycycles
export monotonicity
export FFT, iFT, FS, iFS, DFT, iDFT, FFT, iFFT, freq2k
export zeropad, ZeroPad
export xflip

const signal_funcs = Function[]
macro signal_func(f)
    return quote
        push!(CedarWaves.signal_funcs, $(esc(f)))
    end
end

include("scaling_factors.jl")
include("interval.jl")
include("signal.jl")
include("pointfinder.jl")
include("operators.jl")
include("thresholds.jl")
include("measure.jl")
include("base_math.jl")
include("stats.jl")
include("fourier.jl")
include("logarithms.jl")
include("phase.jl")
include("integral.jl")
include("convolution.jl")
#include("percent.jl")
include("cross.jl")
include("signal_zoo.jl")
#include("memoize.jl") # not used yet
include("filter.jl")
include("dutycycle.jl")
include("flip.jl")
# include("online.jl")
include("measure_timing.jl")
include("delay.jl")
include("monotonicity.jl")
include("glitch.jl")
include("check.jl")
include("makie.jl")

function __init__()
    @require Tables = "bd369af6-aec1-5ad0-b16a-f7cc5008161c" include("tables.jl")
    # Force WGLMakie to resize to body, which gets automatic resizing in VSCode
    try
        WGLMakie.activate!(;resize_to = :body)
    catch
    end
end

export AbstractSignal, OnlineSignal, ArraySignal, ContinuousSignal, InfiniteFunction, FiniteFunction, InfiniteSeries
export Interval
export PWL, PWC, PWAkima, PWQuadratic, PWCubic, Series
export eachxy, eachx, eachy, xvals, yvals, domain, xtype, ytype
export xscale, xshift, zeropad, clip, xspan, xmin, xmax, peak2peak, SIN, pulse
export resample, derivative, ymap_signal, iscontinuous, isdiscrete
export eachglitch, glitches, glitch, GlitchMeasure
export eachovershoot, overshoots, overshoot, OvershootMeasure
export eachundershoot, undershoots, undershoot, UndershootMeasure
export crosses, eachcross, Periodic, rms, integral, sample, bitpattern, phase, phased
export Lowpass, Highpass, Bandpass, Bandstop, firfilter, iirfilter, filt, Butterworth
export FT, iFT, FS, iFS, DFT, iDFT, freq2k, convolution, crosscorrelation, autocorrelation, impulse
export logspace, dB10, dB20, dBm, phased
export extract_supply_levels, rel2abs_thresholds
export ..
end
