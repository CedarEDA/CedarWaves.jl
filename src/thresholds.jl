"""
A y-crossing with a direction of `rising`, `falling` or `either`.
"""
abstract type Threshold end

"""
    rising(yth)

A rising edge with a crossing threshold.

# Examples:

To trigger on a rising edge at y-value of 0.5

```@repl
rising(0.5)
```
"""
struct rising <: Threshold
    value::Float64
end
"""
    falling(yth)

A falling edge with a crossing threshold.

See also [`pct`](@ref).

# Examples:

To trigger on a falling edge at y-value of 0.5

```@repl
falling(0.5)
```
"""
struct falling <: Threshold
    value::Float64
end
"""
    either(yth)

A rising or falling edge with a crossing threshold.

# Examples:

To trigger on either a rising or falling edge at y-value of 0.5

```@repl
either(0.5)
```
"""
struct either <: Threshold
    value::Float64
end

"The rising edge threshold"
rising(th::Threshold) = rising(th.value)
"The falling edge threshold"
falling(th::Threshold) = falling(th.value)
"The rising or falling edge threshold"
either(th::Threshold) = either(th.value)
Base.isless(th1::Threshold, th2::Threshold) = isless(th1.value, th2.value)
Base.isless(th1::Threshold, th2::Real) = isless(th1.value, th2)
Base.isless(th1::Real, th2::Threshold) = isless(th1.value, th2)
Base.isnan(th::Threshold) = isnan(th.value)

# These convert a non-threshold into the y-value but have no direction
#function _resolve_thresh(s::AbstractSignal, thresh::pct)
#    min, max = extrema(s)
#    fraction = convert(Float64, thresh)
#    return fraction*max + (1-fraction)*min
#end
#function _resolve_thresh(s::AbstractSignal, thresh::UReal)
#    thresh
#end

# If threshold has a direction
#function resolve_thresh(s::AbstractSignal, thresh::rising)
#    rising(_resolve_thresh(s, thresh.value))
#end
#function resolve_thresh(s::AbstractSignal, thresh::falling)
#    falling(_resolve_thresh(s, thresh.value))
#end
#function resolve_thresh(s::AbstractSignal, thresh::either)
#    either(_resolve_thresh(s, thresh.value))
#end
#
## If threshold doesn't have a direction
#function resolve_thresh(s::AbstractSignal, thresh)
#    either(_resolve_thresh(s, thresh))
#end

# Math operators for thresholds
for func in BINARY_OPERATORS
    @eval begin
        function (Base.$func)(m1::T1, m2::T2) where {T1<:Threshold, T2<:Threshold}
            ($func)(m1.value, m2.value)
        end
    end
end
for func in UNARY_OPERATORS
    @eval begin
        function (Base.$func)(m::T) where T <: Threshold
            ($func)(m.value)
        end
    end
end
for func in INEQUALITY_OPERATORS
    @eval begin
        function (Base.$func)(m1::T1, m2::T2) where {T1<:Threshold, T2<:Threshold}
            ($func)(m1.value, m2.value)
        end
        function (Base.$func)(m1::T1, m2::Real) where T1<:Threshold
            ($func)(m1.value, m2)
        end
        function (Base.$func)(m1::Real, m2::T1) where T1<:Threshold
            ($func)(m1, m2.value)
        end
    end
end
Threshold(m::Threshold) = m
Threshold(y::Real) = either(y)
Base.AbstractFloat(m::Threshold) = float(m.value)
Base.isfinite(m::Threshold) = isfinite(m.value)

Base.promote_rule(::Type{M}, ::Type{S}) where {M<:Threshold, S<:AbstractFloat} = Float64
Base.promote_rule(::Type{M}, ::Type{S}) where {M<:Threshold, S<:Integer} = Float64
Base.Float64(m::Threshold) = convert(Float64, m.value)

Base.hash(m::Threshold, h::UInt) = hash(m.value, h)
Base.:(==)(m1::Threshold, m2::Threshold) = typeof(m1) == typeof(m2) && m1.value == m2.value

function check_percents(; kwargs...)
    for (name, value) in kwargs
        if !(0 <= value <= 1)
            throw(ArgumentError("$name: percentages must be between 0 and 1: found $value"))
        end
    end
end
function check_percents(vals::Vector)
    for value in vals
        if !(0 <= value <= 1)
            throw(ArgumentError("percentages must be between 0 and 1: found $value"))
        end
    end
end