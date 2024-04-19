import FFTA
@noinline function check_valid_mode(mode)
    if !(mode === real || mode === complex)
        throw(ArgumentError("argument `mode` must be one of `real`, `complex`, got $(repr(mode))"))
    end
end

"""
    fftshift(vals)
Rearrange the values such that the upper half are aliased down to negative frequencies.
The input is assumed to be the raw output of a FFT kernel.
"""
function fftshift end
function fftshift(vec)
    out = similar(vec)
    half = div(lastindex(vec), 2)
    @inbounds for i in firstindex(vec):half
        out[i] = vec[i+half]
    end
    @inbounds for i in half+1:lastindex(vec)
        out[i] = vec[i-half]
    end
    out
end
function fftshift(s::AbstractSignal)
    error("not implemented yet")
end


"""
    FT(signal[, integral_options...])
Return a `Signal` which is the Fourier Transform function of another continuous signal, `signal`, with infinite duration,
according to the formula:

```math
\\big(\\mathrm{FT}(s)\\big)(\\mathit{freq}) = S(\\mathit{freq}) = \\int_{-\\infty}^{+\\infty} s(x) \\exp(-j 2\\pi \\mathit{freq}\\,x) \\,\\mathrm{d}x
```

The Fourier Transform is for aperiodic signals of infinite duration.
Input signals with finite duration are automatically zero padded to ±infinity.
To get the value of the Fourier Transform call the transform with the frequency of interest:

```julia
julia> ft = FT(signal);

julia> ft(0) # DC value
0.5 + 0.0im
```

# Options

* `integral_options` are options that can be passed to [`integral`](@ref).

!!! note
    By default the output domain of the transform is clipped to `±10/xspan(signal)`.
    To change the domain use `extrapolate` like `extrapolate(FT(signal), 0 .. 1e6)`. Infinite domains
    are not returned by default because they cannot be plotted (in finite time).

# Examples

For an ideal pulse in the time domain of 2 seconds and amplitude 10 we use an ideal
square wave (no risetime) and the Fourier Transforms assumes the signal is zero
outside of its defined domain.  Since the pulse is centered around zero it is an
even function so the Fourier Transform will be real values only.

```jldoctest
julia> A=10;

julia> w=2;

julia> pulse = PWL([-w/2, w/2], [A, A]);

julia> ft = FT(pulse);

julia> analytic_solution(freq; A=A, w=w) = A*w*sinc(freq*w);

julia> ft(0) == analytic_solution(0)
true

julia> ft(0.25) ≈ analytic_solution(0.25)
true
```

The following example uses the Fourier Transform to compute the Fourier Series components
by dividing the FT by `xspan(s)` to normalize the results to periodic sinusoid amplitudes:

```jldoctest
julia> t = PWL(0:0.1:2, 0:0.1:2);

julia> s = 0.5 + 3sinpi(2*2t) + 2cospi(2*4t);

julia> ft = abs(FT(s)/xspan(s));

julia> hk = Series(-4:4, ft); # sample Fourier Series components

julia> abs(hk(0)) ≈ 0.5 # DC component
true

julia> abs(hk(2)) + abs(hk(-2)) ≈ 3 # 2 Hz component
true

julia> abs(hk(4)) + abs(hk(-4)) ≈ 2 # 4 Hz component
true

julia> abs(hk(3)) + abs(hk(-3)) < 1e-15 # 4 Hz component
true
```

The above is useful if the Fourier Series components are wanted but
with the x-axis being frequency instead of an integer multiplies
of the fundamental harmonic `1/xspan(s)`.

See also
[`FS`](@ref),
[`DFT`](@ref),
[`iFT`](@ref),
[`iFS`](@ref),
[`iDFT`](@ref).
"""
function FT(s::AbstractContinuousSignal;
            kwargs...)
    InfiniteFunction{Float64, ComplexF64}(freq -> integral(t -> s(t) * cispi(-2*freq*t), domain(s); kwargs...))
end
@signal_func FT

"""
    iFT(signal, [clip, mode, integral_options...])
Return a `Signal` which is the Inverse Fourier Transform function of a continuous signal, `signal`, according to the formula:

```math
\\big(\\mathrm{iFT}(S)\\big)(x) = s(x) = \\frac{1}{2\\pi}\\int_{-\\infty}^{+\\infty} S(\\mathit{freq}) \\exp(j 2\\pi \\mathit{freq}\\, x) \\,\\mathrm{d}\\mathit{freq}
```

The Inverse Fourier Transform is for aperiodic signals.  To get the value of
the Inverse Fourier Transform call the transform with the frequency of interest:

```julia
julia> ift = iFT(signal);

julia> ift(0, mode=real) # at time zero
0.5

julia> inspect(ift) # plot the result
```

# Options

* `clip` is an interval of the Inverse Fourier Transform result.  By default it is ±10 times `1/xspan(signal)`.
    The Inverse Fourier Transform itself goes from -Inf..Inf and the time domain can be changed with clipping the result
    again `extrapolate(FT(signal), 0 .. 0.001)` (which is equivalent to `iFT(signal, clip=0 .. 0.001)`).  Infinite domains
    are not returned by default because they cannot be plotted.
* `mode` can be one `real` or `complex`. The default is `real` which
    returns the time domain signal as real numbers.
* `integral_options` are options that can be passed to [`integral`](@ref).


See also
[`FT`](@ref),
[`FS`](@ref),
[`DFT`](@ref),
[`iFS`](@ref),
[`iDFT`](@ref).
"""
function iFT(Xf::AbstractContinuousSignal;
            mode=real,
            kwargs...)
    check_valid_mode(mode)
    interval = domain(Xf)
    full_transform = if mode === real
            t-> integral(f -> real(Xf(f) * cispi(2*f*t)), interval; kwargs...)
        else
            # Could maybe split this into real and imag parts and use two real integrals (needs benchmarking)
            t-> integral(f -> Xf(f) * cispi(2*f*t), interval; kwargs...)
        end
    YT = mode === real ? Float64 : ComplexF64
    InfiniteFunction{Float64, YT}(full_transform)
end
@signal_func iFT

"""
    DTFT(signal; [, integral_options...])
!!! warning
    This is not yet implemented.

Returns a Discrete Time Fourier Transform function of a discrete signal, `signal`, sampled
at uniform points, according to the formula:

```math
\\big(\\mathrm{DTFT}(s)\\big)(\\mathit{freq}) = S(\\mathit{freq}) = \\sum_{n=-\\infty}^{\\infty} s(n T_\\mathit{step}) \\exp\\left(-j 2\\pi \\mathit{freq}\\,n\\right)
```

The Discrete Time Fourier Transform is for discrete aperiodic signals of infinite duration.
Input signals with finite duration are automatically zero padded to ±infinity.
The output is a function of the frequency `freq` which is from -0.5 to 0.5.
To get the value of the Discrete Time Fourier Transform call the transform with the frequency of interest:

```julia
julia> dtft = DTFT(signal);

julia> dtft(0) # DC value
0.5 + 0.0im
```

# Options

* `integral_options` are options that can be passed to [`integral`](@ref).

See also
[`FS`](@ref),
[`DFT`](@ref),
[`iFT`](@ref),
[`iFS`](@ref),
[`iDFT`](@ref).
"""
function DTFT(s::AbstractSignal;
            kwargs...)
    error("not yet implemented")
end
@signal_func DTFT

"""
    iDFT(signal, [mode, integral_options...])
!!! warning
    This is not yet implemented.

Return a `Signal` which is the Inverse Discrete Time Fourier Transform function of a discrete signal, `signal`.


See also
[`FT`](@ref),
[`FS`](@ref),
[`DFT`](@ref),
[`iFS`](@ref),
[`iDFT`](@ref).
"""
function iDTFT(Xf::AbstractSignal;
            mode=real,
            kwargs...)
    error("not yet implemented")
end
@signal_func iDTFT



"""
    FS(signal[, integral_options...])
Returns a Fourier Series function of a continuous-time signal, `signal`, with finite duration
according to the formula:

```math
\\big(\\mathrm{FS}(s)\\big)(\\mathit{freq}) = S(\\mathit{freq}) = \\frac{1}{T} \\int_{0}^{T} s(x) \\exp\\left(-j 2\\pi \\mathit{freq}\\, x\\right) \\,\\mathrm{d}x
```

The frequency-domain series returned is discrete and infinite extent with components at `freq = k*Fmin` where `k = ... -2, -1, 0, 1, 2 ...`.

```julia
julia> T = 2
2

julia> pulse = extrapolate(ZeroPad(PWL([-T/4, T/4], [1.0, 1.0])), -T/2 .. T/2);

julia> fs = real(FS(pulse));

julia> fs(0) # DC value
julia> fs(1) # 0.5 Hz
julia> fs(2) # 1.0 Hz
julia> fs(3) # 2.0 Hz
julia> fs(4) # 2.5 Hz
julia> fs(5) # 3.0 Hz
julia> fs = FS(signal);

julia> fs(0) # DC value
0.5 + 0.0im

julia> inspect(fs) # plot the result
```

# Options

* `integral_options` are options that can be passed to [`integral`](@ref).

!!! note
    By default the domain of the transform is clipped to `0 .. 10`.
    To change the domain use `extrapolate` like `extrapolate(FS(signal), 0 .. 100)`. Infinite domains
    are not returned by default because they cannot be plotted (in finite time).

See also
[`FT`](@ref),
[`DFT`](@ref),
[`iFT`](@ref),
[`iFS`](@ref),
[`iDFT`](@ref).
"""
function FS(s::AbstractContinuousSignal;
            periodic_discrepancy=1e-9,
            kwargs...)
    Δy = s(xmax(s)) - s(xmin(s))
    if abs(Δy) > periodic_discrepancy
        @warn("input signal to Fourier Series appears to be non-periodic at boundary: Δy = $(Δy)")
    end
    interval = domain(s)
    F = 1/xspan(s)
    # TODO: check for f being a multiple of Fmin?
    # de(k) = throw(DomainError(k, "Fourier Series is only defined for integers"))
    callable = f -> F*integral(t -> s(t) * cispi(-2*f*t), interval; kwargs...)
    InfiniteSeries{typeof(F), ComplexF64}(F, callable)
end
@signal_func FS

"""
    iFS(series, time_interval[; mode, integral_options...])
Returns a Inverse Fourier Series function of a discrete frequency-domain series,
`series`, according to the formula:

```math
\\big(\\mathrm{iFS}(S)\\big)(x) = s(x) = \\sum_{\\mathit{freq}=-\\infty}^{+\\infty} S(\\mathit{freq}) \\exp\\left(j 2\\pi \\mathit{freq}\\, x\\right)
```

where `freq` is a multiple of `k*Fmin` and `k = ... -2, -1, 0, 1, 2, ...`.

```julia
julia> fs = iFS(signal, 0 .. 1e-9);

julia> fs(0) # DC value
0.5 + 0.0im

julia> inspect(fs) # plot the result
```

# Arguments

* `mode` can be one `real` or `complex`. The default is `real` which
    returns the time domain signal as real numbers.
* `integral_options` are options that can be passed to [`integral`](@ref).

!!! warning
    Inifinite extent signals cannot be computed in finite time so ensure to clip the
    frequency domain signal to be finite.

See also
[`FT`](@ref),
[`FS`](@ref),
[`DFT`](@ref),
[`iFT`](@ref),
[`iDFT`](@ref).
"""
function iFS(Xf::AbstractArraySignal;
            mode=real,
            kwargs...)
    Fmin = step(xvals(Xf))
    T = 1/Fmin
    interval = 0.0 .. T
    if mode === real
        fr(t) = sum(real(y * cispi(2*f*t)) for (f, y) in Xf)
        return FiniteFunction{Float64, Float64}(interval, fr)
    elseif mode === complex
        fc(t) = sum(y * cispi(2*f*t) for (f, y) in Xf)
        return FiniteFunction{Float64, ComplexF64}(interval, fc)
    else
        throw(ArgumentError("`mode` must be one of `real` or `complex`"))
    end
end
@signal_func iFS

# Constructor to create a range given an interval and snaped to grid step
function interval_to_grid_range(interval::Interval, grid_step)
    f1 = ceil(first(interval)/grid_step)*grid_step
    f2 = floor(last(interval)/grid_step)*grid_step
    N = round(Int, (f2-f1)/grid_step) + 1 # to get correct endpoints with floating point rounding
    range(f1, f2, length=N)
end

"""
    DFT(s; N)
Returns a Discrete Fourier Transform function of a continuous signal, `s`, sampled
at `N` uniform points, according to the formula:

```math
\\big(\\mathrm{DFT}(s)\\big)(\\mathit{freq}) = S(\\mathit{freq}) = \\frac{1}{N} \\sum_{n=0}^{N-1} s(n T_\\mathit{step}) \\exp\\left(-j 2\\pi \\mathit{freq}\\, n T_\\mathit{step}\\right)
```

where:
- `N` is the number of uniform sampling points over the the `signal`
- `freq` is in Hertz and is a muliple of `Fmin = 1/xspan(signal)`
- `Tstep` is `xspan(signal)/N`

The input signal is assumed to be periodic outside of its (clipped) domain such that
`s(t) = s(t+N*Tstep)` for all `t`.

# Options
* `N` is the number of samples to use over the period.

!!! note
    The DFT is two-sided meaning the amplitude of a signal is half at the positive
    frequency and half at the negative frequency (except for DC).

# Examples

```julia
julia> dft = DFT(signal);

julia> dft(0) # DC value
0.5 + 0.0im

julia> inspect(dft) # plot the result
```

!!! note
    By default the domain of the transform is clipped to `0 .. 10`.
    To change the domain use [`extrapolate`](@ref) like `extrapolate(DFT(signal), 0 .. 100)`. Infinite domains
    are not returned by default because they cannot be plotted (in finite time).

See also
[`FT`](@ref),
[`FS`](@ref),
[`iFT`](@ref),
[`iFS`](@ref),
[`iDFT`](@ref).
"""
function DFT(s::AbstractContinuousSignal;
    N::Int,
    periodic_discrepancy=1e-9)
    ys = yvals(s)
    Δy = first(ys) - last(ys)
    if abs(Δy) > periodic_discrepancy
        @warn("input signal to DFT appears to be non-periodic at boundary: Δy = $(Δy)")
    end
    xs = range(xmin(s), xmax(s), length=N+1)[1:end-1]
    samples = s.(xs)
    s = ArraySignal(xs, samples)
    DFT(s)
end
function DFT(s::AbstractIterableSignal)
    if !(xvals(s) isa AbstractRange)
        @error("input signal to DFT may not be uniformly sampled")
    end
    # Step size of frequency (x-axis):
    T = xspan(s)+step(xvals(s))
    N = length(s)
    Fmin = 1/T
    # For N points from 0 to N-1, Fmax will be one less:
    #Fmax = (N-1)*Fmin
    # f is input var and it should be a multiple of Fmin but seems tricky to check (skip for now)
    callable = f -> sum(((t, y),) -> y * cispi(-2*f*t), s)/N
    # callable = f -> sum(s(t) * cispi(-2*f*t) for t in xs)::ComplexF64/N
    FNyquist = Fmin*(N÷2)
    interval = -FNyquist .. FNyquist
    x = interval_to_grid_range(interval, Fmin)
    ArraySignal(x, callable.(x))
end
@signal_func DFT

"""
    iDFT(series[; mode=real])
Returns an inverse Discrete Fourier Transform function of a discrete frequency-domain series,
`series`, according to the formula:

```math
\\big(\\mathrm{iDFT}(S)\\big)(x) = s(x) = \\sum_{n=0}^{N-1} S(\\mathit{freq}) \\exp\\left(j 2\\pi \\mathit{freq}\\, n \\,T_\\mathit{step}\\right)
```

```julia
julia> idft = iDFT(signal, 0 .. 1e-9, mode=real);

julia> idft(0) # time zero value
0.5

julia> inspect(idft) # plot the result
```

# Arguments

* `mode` can be one `real` or `complex`. The default is `real` which
    returns the time domain signal as real numbers.

See also
[`FT`](@ref),
[`FS`](@ref),
[`DFT`](@ref),
[`iFT`](@ref),
[`iDFT`](@ref).
"""
function iDFT(Xf::AbstractArraySignal;
            mode=real)
    check_valid_mode(mode)
    callable = if mode === real
            t -> sum(real(y * cispi(2*freq*t)) for (freq, y) in Xf)
        else # mode === complex
            t -> sum(y * cispi(2*freq*t) for (freq, y) in Xf)
        end
    T = 1/step(xvals(Xf))
    Tstep = T/(length(Xf)-1)
    interval = 0.0..T
    x = interval_to_grid_range(interval, Tstep)
    ArraySignal(x, callable.(x))
end
@signal_func iDFT

"""
    freq2k(Xf)

Scales the x axis of a DFT signal from frequency to bin index.

See also
[`DFT`](@ref),
[`iDFT`](@ref).
"""
function freq2k(Xf::AbstractArraySignal)
    Fmin = 1/step(xvals(Xf))
    # k = freq/Fmin
    xscale(Xf, Fmin)
end
@signal_func freq2k



function _FFT(y::AbstractArray, xdiff::Real)
    N = length(y)
    Y = FFTA.fft(y) ./ N
    freqs = (1 / xdiff) .* (-(N-1)/2:(N-1)/2)
    Series(freqs, fftshift(Y))
end

function FFT(s::AbstractIterableSignal)
    y = yvals(s)
    xdiff = xspan(s)
    _FFT(y, xdiff)
end

"""
    FFT(s; N=1024)
Returns a Fast Fourier Transform of a signal evaluated at N points.

# Examples
```jldoctest
julia> freq = 100;

julia> t = 0:1e-3:1.025;

julia> y = sin.(2π * freq .* t);

julia> s = PWL(t, y);

julia> ft = FFT(s);

julia> ym = ymax(abs(ft));

julia> abs(freq - abs(ym.x)) < 1 / xspan(s)
true
```
"""
function FFT(s::AbstractContinuousSignal; N=1024)
    xstep = (xmax(s) - xmin(s)) / (N + 1)
    xr = xmin(s):xstep:(xmax(s)-xstep)
    samples = s.(xr)
    _FFT(samples, xspan(s))
end
@signal_func FFT

# TODO: add iFFT
