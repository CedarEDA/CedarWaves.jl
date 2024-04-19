# Other math functions extended from Base. julia
"""
    clamp(signal, y_interval)

Restrict the y-values to be between the `y_interval`

# Examples
```jldoctest
julia> c = clamp(PWL([1, 10], [-10, 10]), -3 .. 3);

julia> c(4)
-3.0

julia> c(7)
3.0
```
"""
function Base.clamp(s::AbstractSignal, yinterval::Interval)
    from, to = first(yinterval), last(yinterval)
    ymap_signal(y->clamp(y, from, to), s)
end
@signal_func Base.clamp
