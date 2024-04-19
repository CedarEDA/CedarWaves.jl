using OffsetArrays
# Test to see if removing Xi and Yi from PWL type will slow things down

abstract type SignalKind end
abstract type ContinuousKind <: SignalKind end
struct PWLKind <: ContinuousKind end
abstract type AbstractSignal{SignalKind,Xi,Yi,X,Y} end
const AbstractPWL = AbstractSignal{PWLKind}
const UReal = Union{<:Real}

"Continuous piece-wise linear signal.  Aperiodic and finite extent."
struct PWL{SK<:PWLKind,Xi,Yi,X<:AbstractVector{Xi},Y<:AbstractVector{Yi}} <: AbstractSignal{SK,Xi,Yi,X,Y}
    "x-values vector"
    x::X
    "y-values vector"
    y::Y
    """
        PWL(xvals, yvals; starting_index=1)

    Create a continuous piece-wise linear signal.  Aperiodic and finite extent.
    """
    function PWL(x::AbstractVector, y::AbstractVector; starting_index::Int=1)
        if starting_index != 1
            N = length(x)
            idxs = starting_index:starting_index+N-1
            x = OffsetVector(x, idxs)
            y = OffsetVector(y, idxs)
        end
        new{PWLKind,eltype(x),eltype(y),typeof(x),typeof(y)}(x, y)
    end
end
function interpolate(::Type{T}, x, x1, y1, x2, y2) where T <: AbstractPWL
    θ = (x - x1)/ (x2 - x1)
    (1-θ)*y1 + θ*y2
end
function interpolate(s::AbstractPWL, x::UReal)
    check_in_range(s, x)
    idx = searchsortedlast(s.x, x)
    if s.x[idx] == x
        return s.y[idx] # no interpolation needed
    end
    x1 = s.x[idx]
    x2 = s.x[idx+1]
    y1 = s.y[idx]
    y2 = s.y[idx+1]
    if !(x1 <= x <= x2)
        error("interpolation bug: idx=$idx, x=$x, x1=$x1, x2=$x2, y1=$y1, y2=$y2")
    end
    interpolate(AbstractPWL, x, x1, y1, x2, y2)
end

"Integral of two x and y points"
function _integral(::Type{T}, x1, y1, x2, y2) where T <: AbstractPWL
    Δx = x2 - x1
    Σy = y1 + y2
    Δx*Σy/2
end
function integral(s::T) where T <: AbstractPWL
    # Get right type for integral
    area = zero(_integral(T, zero(eltype(s.x)), zero(eltype(s.y)), 
                               one(eltype(s.x)),  one(eltype(s.y))))  # not quite right for integers
    if length(s) < 2
        return area
    end
    (_, rest) = Iterators.peel(eachindex(s))
    for i in rest
        area += _integral(T, s.x[i-1], s.y[i-1], s.x[i], s.y[i])
    end
    return area
end

function Base.length(s::AbstractSignal) 
    length(s.x)
end
function Base.iterate(s::AbstractSignal)
    if length(s) < 1
        return nothing
    end
    idx = firstindex(s)
    firstval = (x=s.x[begin], y=s.y[begin])
    return (firstval, idx)
end
function Base.firstindex(s::AbstractSignal)
    firstindex(s.x)
end
function Base.lastindex(s::AbstractSignal)
    lastindex(s.x)
end
function Base.iterate(s::AbstractSignal, idx)
    idx += 1
    if idx < lastindex(s)
        nextval = (x=s.x[idx], y=s.y[idx])
        return (nextval, idx)
    elseif idx == lastindex(s)
        lastval = (x=s.x[idx], y=s.y[idx])
        return (lastval, idx)
    end
    return nothing
end

function interpolate(::Type{T}, x, x1, y1, x2, y2) where T <: AbstractPWL2
    θ = (x - x1)/ (x2 - x1)
    (1-θ)*y1 + θ*y2
end
function interpolate(s::AbstractPWL2, x::UReal)
    check_in_range(s, x)
    idx = searchsortedlast(s.x, x)
    if s.x[idx] == x
        return s.y[idx] # no interpolation needed
    end
    x1 = s.x[idx]
    x2 = s.x[idx+1]
    y1 = s.y[idx]
    y2 = s.y[idx+1]
    if !(x1 <= x <= x2)
        error("interpolation bug: idx=$idx, x=$x, x1=$x1, x2=$x2, y1=$y1, y2=$y2")
    end
    interpolate(AbstractPWL2, x, x1, y1, x2, y2)
end

"Integral of two x and y points"
function _integral(::Type{T}, x1, y1, x2, y2) where T <: AbstractPWL2
    Δx = x2 - x1
    Σy = y1 + y2
    Δx*Σy/2
end
function integral(s::T) where T <: AbstractPWL2
    # Get right type for integral
    area = zero(_integral(T, zero(eltype(s.x)), zero(eltype(s.y)), 
                               one(eltype(s.x)),  one(eltype(s.y))))  # not quite right for integers
    if length(s) < 2
        return area
    end
    (_, rest) = Iterators.peel(eachindex(s))
    for i in rest
        area += _integral(T, s.x[i-1], s.y[i-1], s.x[i], s.y[i])
    end
    return area
end

function Base.length(s::AbstractSignal2) 
    length(s.x)
end
function Base.iterate(s::AbstractSignal2)
    if length(s) < 1
        return nothing
    end
    idx = firstindex(s)
    firstval = (x=s.x[begin], y=s.y[begin])
    return (firstval, idx)
end
function Base.firstindex(s::AbstractSignal2)
    firstindex(s.x)
end
function Base.lastindex(s::AbstractSignal2)
    lastindex(s.x)
end
function Base.iterate(s::AbstractSignal2, idx)
    idx += 1
    if idx < lastindex(s)
        nextval = (x=s.x[idx], y=s.y[idx])
        return (nextval, idx)
    elseif idx == lastindex(s)
        lastval = (x=s.x[idx], y=s.y[idx])
        return (lastval, idx)
    end
    return nothing
end


using BenchmarkTools

function bench1(v::AbstractVector)
    z = zero(zero(eltype(v)))
    for vi in v
        z += vi
    end
    return z
end
function bench1(sig::T) where {T<:Union{<:AbstractSignal,<:AbstractSignal2}}
    z = zero(zero(eltype(sig.x))+zero(eltype(sig.y)))
    for (x, y) in sig
        z += x + y
    end
    return z
end

xs = 0:10^6
ys = rand(length(xs))
s1 = PWL(xs, ys)
s2 = PWL2(xs, ys)
bench1(s1)
@benchmark bench1($ys)
@benchmark bench1($s1)
@benchmark bench1($s2)