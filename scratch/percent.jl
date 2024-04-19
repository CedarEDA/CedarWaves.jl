if false
"""
    pct(value)

A value represented as a percentage.
This is often useful for defining [Thresholds](@ref).

# Examples

```jldoctest
julia> 10pct
10.0pct
julia> 10pct + pct(20)
30.0pct
julia> 10pct + 0.5
0.6
julia> 0.5*50pct
25.0pct
```
"""
struct pct <: AbstractFloat
    value::Float64
    function pct(value::Real)
        new(convert(Float64, value))
    end
end
Base.:*(value::Real, p::Type{<:pct}) = pct(value)
Base.:*(p::Type{<:pct}, value::Real) = pct(value)
Base.:*(value::Real, p::pct) = pct(value * p.value)
#Base.:*(p::pct, value::Real) = pct(value * p.value)
#Base.:*(p::pct, p2::pct) =  pct(p.value * p2 / 100)
Base.promote_rule(::Type{pct}, ::Type{T}) where {T<:Real} = Float64
Base.convert(::Type{Float64}, x::pct) = x.value/100

Base.:+(a::pct, b::pct) = pct(a.value + b.value)
Base.:-(a::pct, b::pct) = pct(a.value - b.value)
Base.:-(a::pct) = pct(-a.value)
Base.:/(a::pct, b::pct) = pct(a.value / b.value * 100)
Base.:^(a::pct, b::pct) = pct((a.value/100) ^ (b.value/100) * 100)
Base.:^(a::Type{<:pct}, b::pct) = (b.value/100)
Base.:^(a::Type{<:pct}, b::Real) = (b)
Base.:^(a::Real, b::pct) = pct((a ^ (b.value/100))*100)
Base.:^(a::pct, b::Real) = pct(((a.value/100) ^ (b))*100)
Base.:<(a::pct, b::pct) = a.value < b.value
Base.log10(a::pct) = log10(a.value/100)

Base.show(io::IO, p::pct) = print(io, p.value, "pct")

Base.hash(m::pct, h::UInt) = hash(m.value, h)
Base.:(==)(m1::pct, m2::pct) = m1.value == m2.value
end