abstract type AbstractInterval{T} end

# TODO, allow to specify this like Intervals.jl (should not be a type parameter)
"""
    Interval(start, stop)
Defines an interval from the `start`` to `stop`` value.
Can also be written as `start .. stop` to create an Interval.

### Examples

```@jldocest
julia> a = 1 .. 3
[1 .. 3]

julia> first(a) == 1
true

julia> last(a) == 3
true

julia> 1.2 in a
true

julia> 10 in a
false
```
"""
struct Interval{T} <: AbstractInterval{T}
    l::T
    r::T
end
function Interval(a, b)
    T = promote_type(eltype(a), eltype(b))
    Interval{T}(T(a), T(b))
end
Base.eltype(::AbstractInterval{T}) where {T} = T

empty_interval(::Type{T}) where{T} = Interval{T}(zero(T), zero(T))
empty_interval(i::Interval{T}) where{T} = empty_interval(T)


Base.show(io::IO, i::Interval) = print(io, "[", first(i), " .. ", last(i), "]")

..(a, b) = Interval(promote(a, b)...)

Base.first(i::Interval) = i.l
Base.last(i::Interval) = i.r
Base.Tuple(i::Interval) = (i.l, i.r)

Base.maximum(i::Interval) = max(i.l, i.r)
Base.minimum(i::Interval) = min(i.l, i.r)

Base.:+(a::Interval, b::Number) = Interval(a.l + b, a.r + b)
Base.:-(a::Interval) = Interval(-a.r, -a.l)
Base.:+(a::Interval) = a
Base.:*(a::Interval, b::Number) = b >= 0 ? Interval(a.l * b, a.r * b) : Interval(a.r * b, a.l * b)

Base.:+(a::Number, b::Interval) = b + a
Base.:-(a::Interval, b::Number) = a + -b
Base.:-(a::Number, b::Interval) = a + -b
Base.:*(a::Number, b::Interval) = b * a

Base.float(i::Interval) = Interval(float(i.l), float(i.r))
Base.in(x::Number, i::Interval) = minimum(i) ≤ x ≤ maximum(i)
in_closedopen(x::Number, i::Interval) = i.l <= x < i.r
span(i::Interval) = i.r - i.l
descending(i::Interval) = i.r < i.l

function overlaps(i₁::Interval, i₂::Interval)
    l = max(i₁.l, i₂.l)
    r = min(i₁.r, i₂.r)
    return l <= r
end

function Base.intersect(i₁::Interval{T}, i₂::Interval{S}) where {T, S}
    TS = promote_type(T, S)
    overlaps(i₁, i₂) || return empty_interval(TS)
    l = max(i₁.l, i₂.l)
    r = min(i₁.r, i₂.r)
    return Interval{TS}(l, r)
end

function Base.union(i₁::Interval{T}, i₂::Interval{S}) where {T, S}
    TS = promote_type(T, S)
    overlaps(i₁, i₂) || @warn "Union of $i₁ and $i₂ is not contiguous"
    l = min(i₁.l, i₂.l)
    r = max(i₁.r, i₂.r)
    return Interval{TS}(l, r)
end


Base.issubset(a::Interval, b::Interval) = a.l ≥ b.l && a.r ≤ b.r
Base.isempty(a::Interval) = a.l >= a.r
Base.:(==)(a::Interval, b::Interval) = a.l == b.l && a.r == b.r