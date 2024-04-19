# Experiment for alternate PWL API/structure.
struct IdxVal{X<:Real,Y<:Number} <: Number
    x::X
    y::Y
end
struct PWL3{X<:AbstractVector,Y<:AbstractVector}
    x::X
    y::Y
end

s1 = PWL3(0:2, [1,-1,1])
Base.getindex(s::PWL3, idx::Int) = IdxVal(s.x[idx], s.y[idx])
Base.length(s::PWL3) = length(s.x)
Base.iterate(s::PWL3, state=1) = state > length(s) ? nothing : (s[state], state+1)
Base.eltype(s::PWL3) = IdxVal{eltype(s.x), eltype(s.y)}

Base.abs(v::IdxVal) = IdxVal(v.x, abs(v.y))
abs.(s1)

Base.isless(a::IdxVal, b::IdxVal) = isless(a.y, b.y)
maximum(s1)