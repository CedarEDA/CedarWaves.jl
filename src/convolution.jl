"""
    convolution(signal1, signal2)
Returns the convolution of the two signals.
The convolution is calcualted using a numerical integration of the product of the two signals (one flipped and shifted).

# Examples
```jldoctest
julia> triangle = PWL(-1:1, [0,1,0]);

julia> conv = convolution(triangle, triangle);

julia> conv(0) ≈ 2/3
true

julia> domain(triangle)
[-1.0 .. 1.0]

julia> domain(conv)
[-2.0 .. 2.0]
```

Calculate the response of an RC circuit given the impulse response:

```jldoctest
julia> R, C = 2000, 3e-6; # RC circuit

julia> τ = R*C
0.006

julia> t = PWL([0, 5τ], [0, 5τ]);

julia> hs = 1/τ * exp(-t/τ); # impulse response

julia> square_wave_input = PWL([0, τ], [1, 1]);

julia> yt = convolution(square_wave_input, hs);

julia> isapprox(yt(τ), 1 - exp(-1), atol=0.0001)
true
```

See also
[`impulse`](@ref),
[`autocorrelation`](@ref),
[`crosscorrelation`](@ref).
"""
function convolution(s1::AbstractSignal, s2::AbstractSignal; kwargs...)
    # convolution domain:
    x1 = xmin(s1) + xmin(s2)
    x2 = x1 + xspan(s1) + xspan(s2)
    base_x_interval = x1..x2
    # For τ domain (inner integral) use signal with smaller domain for better accuracy
    # Note: integrator can have trouble with a bunch of zeros and then missing a small glitch
    if xspan(s1) < xspan(s2)
        transform1 = s1
        dτ = domain(s1)
        # Zero pad outside clip range since convolution will go outside original domain at ends of signals
        transform2 = Window(s2, domain(s2))
    else
        transform1 = s2
        dτ = domain(s2)
        # Zero pad outside clip range since convolution will go outside original domain at ends of signals
        transform2 = Window(s1, domain(s1))
    end
    f(x) = integral(τ -> transform1(τ) * transform2(x-τ), dτ; kwargs...)
    X = promote_type(xtype(s1), xtype(s2))
    Y = promote_type(ytype(s1), ytype(s2))
    c = FiniteFunction{X, Y}(base_x_interval, f)
end
@signal_func convolution

"""
    crosscorrelation(sig1, sig2)
Computes the cross-correlation of two signals.

# Examples
```jldoctest
julia> s1 = PWL([2, 3, 4], [0, 2, 4]);

julia> s2 = PWL([3, 4, 5], [6, 3, 0]);

julia> corr = crosscorrelation(s1, s2);

julia> xmin(corr)
-1.0

julia> xmax(corr)
3.0

julia> corr.(-1:3) ≈ [0, 1, 8, 13, 0]
true
```
"""
function crosscorrelation(sig1::AbstractSignal, sig2::AbstractSignal; kwargs...)
    xshift(convolution(sig1, xflip(sig2); kwargs...), -(xmin(sig1) + xmax(sig1)))
end
@signal_func crosscorrelation

"""
    autocorrelation(signal)
Computes the autocorrelation of a signal.

# Examples
```jldoctest
julia> t = 0:0.005:1;

julia> freq = 1;

julia> y = @. sin(2pi*freq*t);

julia> s = PWL(t, y);

julia> autocorr = autocorrelation(s);

julia> ym = ymax(sample(autocorr, 0.005));

julia> isapprox(ym.x, 0, atol=1e-10)
true

julia> ≈(ym, 0.5, atol=1e-4)
true
```
"""
function autocorrelation(s::AbstractSignal)
    crosscorrelation(s, s)
end
@signal_func autocorrelation
