
"""
    dutycycle(signal, yth)
Returns the duty cycle of `signal` with a threshold `yth`,
in other words, the percentage of time `signal` is above `yth`.

```jldoctest
julia> tri = PWL(1:3, [-1, 1, -1]);

julia> dutycycle(tri, 0)
0.5

julia> dutycycle(tri, 0.5)
0.25

julia> dutycycle(tri, -0.5)
0.75
```
"""
function dutycycle(s::AbstractSignal, yth, tol=nothing)
    xs = eachcross(s, [yth]; tol)
    high = 0.0
    prevx = xmin(s)
    for m in xs
        span = m.x - prevx
        if !(m.yth isa rising)
            high += span
        end
        prevx = m.x
    end
    x = xmax(s)
    span = x - prevx
    if s(x) > yth
        high += span
    end
    high/xspan(s)
end
@signal_func dutycycle

"""
    dutycycles(signal, yth, window)
Computes `dutycycle` over a sliding window.


```jldoctest
julia> t = PWL(0:0.001:1, 0:0.001:1);

julia> s = (sinpi(100*t)+sinpi(4*t));

julia> extrema(dutycycles(s, 0, 0.1))
(0.10256, 0.89744)
```
See also
[`dutycycle`](@ref),
[`iirfilter`](@ref).
[`firfilter`](@ref).
"""
function dutycycles(s::AbstractContinuousSignal, yth, window)
    zp = zeropad(s, (xmin(s)-window/2)..(xmax(s)+window/2))
    f(x) = dutycycle(clip(zp, (x-window/2)..(x+window/2)), yth)
    similar(s; f)
end
@signal_func dutycycles
