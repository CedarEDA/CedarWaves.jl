"""
    dB20(x)
    dB20(signal)

Returns `20*log10(x)`.  For a signal it operates on the y-values.
If the value is complex then `abs(x)` is used.
Typically used to convert a signal in volts to dB.

# Examples

```jldoctest
julia> dB20(100)
40.0

julia> s = dB20(PWL([1, 10], [1, 10]));

julia> s(2)
6.020599913279624

julia> s(10)
20.0
```

See also
[`dB10`](@ref),
[`dBm`](@ref).
"""
function dB20 end
function dB20(x::Real)
    20*log10(x)
end
function dB20(x::Complex)
    20*log10(abs(x))
end
function dB20(s::AbstractSignal)
    ymap_signal(dB20, s)
end
@signal_func dB20

"""
    dB10(x)
    dB10(signal)

Returns `10*log10(x)`.  For a signal it operates on the y-values.
If the value is complex then `abs(x)` is used.
Typically used to convert a value in watts to dB.

# Examples

```jldoctest
julia> dB10(100)
20.0

julia> s = dB10(PWL([1, 10], [1, 10]));

julia> s(2)
3.010299956639812

julia> s(4)
6.020599913279624

julia> s(10)
10.0
```

See also
[`dB20`](@ref),
[`dBm`](@ref).
"""
function dB10 end
function dB10(x::Real)
    10*log10(x)
end
function dB10(x::Complex{T}) where T
    10*log10(abs(x))
end
function dB10(s::AbstractSignal)
    ymap_signal(dB10, s)
end
@signal_func dB10

"""
    dBm(x)
    dBm(signal)

Returns `10*log10(x)+30`.  For signals it operates on the y-values.
If the value is complex then `abs(x)` is used.
Typically used to convert to watts to decibel relative to 1 mW.

```jldoctest
julia> dBm(100)
50.0

julia> dBm(PWL(1:10, 1:10));

julia> dBm(1)
30.0

julia> dBm(10)
40.0
```

See also
[`dB10`](@ref),
[`dB20`](@ref).
"""
function dBm end
function dBm(x::Real)
    10*log10(x)+30
end
function dBm(x::Complex{T}) where T
    10*log10(abs(x))+30
end
function dBm(s::AbstractSignal)
    ymap_signal(dBm, s)
end
@signal_func dBm


"""
    logspace(start, stop; length)

Returns logarithmically spaced values with `length` points from `start` to `stop`.

# Examples

```jldoctest
julia> logspace(0.1, 1000, length=5)
5-element Vector{Float64}:
    0.1
    1.0
   10.0
  100.0
 1000.0
```
"""
function logspace(start, stop; length)
    # log is faster than log10 but log10 has better accuracy for 10x multiples
    v = 10 .^ range(log10(start), log10(stop); length)
    # Fix possible floating point error with first and last value
    v[1] = start
    v[end] = stop
    return v
end
