"""
    phase(real)
    phase(complex)
    phase(signal)

Returns the phase of a complex number or signal in radians.
Alias for [`angle`](@ref).

!!! tip
    Since `pi` is an approximate number it is better for accuracy to work in degrees, see [`phased`](@ref).

# Examples

```jldoctest
julia> phase(pi)
0.0

julia> s = phase(PWL(0:1, [1, im]));

julia> s(0.5) ≈ 2pi/8
true
```

See also
[`abs`](https://docs.julialang.org/en/v1/base/math/#Base.abs),
[`real`](https://docs.julialang.org/en/v1/base/math/#Base.real-Tuple{Complex}),
[`imag`](https://docs.julialang.org/en/v1/base/math/#Base.imag),
[`conj`](https://docs.julialang.org/en/v1/base/math/#Base.conj),
[`phased`](@ref),
[`angle`](@ref),
[`rad2deg`](https://docs.julialang.org/en/v1/base/math/#Base.Math.rad2deg),
[`deg2rad`](https://docs.julialang.org/en/v1/base/math/#Base.Math.deg2rad).
"""
phase(s::AbstractSignal) = ymap_signal(phase, s)
phase(x) = angle(x)
@signal_func phase

"""
    angle(x)
    angle(signal)

Returns a signal with the (complex) y-values converted to radians.
Alias for [`phase`](@ref).

!!! tip
    Since `pi` is an approximate number it is better for accuracy to work in degrees, see [`phased`](@ref).

# Examples

```jldoctest
julia> angle(1)
0.0

julia> angle(1 + 1im) ≈ 2pi/8
true

julia> s = angle(PWL(0:1, [1, im]));

julia> s(0.5) ≈ 2pi/8
true
```

See also
[`abs`](https://docs.julialang.org/en/v1/base/math/#Base.abs),
[`real`](https://docs.julialang.org/en/v1/base/math/#Base.real-Tuple{Complex}),
[`imag`](https://docs.julialang.org/en/v1/base/math/#Base.imag),
[`conj`](https://docs.julialang.org/en/v1/base/math/#Base.conj),
[`phase`](@ref),
[`phased`](@ref),
[`angle`](@ref),
[`rad2deg`](https://docs.julialang.org/en/v1/base/math/#Base.Math.rad2deg),
[`deg2rad`](https://docs.julialang.org/en/v1/base/math/#Base.Math.deg2rad).
"""
Base.angle(s::AbstractSignal) = ymap_signal(angle, s)
@signal_func Base.angle

"""
    phased(real)
    phased(complex)
    phased(signal)

Returns the phase of a complex number or signal in degrees.

# Examples

```jldoctest
julia> phased(1)
0.0

julia> phased(im)
90.0

julia> s = phased(PWL(0:1, [1, im]));

julia> s(0.5)
45.0
```

See also
[`abs`](https://docs.julialang.org/en/v1/base/math/#Base.abs),
[`real`](https://docs.julialang.org/en/v1/base/math/#Base.real-Tuple{Complex}),
[`imag`](https://docs.julialang.org/en/v1/base/math/#Base.imag),
[`conj`](https://docs.julialang.org/en/v1/base/math/#Base.conj),
[`phase`](@ref),
[`angle`](@ref),
[`rad2deg`](https://docs.julialang.org/en/v1/base/math/#Base.Math.rad2deg),
[`deg2rad`](https://docs.julialang.org/en/v1/base/math/#Base.Math.deg2rad).
"""
function phased end
phased(x::Real) = rad2deg(phase(x))
phased(x::Complex) = atand(imag(x), real(x))
phased(s::AbstractSignal) = ymap_signal(phased, s)
@signal_func phased
