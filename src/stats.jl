"""
    xmin(signal)

Returns the minimum x-value of a signal.

# Examples

```jldoctest
julia> xmin(PWC(0:2, rand(3)))
0
```

See also
[`xmax`](@ref),
[`xspan`](@ref),
[`ymin`](@ref),
[`ymax`](@ref),
[`minimum`](@ref),
[`maximum`](@ref),
[`extrema`](@ref),
[`peak2peak`](@ref).
"""
xmin(s::AbstractSignal) = minimum(domain(s))
@signal_func xmin

"""
    xmax(signal)

Returns the maximum x-value of a signal.

# Examples

```jldoctest
julia> xmax(PWL(0:3, [0,1,0,1]))
3.0
```

See also
[`xmin`](@ref),
[`xspan`](@ref),
[`ymin`](@ref),
[`ymax`](@ref),
[`minimum`](@ref),
[`maximum`](@ref),
[`extrema`](@ref),
[`peak2peak`](@ref).
"""
xmax(s::AbstractSignal) = maximum(domain(s))
@signal_func xmax


"""
    minimum(signal)

Returns the minimum y-value of a signal.  Alias for [`ymin`](@ref).

# Examples

```jldoctest
julia> minimum(PWL(0:3, [0,1,-2,1]))
-2

julia> minimum(Series(0:3, [0,-11,-2,1]))
-11
```

See also
[`xmin`](@ref),
[`xmax`](@ref),
[`xspan`](@ref),
[`ymin`](@ref),
[`ymax`](@ref),
[`maximum`](@ref),
[`extrema`](@ref),
[`peak2peak`](@ref).
"""
Base.minimum(s::AbstractSignal; options...) = ymin(s; options...)
@signal_func Base.minimum

"""
    maximum(signal)

Returns the maximum y-value of a signal.  Alias for [`ymax`](@ref).

# Examples

```jldoctest
julia> maximum(PWL(0:3, [0,1,0,1]))
1

julia> maximum(Series(0:3, [0,1,0,1]))
1
```

See also
[`xmin`](@ref),
[`xmax`](@ref),
[`xspan`](@ref),
[`ymin`](@ref),
[`ymax`](@ref),
[`minimum`](@ref),
[`extrema`](@ref),
[`peak2peak`](@ref).
"""
Base.maximum(s::AbstractSignal; options...) = ymax(s; options...)
@signal_func Base.maximum

"""
    ymin(signal)

Returns the minimum y-value of a signal.  Alias of [`minimum`](@ref).

See also [`ymax`](@ref).

# Examples

```jldoctest
julia> ymin(PWL(0:3, [0,1,0,1]))
0.0
```

See also
[`xmin`](@ref),
[`xmax`](@ref),
[`xspan`](@ref),
[`ymax`](@ref),
[`minimum`](@ref),
[`maximum`](@ref),
[`extrema`](@ref),
[`peak2peak`](@ref).
"""
function ymin(s::RealSignal; name="ymin", trace::Bool=true, options...)
    y, x = find_min_itr(s, +)
    if trace
        YMeasure(s, x; name, options...)
    else
        y
    end
end
function ymin(s::ComplexSignal; name="ymin", trace::Bool=true, options...)
    error("cannot take ymin of a complex signal, maybe first take abs?")
end
@signal_func ymin

"""
    ymax(signal)

Returns the maximum y-value of a signal.  Alias of [`maximum`](@ref).

See also [`ymin`](@ref).

# Examples

```jldoctest
julia> ymax(PWL(0:3, [0,1,0,1]))
1
```

See also
[`xmin`](@ref),
[`xmax`](@ref),
[`xspan`](@ref),
[`ymin`](@ref),
[`minimum`](@ref),
[`maximum`](@ref),
[`extrema`](@ref),
[`peak2peak`](@ref).
"""
function ymax end
function ymax(s::RealSignal; name="ymax", trace::Bool=true, options...)
    y, x = find_min_itr(s, -)
    if trace
        YMeasure(s, x; name, options...)
    else
        y
    end
end
function ymax(s::ComplexSignal; name="ymax", trace::Bool=true, options...)
    error("cannot take ymax of a complex signal, maybe first take abs?")
end
@signal_func ymax

"""
    extrema(signal)

Same as `(ymin(sig), ymax(sig))`.  See also [`peak2peak`](@ref).

# Examples

```jldoctest
julia> extrema(PWL(0:3, [0,1,-1,1]))
(-1, 1)
```

See also
[`xmin`](@ref),
[`xmax`](@ref),
[`xspan`](@ref),
[`ymin`](@ref),
[`ymax`](@ref),
[`minimum`](@ref),
[`maximum`](@ref),
[`peak2peak`](@ref).
"""
Base.extrema(s::RealSignal; trace=true, kwargs...) = ymin(s; trace, kwargs...), ymax(s; trace, kwargs...)
function Base.extrema(s::ComplexSignal; options...)
    error("cannot take extrema of a complex signal, maybe first take abs?")
end
@signal_func Base.extrema

"""
    peak2peak(signal)

Same as `ymax(sig) - ymin(sig)`.  See also [`extrema`](@ref).

# Examples

```jldoctest
julia> peak2peak(PWL(0:3, [0,1,-1,1]))
2
```

See also
[`xmin`](@ref),
[`xmax`](@ref),
[`xspan`](@ref),
[`ymin`](@ref),
[`ymax`](@ref),
[`minimum`](@ref),
[`maximum`](@ref),
[`extrema`](@ref).
"""
function peak2peak(s::RealSignal; name="peak2peak", trace::Bool=true, options...)
    ymin, ymax = extrema(s; trace)
    if trace
        DyMeasure(ymin, ymax; name, options...)
    else
        ymax - ymin
    end
end
function peak2peak(s::ComplexSignal; options...)
    error("cannot take peak2peak of a complex signal, maybe first take abs?")
end
@signal_func peak2peak

"""
    xspan(signal)

Returns the domain of a signal: `xmax(s) - xmin(s)`.

# Examples

```jldoctest
julia> xspan(PWL(0:10, rand(11)))
10.0

julia> xspan(Series(-2:2, rand(5)))
4
```

See also
[`xmin`](@ref),
[`xmax`](@ref),
[`ymin`](@ref),
[`ymax`](@ref),
[`minimum`](@ref),
[`maximum`](@ref),
[`extrema`](@ref),
[`peak2peak`](@ref),
[`clip`](@ref).
"""
xspan(s::AbstractSignal) = xmax(s) - xmin(s) # DxMeasure(s, xmin(s), xmax(s), name="xspan")
xspan(interval::Interval) = last(interval) - first(interval)
@signal_func xspan


"""
    mean(signal)
Calculate the mean value of a signal.
For continuous signals the formula is:

```math
\\mathrm{mean}(s)=\\frac{1}{\\mathrm{xspan}(s)} \\int_{\\mathrm{xmin}(s)}^{\\mathrm{xmax}(s)} s(x)\\,\\mathrm{d}x
```

For discrete signals with `N` elements the formula is:

```math
\\mathrm{mean}(s) = \\frac{1}{N} \\sum_{n=\\mathrm{xmin}(s)}^{\\mathrm{xmax}(s)} s[n]
```

# Examples

```jldoctest
julia> mean(PWL(0:2, [0,12,0]))
6

julia> mean(Series(0:2, [0,12,0]))
4

julia> mean(PWL(0:2, [1,0,1])) ≈ 0.5
true

julia> mean(Series(0:2, [1,0,1])) == 2/3
true
```

See also
[`sum`](@ref),
[`integral`](@ref),
[`rms`](@ref),
[`std`](@ref).
"""
function mean end
function Statistics.mean(s::AbstractContinuousSignal; name="mean", trace::Bool=true, options...)
    y = integral(s; options...)/xspan(s)
    if trace
        YLevelMeasure(s, y; name, options...)
    else
        y
    end
end
function Statistics.mean(s::AbstractIterableSignal; name="mean", trace::Bool=true, options...)
    val = mean(eachy(s))
    if trace
        YLevelMeasure(s, val; name, options...)
    else
        val
    end
end
@signal_func mean

"""
    sum(discrete_signal)
Returns the sum of a discrete signal's y-values over its domain acccording to the formula:

```math
\\mathrm{sum}(s)=\\sum_{n=\\mathrm{xmin}(s)}^{\\mathrm{xmax}(s)} s[n]
```

# Examples

```jldoctest
julia> sum(eachy(Series(0:2, [0,12,0])))
12
```
See also
[`mean`](@ref),
[`integral`](@ref),
[`rms`](@ref),
[`std`](@ref).
"""
function Base.sum(s::AbstractIterableSignal)
    sum(eachy(s))
end
@signal_func Base.sum

"""
    std(signal; <keyword arguments>)
Returns the standard deviation of a signal.
For continuous signals the formula is:

```math
\\mathrm{std}(s) = \\sqrt{\\frac{1}{\\mathrm{xspan}(s)}\\int_{\\mathrm{xmin}(s)}^{\\mathrm{xmax}(s)} \\big(s(x) - \\mathrm{mean}(s)\\big)^2\\,\\mathrm{d}x}
```

for discrete signals:

```math
\\mathrm{std}(s) = \\sqrt{\\frac{1}{\\mathrm{xspan}(s)} \\sum_{n=\\mathrm{xmin}(s)}^{\\mathrm{xmax}(s)} \\big(s[n] - \\mathrm{mean}(s)\\big)^2}
```

# Arguments

- `mean`: the pre-computed mean of the signal (optional).
- `corrected`: if `true` (default) then it is scaled by `n-1`, otherwise by `n` (for discrete signals only).

# Examples

```jldoctest
julia> std(Series(0:2, [0, -1, 0])) == std([0, -1, 0])
true

julia> std(Series(0:2, [1, -2, 1]), corrected=false) == rms(Series(0:2, [1, -2, 1])) # std == rms when mean is zero
true

julia> std(PWL(0:1, [-1, 1])) ≈ 1/sqrt(3)
true
```

See also
[`sum`](@ref),
[`mean`](@ref),
[`rms`](@ref),
[`integral`](@ref).
"""
function std end
function Statistics.std(s::AbstractContinuousSignal; mean=nothing, options...)
    if isnothing(mean)
        mean = CedarWaves.mean(s; options...)
    end
    sqrt(integral((s - mean)^2; options...)/xspan(s))
end
function Statistics.std(s::AbstractIterableSignal; mean=nothing, options...)
    std(eachy(s); mean, options...)
end
@signal_func std


"""
    rms(signal; name="rms", options...)
Returns `sqrt(mean(signal^2))`, the root-mean-squared value of a signal.
The [`mean`](@ref) value changes depending on if the signal is discrete or continuous.

# Examples

```jldoctest
julia> rms(PWL(0:2, [-1,0,1])) ≈ 1/sqrt(3)
true

julia> rms(Series(0:2, [-1,0,1])) ≈ sqrt(2/3)
true
```

See also
[`sum`](@ref),
[`mean`](@ref),
[`std`](@ref),
[`integral`](@ref).
"""
function rms(s::AbstractSignal; name="rms", trace::Bool=true, options...)
    rmsval = sqrt(mean(s^2; trace=false, options...))
    if trace
        YLevelMeasure(s, rmsval; name, trace, options...)
    else
        rmsval
    end
end
@signal_func rms
