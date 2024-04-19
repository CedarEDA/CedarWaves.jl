"""
    xflip(signal)
Flips a signal along the x-axis, so a signal whose domain is `a .. b` is
transformed to return the original signal's values along `b .. a`.

# Examples
```jldoctest
julia> s = PWL(1:2, [0, 1]);

julia> s2 = xflip(s);

julia> domain(s2)
[1.0 .. 2.0]

julia> s2.(1:2)
2-element Vector{Float64}:
 1.0
 0.0
```
"""
function xflip(s::AbstractSignal)
    offset = xmin(s) + xmax(s)
    xshift(xscale(s, -1), offset)
end
@signal_func xflip
