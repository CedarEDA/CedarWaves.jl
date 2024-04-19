"""
    eachcross(signal, thresholds; tol=nothing, trace=true, options...)
    crosses(...)
    cross(...)

Return a set of CrossMeasures where the signal crosses one of the thresholds.
If tolerance is not nothing, hysteresis is used to avoid spurious transitions.

# Variants
- `eachcross` returns an iterator of `CrossMeasure` objects if trace is true, crosses returns a vector, and cross the first element.
- `crosses` returns all crossings as a vector of `CrossMeasure` objects if trace is true, otherwise as a vector of numbers.
- `cross` returns the first crossing as a `CrossMeasure` object if trace is true, otherwise as a number.

# Examples

```jldoctest
julia> s = PWL(0:7, [0, 0, 0.5, 0.15, 1, 1, 0, 0]);

julia> crosses(s, [falling(0.5), rising(0.1), falling(0.9)])
3-element Vector{CrossMeasure}:
 1.2
 5.1
 5.5
```
"""
function eachcross(s::AbstractIterableSignal, thresholds::Vector{Threshold}; tol=nothing, trace=true, options...)
    thresholds = sort(thresholds)

    # Merge thresholds so that e.g., [rising(50), falling(50)] becomes [either(50)]
    for i=length(thresholds)-1:-1:1
        if thresholds[i + 1].value == thresholds[i].value
            if typeof(thresholds[i]) !== typeof(thresholds[i + 1])
                thresholds[i] = either(thresholds[i].value)
            end
            deleteat!(thresholds, i + 1)
        end
    end

    if tol!==nothing
        binned = hysteresis(mapregion(tolregions(thresholds, tol), s))
    else
        binned = mapregion(thresholds, s)
    end
    pairs = partition(binned, 2, 1)
    trans = Iterators.filter(pairs) do ((x1, y1, t1), (x2, y2, t2)) # FIXME: type unstable
            for th in thresholds[min(t1,t2):max(t1,t2)-1]
                if (th isa either ||
                   (t2 > t1 && th isa rising) ||
                   (t2 < t1 && th isa falling))
                    return true
                end
            end
            return false
        end
    crossings = Iterators.flatmap(function crossx(((x1, y1, t1), (x2, y2, t2)))
            if t2 > t1
                ts = rising.(filter(th -> (th isa rising || th isa either), thresholds[t1:t2-1]))
            else
                ts = falling.(filter(th -> (th isa falling || th isa either), thresholds[t1-1:-1:t2]))
            end
            map(ts) do t
                x = find_zero(s-float(t), (x1, x2))
                if trace
                    CrossMeasure(s, x, t; options...)
                else
                    x
                end
            end
        end, trans)
    cache(crossings)
end
@signal_func eachcross
function crosses(signal::AbstractIterableSignal, args...; kwargs...)
    collect(eachcross(signal, args...; kwargs...))
end
@doc (@doc eachcross) crosses
@signal_func crosses

function cross(signal::AbstractIterableSignal, args...; kwargs...)
    first(eachcross(signal, args...; kwargs...))
end
@doc (@doc eachcross) cross
@signal_func cross

Base.convert(::Type{Threshold}, x::Real) = either(x)
Base.convert(::Type{Threshold}, x::Threshold) = x

eachcross(s::AbstractIterableSignal, th; kwargs...) = eachcross(s, [th]; kwargs...)
eachcross(s::AbstractIterableSignal, thresholds::Vector; kwargs...) = eachcross(s, convert(Vector{Threshold}, thresholds); kwargs...)

"""
    mapregion(thresholds, s)

Maps the y-values of an iterable signal to a region between thresholds.
"""
mapregion(thresholds::Vector{<:Threshold}, s) = mapregion(float.(thresholds), s)
mapregion(thresholds::Vector{<:Real}, s) = Iterators.map(((x, y),) -> (x, y, searchsortedfirst(thresholds, y)), s)

"""
hysteresis(s)

An iterator that assigns intermediate regions to the last region.
If the signal starts on an intermediate region, that is returned
"""
function hysteresis(s)
    x = Iterators.accumulate(function((_, _, last_bin), (x, y, bin))
            if iseven(bin)
                bin = last_bin
            end
            (x, y, bin)
        end, s)
    Iterators.map(((x, y, bin),) -> (x, y, (bin+1)÷2), x)
end

"""
     tolregions(bins, tol=1e-9)

Generate extra regions for hysteresis.
"""
tolregions(bins::Vector{<:Threshold}, tol=1e-9) = tolregions(float.(bins), tol)
tolregions(bins::Vector{<:Real}, tol=1e-9) = collect(Iterators.flatmap(x -> (x-tol,x+tol), bins))


"""
    crosses(signal, yth; limit=Inf, trace=true, options...)
    crosses(signal; yth, limit=Inf, trace=true, options...)

Return all crosses of `yth` as a vector
of x-values, up to a limit of `limit` values.

See also [`cross`](@ref), [`eachcross`](@ref), [Thresholds](@ref), and [`pct`](@ref).

# Examples

To find the x-values for all the times the y-value crosses 0.5:
```jldoctest
julia> crosses(PWL(0:3, [0, 1, 0, 1]), 0.5)
3-element Vector{CrossMeasure}:
 0.5
 1.5
 2.5
```
"""
function crosses(s::AbstractIterableSignal, yth; trace::Bool=true, name="cross", limit=Inf, options...)
    if limit==Inf
        collect(eachcross(s, yth; trace, name, options...))
    else
        collect(Iterators.take(eachcross(s, yth; trace, name, options...), limit))
    end
end

function crosses(s::AbstractIterableSignal; yth, trace::Bool=true, name="cross", options...)
    crosses(s, yth; trace, name, options...)
end

struct MissingCrossError <: Exception
    msg::String
end
function Base.showerror(io::IO, ex::MissingCrossError)
    print(io, "MissingCrossError: ")
    print(io, ex.msg)
end

"""
    cross(s, yth; N=1, options...)
Returns the Nth crossing (x-value) of a signal.
"""
function cross(s::AbstractIterableSignal, yth; N=1, trace::Bool=true, name="cross", options...)
    cr = eachcross(s, yth; trace, name, options...)
    if N<0
        # reversing signals is annoying, but this is potentially slow
        cr = crosses(s, yth; trace, name, options...)
        N = length(cr) + N + 1
    end
    for (nth, x) in Iterators.enumerate(cr)
        if nth == N
            return x
        end
    end
    #throw(MissingCrossError("could not find crossing $N with yth=$yth"))
    xbad = xtype(s)(NaN)
    trace ? CrossMeasure(s, xbad, yth; name, options...) : xbad
end


"""
    clipcrosses(signal, yth; options...)
Clip a signal to the first and last crossing of `yth`.
"""
function clipcrosses(s::AbstractIterableSignal, yth; options...)
    xes = crosses(s, yth; options...)
    clip(s, first(xes)..last(xes))
end
@signal_func clipcrosses
