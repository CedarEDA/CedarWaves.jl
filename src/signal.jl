"""
    AbstractSignal{X, Y}
A signal base class with element types X and Y"
"""
abstract type AbstractSignal{X, Y} end
"A signal with samples that can be iterated over with element types X and Y"
abstract type AbstractIterableSignal{X, Y} <: AbstractSignal{X, Y} end
"A signal backed by an array of samples with element types X and Y"
abstract type AbstractArraySignal{X, Y} <: AbstractIterableSignal{X, Y} end
"A signal that has a value at every point within its domain with element types X and Y"
abstract type AbstractContinuousSignal{X, Y} <: AbstractArraySignal{X, Y} end

const RealSignal = AbstractSignal{<:Real, <:Real}
const ComplexSignal = AbstractSignal{<:Real, <:Complex}

struct OnlineSignal{X, Y} <: AbstractIterableSignal{X, Y}
    ch::Channel{Tuple{X, Y}}
end

struct ArraySignal{X, Y, VX <: AbstractVector{X}, VY <: AbstractVector{Y}} <: AbstractArraySignal{X, Y}
    x::VX
    y::VY
    function ArraySignal(x::VX, y::VY) where {VX<:AbstractVector, VY<:AbstractVector}
        check_x_y(x, y)
        new{eltype(VX), eltype(VY), VX, VY}(x, y)
    end
end

"""
    ArraySignal(xs, ys)
Constructs a discrete signal from two vectors of x and y values.
A discrete signal has no interpolation.
If the x-value is between sample points then the last sample point is used:

# Examples
```jldoctest
julia> s = ArraySignal(0:3, [-1, 0.5, 0.5, -1]);

julia> s[1]
(x = 0, y = -1.0)

julia> s[2]
(x = 1, y = 0.5)

julia> s(0.1) # the x-value is snapped to the next x-value to the right
0.5
"""
function ArraySignal end
function ArraySignal(x::AbstractVector, s::AbstractSignal)
    vx = collect(x)
    vy = s.(vx)
    ArraySignal(vx, vy)
end
@inline function (s::AbstractArraySignal)(x::Real)
    idxs = searchsorted(xvals(s), x)
    if first(idxs) > lastindex(s.x) || last(idxs) < firstindex(s.x)
        throw(DomainError(x, "$x is not in the domain of the signal: $(domain(s))"))
    end
    yvals(s)[first(idxs)]
end

struct ContinuousSignal{X, Y, VX <: AbstractVector{X}} <: AbstractContinuousSignal{X, Y}
    x::VX
    f::FunctionWrapper{Y, Tuple{X}}
end

"""
    ContinuousSignal(xs, ys; interp)
    ContinuousSignal(xs, func)
Construct a continuous signal that is sampled at `xs`.
The first form takes the `ys` and an interpolation function that takes the
`xs` and `ys` and returns a function to interpolate at a given `x` value.
The second form takes the sampled x-values (`xs`) and a function (`func`) that returns
the corresponding y-values.

# Examples
```jldoctest
julia> s = ContinuousSignal(0:3, x->x^2);

julia> s.(0:0.5:3)
7-element Vector{Float64}:
 0.0
 0.25
 1.0
 2.25
 4.0
 6.25
 9.0
"""
function ContinuousSignal end
function ContinuousSignal(x::AbstractVector, func)
    X = typeof(float(first(x)))
    if eltype(x) != X
        x = X.(x)
    end
    Y = typeof(float(func(first(x))))
    ContinuousSignal{X, Y, typeof(x)}(x, func)
end

function ContinuousSignal(x::VX, y::VY; interp=DataInterpolations.AkimaInterpolation) where {VX <: AbstractVector, VY <: AbstractVector}
    check_x_y(x, y)
    X = eltype(x)
    Y = eltype(y)
    f = interp(y, x)
    ContinuousSignal{X, Y, VX}(x, f)
end

struct ArrayContinuousSignal{X, Y, VX <: AbstractVector{X}, VY <: AbstractVector{Y}} <: AbstractContinuousSignal{X, Y}
    x::VX
    y::VY
    f::FunctionWrapper{Y, Tuple{X}}
    function ArrayContinuousSignal(x::VX, y::VY, f=DataInterpolations.AkimaInterpolation(y, x)) where {X, Y, VX<:AbstractVector{X}, VY<:AbstractVector{Y}}
        check_x_y(x, y)
        new{X, Y, VX, VY}(x, y, f)
    end
end

function checkdomain(s::AbstractSignal, x)
    if x ∉ domain(s)
        throw(DomainError(x, "$x is not in the domain of the signal: $(domain(s))"))
    end
end

@inline function (s::ContinuousSignal{X})(x::X) where {X<:Real}
    isnan(x) && return NaN
    @boundscheck(checkdomain(s, x))
    s.f(x)
end

# fallback for dual numbers
function (s::ContinuousSignal)(x::Real)
    isnan(x) && return NaN
    @boundscheck(checkdomain(s, x))
    s.f.obj[](x)
end

struct FiniteFunction{X, Y} <: AbstractSignal{X, Y}
    domain::Interval{X}
    f::FunctionWrapper{Y, Tuple{X}}
    function FiniteFunction{X,Y}(domain::Interval, f) where {X,Y}
        x1 = X(first(domain))
        x2 = X(last(domain))
        Y2 = typeof(f(x1))
        @assert Y == Y2 "provided Y type `$(Y)` does not match function return type `$(Y2)`"
        d = x1 .. x2
        new{X, Y}(d, f)
    end
end

"""
    FiniteFuntion(domain::Interval, func)
Constructs a signal that is defined by a pure function over the given domain with
element types X and Y.  The input to the function must be a single parameter
function of type X and the output is a single value of type Y.

# Examples
```jldoctest
julia> FiniteFunction{Float64, Float64}(0 .. 1, x -> x^2)
Unable to show signals of type FiniteFunction{Float64, Float64}

julia> FiniteFunction(0 .. 1, sinpi)
Unable to show signals of type FiniteFunction{Float64, Float64}


```
"""
function FiniteFunction end
function FiniteFunction(domain::Interval, f)
    x1 = float(first(domain))
    x2 = float(last(domain))
    X = typeof(x1)
    Y = typeof(f(x1))
    d = x1 .. x2
    FiniteFunction{X, Y}(d, f)
end
(s::FiniteFunction)(x) = s.f(x) # FIXME: check in domain?

struct InfiniteFunction{X, Y} <: AbstractSignal{X, Y}
    f::FunctionWrapper{Y, Tuple{X}}
end
"""
    InfiniteFunction{X,Y}(func)
Constructs a signal that is defined by a pure function over the entire real number line.
The `X` and `Y` types are the element types of the input and output of the function (`func`).

# Examples
```jldoctest
julia> sindegrees = InfiniteFunction{Float64, Float64}(sind);

julia> sindegrees(90)
1.0
```
"""
function InfiniteFunction end
function InfiniteFunction(func)
    InfiniteFunction{Float64, Float64}(func)
end
(s::InfiniteFunction)(x) = s.f(x)
function clip(s::InfiniteFunction{X, Y}, interval::Interval) where {X, Y}
    d = X(first(interval)) .. X(last(interval))
    FiniteFunction{X, Y}(d, s.f)
end

struct InfiniteSeries{X, Y} <: AbstractSignal{X, Y}
    dx::X
    y::FunctionWrapper{Y, Tuple{X}}
end

domain(s::InfiniteFunction) = -Inf .. Inf

"""
    InfiniteSeries{X, Y}(dx, func)
Constructs a signal that is discrete and has an infinite number of points
of the same step size and crosses the zero point.
The `X` and `Y` parametric types are the element types of the input and output of the function (`func`).

# Examples

```jldoctest
julia> s = InfiniteSeries{Float64,Float64}(0.1, x -> x^2);

julia> s.(-1:3)
5-element Vector{Float64}:
 1.0
 0.0
 1.0
 4.0
 9.0
```
"""
function InfiniteSeries end
(s::InfiniteSeries)(x) = s.y(x)

function clip(s::InfiniteSeries{X, Y}, interval::Interval) where {X, Y}
    x = interval_to_grid_range(interval, s.dx)
    y = s.y.(x)
    ArraySignal(x, y)
end

"""
    sample(signal, xvalues)
    sample(signal, xstep)
    sample(signal; length=Npts)
    sample(signal; step=xstep)
    sample(xstep)
Resamples a signal to the specified values. Typically used for signals that are pure functions (not sampled) as
functions like `ymax` and `ymin` only look at the sample points as they assume the signal is densely sampled.
If the x values are a vector (`xvalues`) then the signal is resampled at those points.
If the value is a scalar (`xstep`) then the signal is reampled at a linear range over the domain of the signal at that step size.
If only the `xstep` is provided then a function is returned that can be used to resample any signal.

# Examples

```jldoctest
julia> s = SIN(amp=2, freq=1)
Unable to show signals of type InfiniteFunction{Float64, Float64}

julia> s(0.25)
2.0

julia> s(0.75)
-2.0

julia> s2 = sample(s, 0:0.5:1);

julia> ymax(s2) # ymax only looks at samples
0.0

julia> s3 = sample(s, 0:0.25:1);

julia> ymax(s3)
2
```

# Extended Help

Sampling a sampled signal does not change the shape as the signal is already sampled at those points.

```jldoctest
julia> s = PWL(0:3, [0, 0, 1, 0]);

julia> s2 = sample(s, 1.5:2.5);

julia> s2[1]
(x = 1.5, y = 0.5)

julia> s(2) == s2(2)
true
```
"""
function sample end
sample(s::InfiniteFunction{X, Y}, x::AbstractVector{X}) where {X, Y} = ContinuousSignal{X, Y, typeof(x)}(x, s.f)
sample(s::InfiniteFunction{X, Y}, x::AbstractVector) where {X, Y} = ContinuousSignal{X, Y, typeof(x)}(X.(x), s.f)
sample(s::InfiniteFunction{X, Y}; range_kwargs...) where {X, Y} = (xs = range(first(domain(s)), last(domain(s)); range_kwargs...); ContinuousSignal{X, Y, typeof(xs)}(xs, s.f))
sample(s::InfiniteFunction, step::Real) = sample(s, step=step)

sample(s::FiniteFunction{X, Y}, x::AbstractVector{X}) where {X, Y} = ContinuousSignal{X, Y, typeof(x)}(x, s.f)
sample(s::FiniteFunction{X, Y}, x::AbstractVector) where {X, Y} = (x2 = X.(x); ContinuousSignal{X, Y, typeof(x2)}(x2, s.f))
sample(s::FiniteFunction{X, Y}; range_kwargs...) where {X, Y} = (xs=range(first(domain(s)), last(domain(s)); range_kwargs...); ContinuousSignal{X, Y, typeof(xs)}(xs, s.f))
sample(s::FiniteFunction, step::Real) = sample(s; step)

function sample(s::AbstractContinuousSignal, x::AbstractVector)
    Xs = xtype(s)
    Xx = eltype(s)
    if Xs != Xx
        x = Xs.(x)
    end
    similar(s; x)
end
sample(s::AbstractContinuousSignal, step::Real) = sample(s; step)
sample(s::AbstractContinuousSignal; range_kwargs...) = similar(s; x=range(first(domain(s)), last(domain(s)); range_kwargs...))

sample(step::Real) = signal -> sample(signal, step)
@signal_func sample


# signal creation utilities

function Base.:∘(f, g::ContinuousSignal)
    cp=ComposedFunction(f, g.f)
    ContinuousSignal(g.x, cp)
end

Base.similar(s::ArraySignal; x=s.x, y=s.y) = ArraySignal(x, y)
Base.similar(s::ContinuousSignal; x=s.x, f=s.f) = ContinuousSignal(x, f)
# doesn't support changes
Base.similar(s::ArrayContinuousSignal; x=s.x, f=s.f) = ContinuousSignal(x, f)

# iteration interface
Base.eltype(::AbstractSignal{X, Y}) where {X, Y} = Tuple{X, Y}

Base.iterate(s::OnlineSignal) = iterate(s.ch)
Base.iterate(s::OnlineSignal, state) = iterate(s.ch, state)
Base.IteratorSize(::OnlineSignal) = Base.SizeUnknown()

Base.iterate(s::ArraySignal) = iterate(zip(s.x, s.y))
Base.iterate(s::ArraySignal, state) = iterate(zip(s.x, s.y), state)
Base.length(s::ArraySignal) = length(s.x)

Base.iterate(s::ContinuousSignal) = iterate(zip(s.x, Iterators.map(s, s.x)))
Base.iterate(s::ContinuousSignal, state) = iterate(zip(s.x, Iterators.map(s, s.x)), state)
Base.length(s::ContinuousSignal) = length(s.x)

Base.iterate(s::ArrayContinuousSignal) = iterate(zip(s.x, s.y))
Base.iterate(s::ArrayContinuousSignal, state) = iterate(zip(s.x, s.y), state)
Base.length(s::ArrayContinuousSignal) = length(s.x)


#### Indexing
function Base.getindex(s::AbstractArraySignal, idx::Int)
    x = xvals(s)[idx]
    y = yvals(s)[idx]
    (; x, y)
end
function Base.getindex(s::AbstractArraySignal, idxs)
    x = xvals(s)[idxs]
    y = yvals(s)[idxs]
    similar(s; x, y)
end
function Base.getindex(s::AbstractContinuousSignal, idx::Int)
    x = xvals(s)[idx]
    y = yvals(s)[idx]
    (; x, y)
end
function Base.getindex(s::AbstractContinuousSignal, idxs)
    x = xvals(s)[idxs]
    similar(s; x)
end

Base.firstindex(s::AbstractArraySignal) = firstindex(xvals(s))
Base.lastindex(s::AbstractArraySignal) = lastindex(xvals(s))

# transformations

struct Scale{N}
    scale::N
end
(scale::Scale)(x) = x*scale.scale

struct Shift{N}
    shift::N
end
(shift::Shift)(x) = x+shift.shift

# axes

struct TransformedAxis{X, VX <: Tuple{Vararg{AbstractVector}}, F <: FunctionWrapper} <: AbstractVector{X}
    transform::F
    inner::VX
end
function TransformedAxis(f, axes...)
    et = eltype.(axes)
    X = typeof(f(first.(axes)...))
    fw = FunctionWrapper{X, Tuple{et...}}
    TransformedAxis{X, typeof(axes), fw}(f, axes)
end
Base.size(a::TransformedAxis) = size(first(a.inner))
Base.getindex(a::TransformedAxis, i::Int) = a.transform(getindex.(a.inner, i)...)

"""
    EndPointAxis(inner_xs, first_x, last_x)
An x-axis that has endpoints that may not included in the inner axis.
This is used for clipping a signal to points that are not in the original signal.
"""
struct EndpointAxis{X, VX <: AbstractVector{X}} <: AbstractVector{X}
    "The base x-axis sample points (vector)"
    inner::VX
    "The first x-value (or nothing if it is the first inner value)"
    first::Union{Nothing, X}
    "The last x-value (or nothing if it is the last inner value)"
    last::Union{Nothing, X}
    function CedarWaves.EndpointAxis(inner::VX, first::X, last::X) where {X, VX<:AbstractVector{X}}
        fv = !isempty(inner) && inner[begin] == first ? nothing : first
        lv = !isempty(inner) && inner[end] == last ? nothing : last
        new{X, VX}(inner, fv, lv)
    end
end
function Base.size(a::EndpointAxis)
    len = length(a.inner)
    if a.first !== nothing
        len += 1
    end
    if a.last !== nothing
        len += 1
    end
    (len,)
end
function Base.getindex(a::EndpointAxis, i::Int)
    if i == 1 && a.first !== nothing
        a.first
    elseif i == length(a) && a.last !== nothing
        a.last
    else
        getindex(a.inner, i-(a.first !== nothing))
    end
end


"""
    isdiscrete(signal)
Returns true if a signal has a discrete (not continuous) domain.

# Examples

```jldoctest
julia> isdiscrete(PWL(0:1, 0:1))
false

julia> isdiscrete(PWC(0:1, 0:1))
false

julia> isdiscrete(Series(0:1, 0:1))
true
```

See also
[`iscontinuous`](@ref),
[`issampled`](@ref),
"""
function isdiscrete end
isdiscrete(s::AbstractContinuousSignal) = false
isdiscrete(s::AbstractSignal) = true
@signal_func isdiscrete

"""
    iscontinuous(signal)
Returns true if a signal has a continuous (not discrete) domain.

# Examples

```jldoctest
julia> iscontinuous(PWL(0:1, 0:1))
true

julia> iscontinuous(PWC(0:1, 0:1))
true

julia> iscontinuous(Series(0:1, 0:1))
false
```

See also
[`isdiscrete`](@ref),
[`signal_kind`](@ref).
"""
function iscontinuous end
iscontinuous(s::AbstractSignal) = false
iscontinuous(s::AbstractContinuousSignal) = true
iscontinuous(s::FiniteFunction) = true
iscontinuous(s::InfiniteFunction) = true
@signal_func iscontinuous

eachxy(s::AbstractSignal) = zip(eachx(s), eachy(s))
@signal_func eachxy

"""
    eachx(signal; [dx, maxdx])
Returns an iterator over the sampled x-values of a signal (continuous or discrete).
Or the x values spaces at `dx` intervals or at most `maxdx` step size.

!!! tip
    If you want a vector for indexing operations use `collect(eachx(s))` or `xvals(s)` --
    although this is much less memory efficient in most cases.

# Examples

```jldoctest
julia> s = PWL([0, 0.2e-9, 0.8e-9, 1.0e-9], [0, 1, 1, 0]);

julia> s2 = xscale(s, 1e9);  # convert to ns

julia> xs = collect(eachx(s2))
4-element Vector{Float64}:
 0.0
 0.2
 0.8
 1.0
```

See also
[`eachy`](@ref),
[`eachxy`](@ref),
[`xvals`](@ref),
[`yvals`](@ref),
[`collect`](https://docs.julialang.org/en/v1/base/collections/#Base.collect-Tuple{Any}).
"""
eachx(s::AbstractIterableSignal) = Iterators.map(xy->xy[1], s)
eachx(s::ArraySignal) = s.x
eachx(s::ContinuousSignal) = s.x
eachx(s::ArrayContinuousSignal) = s.x
@signal_func eachx

"""
    xvals(signal, [dx, maxdx])
Returns an vector of the sampled x-values of a signal (continuous or discrete).
Or the x values spaces at `dx` intervals (or `maxdx` step size).

!!! tip
    If the full vector isn't needed in the end it may be faster to iterate
    over the x-values one-by-one with [`eachx`](@ref).

# Examples

```jldoctest
julia> s = PWL(1e-9 * [0, 0.05, 0.95, 1.0], [0, 1, 1, 0]);

julia> s2 = xscale(s, 1e9);  # convert to ns

julia> xs = round.(xvals(s2), sigdigits=3)
4-element Vector{Float64}:
 0.0
 0.05
 0.95
 1.0
```

See also
[`eachx`](@ref),
[`eachy`](@ref),
[`eachxy`](@ref),
[`yvals`](@ref),
[`collect`](https://docs.julialang.org/en/v1/base/collections/#Base.collect-Tuple{Any}).
"""
xvals(s::AbstractIterableSignal) = collect(eachx(s))
xvals(s::ArraySignal) = s.x
xvals(s::ContinuousSignal) = s.x
xvals(s::ArrayContinuousSignal) = s.x
@signal_func xvals

"""
    eachy(signal, [dx, maxdx])
Returns an iterator over the sampled y-values of a signal (continuous or discrete).
Or the y values sampled at `dx` intervals (or at most `maxdx` step size).

!!! tip
    If you want a vector for indexing operations use `collect(eachy(s))` or `yvals(s)` --
    although this is much less memory efficient in most cases.

# Examples

```jldoctest
julia> s = PWL(1e-9 * [0, 0.05, 0.95, 1.0], [0, 1, 1, 0]);

julia> ys = collect(eachy(s))
4-element Vector{Float64}:
 0.0
 1.0
 1.0
 0.0
```

See also
[`eachx`](@ref),
[`eachxy`](@ref),
[`xvals`](@ref),
[`yvals`](@ref),
[`collect`](https://docs.julialang.org/en/v1/base/collections/#Base.collect-Tuple{Any}).
"""
eachy(s::AbstractIterableSignal) = Iterators.map(xy->xy[2], s)
eachy(s::ArraySignal) = s.y
eachy(s::ContinuousSignal) = Iterators.map(s.f, s.x)
eachy(s::ArrayContinuousSignal) = s.y
@signal_func eachy

"""
    yvals(signal, [dx, maxdx])
Returns an vector of the sampled y-values of a signal (continuous or discrete).
Or the y values sampled at `dx` intervals (or at most `maxdx` step size).

!!! tip
    If the full vector isn't needed in the end it may be faster to iterate
    over the y-values one-by-one with [`eachy`](@ref).

# Examples

```jldoctest
julia> s = PWL(1e-9 * [0, 0.05, 0.95, 1.0], [0, 1, 1, 0]);

julia> ys = yvals(s)
4-element Vector{Float64}:
 0.0
 1.0
 1.0
 0.0
```

See also
[`eachx`](@ref),
[`eachy`](@ref),
[`eachxy`](@ref),
[`xvals`](@ref),
[`collect`](https://docs.julialang.org/en/v1/base/collections/#Base.collect-Tuple{Any}).
"""
yvals(s::AbstractIterableSignal) = collect(eachy(s))
yvals(s::ArraySignal) = s.y
yvals(s::ContinuousSignal) = s.f.(s.x)
yvals(s::ArrayContinuousSignal) = s.y
@signal_func yvals

"""
    xtype(signal)
Returns the type of the x-values element type.

# Examples

```jldoctest
julia> dig = PWC(0:3, [false, true, true, false]);

julia> xtype(dig)
Int64
```

Note the `xtype` for a continuous signal is a Float64 (not an Int64).
"""
xtype(::AbstractSignal{X, Y}) where {X, Y} = X
@signal_func xtype

"""
    ytype(signal)
Returns the type of the y-values element type.

# Examples

```jldoctest
julia> dig = PWC(0:3, [false, true, true, false]);

julia> ytype(dig)
Bool
```

Note the `xtype` for a continuous signal is a Float64 (not an Int64).
"""
ytype(::AbstractSignal{X, Y}) where {X, Y} = Y
@signal_func ytype

function samex(xs...)
    if !allequal(xs)
        throw(ArgumentError("Signals don't have the same X axis, use `sample(s1, xvals(s2))` to resample to same values"))
    end
    return first(xs)
end

# Merge unique items from two sorted arrays
# within the range of items covered by both arrays
function mergex(a1, a2)
    i1 = searchsortedfirst(a1, a2[begin])
    i2 = searchsortedfirst(a2, a1[begin])
    res = promote_type(eltype(a1), eltype(a2))[]
    (i1 > length(a1) || i2 > length(a2)) && throw(DomainError("No overlap in x-values"))
    while true
        x1 = a1[i1]
        x2 = a2[i2]
        if x1 == x2
            push!(res, x1)
            i1 += 1
            i2 += 1
        elseif x1 < x2
            push!(res, x1)
            i1 += 1
        else
            push!(res, x2)
            i2 += 1
        end
        if i1 > length(a1) || i2 > length(a2)
            break
        end
    end
    return res
end


"""
    ymap_signal(func, signal...)
Creates a new signal by applying the function `func` to each
y-value of `signal`.
The `func` takes one or more y-value and returns a modified y-value.

```jldoctest
julia> double(s::AbstractContinuousSignal) = ymap_signal(y->2y, s)
double (generic function with 1 method)

julia> s = double(PWL(0:1, 1:2));

julia> s(0.5)
3.0
```
"""
function ymap_signal(func, signals::Vararg{AbstractContinuousSignal}; method=samex)
    xs = method(map(xvals, signals)...)
    cp = x -> func((s(x) for s in signals)...)
    ContinuousSignal(xs, cp)
end
function ymap_signal(func, ss::Vararg{AbstractArraySignal})
    if !allequal(xvals.(ss))
        throw(ArgumentError("Signals don't have the same X axis, please resample them"))
    end
    y = TransformedAxis(func, yvals.(ss)...)
    ArraySignal(xvals(first(ss)), y)
end
function ymap_signal(func, ss::Vararg{FF}) where FF<:FiniteFunction
    if !allequal(domain.(ss))
        throw(ArgumentError("Signals don't have the same domain"))
    end
    cp=x->func((s(x) for s in ss)...)
    FF(domain(first(ss)), cp)
end
function ymap_signal(func, ss::Vararg{IF}) where IF<:InfiniteFunction
    cp=x->func((s(x) for s in ss)...)
    IF(cp)
end

combine(f, ss::Vararg{AbstractContinuousSignal}) = ymap_signal(f, ss...; method=mergex)

"""
    xshift(signal, value)

Returns a new signal with the x-axis of `signal` shifted by `value`.
Positive is a right shift while negative shifts left.

```jldoctest
julia> s1 = xshift(PWL(0:2, [1,2,3]), 3);

julia> s1(3)
1.0

julia> s1(5)
3.0
```
"""
function xshift(s::AbstractArraySignal, offset)
    x = TransformedAxis(Shift(offset), xvals(s))
    similar(s; x)
end
function xshift(s::AbstractContinuousSignal, offset)
    x = TransformedAxis(Shift(offset), xvals(s))
    f = s ∘ Shift(-offset)
    similar(s; x, f)
end
function xshift(s::FF, offset) where {FF <: FiniteFunction}
    f = s ∘ Shift(-offset)
    FF(s.domain+offset, f)
end
@signal_func xshift

"""
    xscale(signal, value)

Returns a new signal with the x-axis of `signal` scaled by `value`.
See also [`xshift`](@ref).

```jldoctest
julia> s1 = PWL([0, 1e-9, 2e-9], [1,2,3]);

julia> s1(0.5e-9)
1.5

julia> s2 = xscale(s1, 1e9); # to ns

julia> s2(0.5) # in ns
1.5
```
"""
function xscale(s::AbstractArraySignal, scale)
    x = TransformedAxis(Scale(scale), xvals(s))
    similar(s; x)
end
function xscale(s::AbstractContinuousSignal, scale)
    if scale == 0
        throw(DomainError("Can't scale x-axis by 0"))
    end
    if scale < 0
        x = TransformedAxis(Scale(scale), reverse(xvals(s)))
        f = s ∘ Scale(1/scale)
    else
        x = TransformedAxis(Scale(scale), xvals(s))
        f = s ∘ Scale(1/scale)
    end
    similar(s; x, f)
end
function xscale(s::FF, scale) where {FF <: FiniteFunction}
    f = s ∘ Scale(1/scale)
    FF(s.domain*scale, f)
end
@signal_func xscale

"""
    domain(signal)
Returns the domain of a signal. This can be used to check if an x-value is a
between the min and max x-values of asignal. Otherwise a DomainError will be thrown.
For discrete signals
it only checks that

```jldoctest
julia> s = PWL(0:3, 10:13);

julia> 0 in domain(s)
true

julia> 5 in domain(s)
false

julia> s2 = Series(-10:10, sin);

julia> 0 in domain(s2)
true

julia> 0.5 in domain(s2)
true
```
"""
function domain(s::AbstractArraySignal)
    x = xvals(s)
    x[begin]..x[end]
end
domain(s::FiniteFunction) = s.domain
@signal_func domain

"""
    Window(func, interval; type=:rect, domain=range(-Inf, Inf))

Returns a function that applies a "window" to `func`, such that within `interval`,
values are multiplied by the window function (constant 1.0 for a rectangular window)
and outside of `interval` zeros are returned.

julia> f = Window(cos, 0 .. 2pi; type=:rect);

julia> f(-1)
0.0

julia> f(0)
1.0

julia> f(pi)
-1.0

julia> f(10)
0.0
"""
struct Window{X, Y, I<:Interval{X}}
    func::FunctionWrapper{Y, Tuple{X}}
    func_domain::I
    domain::I
    function Window(func, interval::Interval{X}=domain(func)
                    ; type=:rect, domain=Interval(typemin(X), typemax(X))) where {X}
        Y = typeof(func(first(interval)))
        if type !== :rect
            throw(ArgumentError("Only rectangular windows (type = :rect) currently supported."))
        end
        new{X, Y, Interval{X}}(func, interval, domain)
    end
end
domain(z::Window) = z.domain
function (z::Window{X, Y, I})(x) where {X, Y, I}
    if x ∉ domain(z)
        throw(DomainError(x, "$x is not in the domain of the signal: $(domain(z))"))
    end
    return x in z.func_domain ? z.func(x) : zero(Y)
end

"""
    ZeroPad(func, interval)

Returns a function that wraps the input function `func` such that it returns zero when outside the `interval`.

```jldoctest
julia> hi = PWL([0, 0.5], [1, 1]);

julia> pulse = ZeroPad(hi, 0 .. 1.);

julia> pulse(0)
1.0

julia> pulse(0.5)
1.0

julia> pulse(0.5 + 1e-9)
0.0

julia> domain(pulse)
[0.0 .. 1.0]
```

See also
[`clip`](@ref).
"""
struct ZeroPad{X, Y, I<:Interval{X}}
    func::FunctionWrapper{Y, Tuple{X}}
    func_domain::I
    domain::I
    function ZeroPad(func::AbstractContinuousSignal{X, Y}, interval::Interval{X}=domain(func)) where {X, Y}
        new{X, Y, Interval{X}}(func, domain(func), interval)
    end
end
domain(z::ZeroPad) = z.domain
function (z::ZeroPad{X, Y, I})(x) where {X, Y, I}
    if x ∉ domain(z)
        throw(DomainError(x, "$x is not in the domain of the signal: $(domain(z))"))
    end
    return x in z.func_domain ? z.func(x) : zero(Y)
end

"""
    zeropad(signal, interval)

Returns a zero-padded copy of `signal` that supports sampling in the given `interval`.

If the domain of `signal` extends outside of `interval`, it will be restricted.

```jldoctest
julia> hi = PWL([0, 0.5], [1, 1]);

julia> pulse = zeropad(hi, 0 .. 1);

julia> pulse(0)
1.0

julia> pulse(0.5)
1.0

julia> pulse(0.5 + 1e-9)
0.0

julia> domain(pulse)
[0.0 .. 1.0]
```
See also
[`clip`](@ref),
[`Periodic`](@ref).
"""
function zeropad(s::AbstractContinuousSignal{X, Y}, interval::Interval) where {X, Y}
    x = EndpointAxis(xvals(s), X(first(interval)), X(last(interval)))
    f = Window(s, domain(s))
    similar(s; x, f)
end
@signal_func zeropad

"""
    Periodic(func, interval)

Returns a function with input `x` that wraps down to the base `interval` and then applies function `func`.

```jldoctest
julia> f = Periodic(x->2x-3, 1 .. 2);

julia> f(0.0)
-1.0

julia> f(1.0)
-1.0

julia> f(2.0)
-1.0

julia> s = PWL(0:0.005:6, f);

julia> s(3)
-1.0
```
"""
struct Periodic{F,I <: Interval} <: Function
    func::F
    interval::I
end
function (p::Periodic)(x)
    t1 = first(p.interval)
    T = span(p.interval)
    x2 = mod(x-t1, T)+t1
    return p.func(x2)
end

function Base.repeat(s::AbstractContinuousSignal, counts::Int)
    x = repeat(xvals(s), counts) .+ floor.(range(0, length(s)*3-1) ./ length(s)).*span(domain(s))
    f = Periodic(s, domain(s))
    similar(s; x, f)
end

function check_x_y(x, y)
    # if !issorted(x)
    #     throw(ArgumentError("x axis must be monotonically increasing"))
    # end
    if length(x) != length(y)
        throw(DimensionMismatch("length x ($(length(x))) != length y ($(length(y)))"))
    end
    # if keys(x) != keys(y)
    #     throw(DimensionMismatch("x indices ($(firstindex(x)) to $(lastindex(x))) != y indices ($(firstindex(y)) to $(lastindex(y)))"))
    # end
    Base.require_one_based_indexing(x, y)
end
function check_domain_subset(smaller_domain, larger_domain, operation)
    iss = issubset(smaller_domain, larger_domain)
    if iss
        return
    end
    a, b = first(smaller_domain), last(smaller_domain)
    a2, b2 = first(larger_domain), last(larger_domain)
    if a < a2
        throw(DomainError(a, "$operation not in domain of signal, $larger_domain.  Hint: increase start of $operation to match `$a2`."))
    elseif b > b2
        throw(DomainError(a, "$operation not in domain of signal, $larger_domain.  Hint: decrease end of $operation to match `$b2`."))
    else
        # This could print out way to much for discrete signals if we use the actual sample values as the domain (vs an integral)
        throw(DomainError(smaller_domain, "domain is not a subest of the domain, $larger_domain."))
    end
end

# Convert AbstractMeasures to floats
abstract type AbstractMeasure <: Real end
#=
function SampledSignal(x::AbstractVector{<:AbstractMeasure}, y::AbstractVector; kwargs...)
    SampledSignal(float.(x), y; kwargs...)
end
function SampledSignal(x::AbstractVector, y::AbstractVector{<:AbstractMeasure}; kwargs...)
    SampledSignal(x, float.(y); kwargs...)
end
function SampledSignal(x::AbstractVector{<:AbstractMeasure}, y::AbstractVector{<:AbstractMeasure}; kwargs...)
    SampledSignal(float.(x), float.(y); kwargs...)
end
=#

"""
    PWL(xs, ys)
    PWL(x_interval, y_interval; N=1001)
    PWL(xs, signal)
    PWL(xs, function)
    PWL(signal)
Returns a continuous signal with piecewise-linear interpolation over the x-values.

# Variants:
- `PWL(xs, ys)` takes a vector of x- and corresponding y-values.
- `PWL(x_inteval, y_interval, N=1001)` two intervals for the domain of the signal using `N` samples.
- `PWL(xs, signal) the y-values come from sampling a signal `signal` at the x-values, `xs`
- `PWL(xs, function)` the y-values come from evaluating a function `function` at the x-values, `xs`
- `PWL(signal)` this creates a PWL signal using `PWL(xvals(signal), yvals(signal))`

# Examples

```jldoctest
julia> s = PWL(0:3, [0,1,1,0]);

julia> t = PWL(0..1, 0..1, N=11); # time axis

julia> s2 = 1.5 + 3sin(2pi*t) + sin(2pi*3t);

julia> s3 = PWL(0:0.25:1, s2); # sample s2
```

See also
[`PWC`](@ref),
[`PWQuadratic`](@ref),
[`PWCubic`](@ref),
[`PWAkima`](@ref),
[`ContinuousFunction`](@ref),
[`Series`](@ref),
[`domain`](@ref).
"""
function PWL end
PWL(x::AbstractVector, y::AbstractVector) = ContinuousSignal(float(x), float(y), interp=DataInterpolations.LinearInterpolation)
PWL(x::AbstractVector, s::AbstractSignal) = PWL(x, s.(x))
PWL(xint::Interval, yint::Interval; N=1001) = PWL(range(float(first(xint)), float(last(xint)), length=N), range(float(first(yint)), float(last(yint)), length=N))
PWL(x::AbstractVector, s::Function) = PWL(x, s.(x))
PWL(s::AbstractIterableSignal) = PWL(xvals(s), yvals(s))
@signal_func PWL

"""
    PWQuadratic(xs, ys)
    PWQuadratic(x_interval, y_interval; N=1001)
    PWQuadratic(xs, signal)
    PWQuadratic(xs, function)
    PWQuadratic(signal)
Returns a continuous signal with piecewise-quadratic interpolation over the x-values.
A quadradic interpolation is continuously differentiable and hits each sample point
exactly.

# Variants

- `PWQuadratic(xs, ys)` takes a vector of x- and corresponding y-values.
- `PWQuadratic(x_inteval, y_interval, N=1001)` two intervals for the domain of the signal using `N` samples.
- `PWQuadratic(xs, signal) the y-values come from sampling a signal `signal` at the x-values, `xs`
- `PWQuadratic(xs, function)` the y-values come from evaluating a function `function` at the x-values, `xs`
- `PWQuadratic(signal)` this creates a PWQuadratic signal using `PWQuadratic(xvals(signal), yvals(signal))`

# Examples

```jldoctest
julia> s = PWQuadratic(0:4, [0, 1, 1, 0, 3]);

julia> s(1) == 1.0 # samples maintained
true

julia> s(1.5)
1.125

julia> t = PWQuadratic(0..1, 0..1, N=11); # time axis

julia> s2 = 1.5 + 3sin(2pi*t) + sin(2pi*3t)+10t;

julia> s2(0.25)
6.0

julia> s3 = PWL(s2); # convert to PWL

julia> round(s3(0.25), sigdigits=4)
6.265
```

See also
[`PWC`](@ref),
[`PWL`](@ref),
[`PWQuadratic`](@ref),
[`PWCubic`](@ref),
[`PWAkima`](@ref),
[`ContinuousFunction`](@ref),
[`Series`](@ref),
[`domain`](@ref).
"""
function PWQuadratic end
PWQuadratic(x::AbstractVector, y::AbstractVector) = ContinuousSignal(float(x), float(y), interp=DataInterpolations.QuadraticInterpolation)
PWQuadratic(x::AbstractVector, s::AbstractSignal) = PWQuadratic(x, s.(x))
PWQuadratic(x::AbstractVector, s::Function) = PWQuadratic(x, s.(x))
PWQuadratic(xint::Interval, yint::Interval; N=1001) = PWQuadratic(range(float(first(xint)), float(last(xint)), length=N), range(float(first(yint)), float(last(yint)), length=N))
PWQuadratic(s::AbstractIterableSignal) = PWQuadratic(xvals(s), yvals(s))
@signal_func PWQuadratic

"""
    PWCubic(xs, ys)
    PWCubic(x_interval, y_interval; N=pts)
    PWCubic(xs, signal)
    PWCubic(xs, function)
    PWCubic(signal)
Returns a continuous signal with piecewise-cubic spline interpolation over the x-values.
A cubic spline interpolation is continuously differentiable and hits each sample point
exactly.

# Variants

- `PWCubic(xs, ys)` takes a vector of x- and corresponding y-values.
- `PWCubic(x_inteval, y_interval, N=1001)` two intervals for the domain of the signal, using `N` samples.
- `PWCubic(xs, signal) the y-values come from sampling a signal `signal` at the x-values, `xs`
- `PWCubic(xs, function)` the y-values come from evaluating a function `function` at the x-values, `xs`
- `PWCubic(signal)` this creates a PWCubic signal using `PWCubic(xvals(signal), yvals(signal))`

# Examples

```jldoctest
julia> s = PWCubic(0:4, [0, 1, 1, 0, 3]);

julia> s(1) == 1.0 # samples maintained
true

julia> s(1.5)
1.2522321428571428

julia> t = PWCubic(0..1, 0..1, N=11); # time axis

julia> s2 = 1.5 + 3sin(2pi*t) + sin(2pi*3t)+10t;

julia> s2(0.25)
6.0

julia> s3 = PWQuadratic(s2); # convert to PWQuadratic

julia> round(s3(0.25), sigdigits=5)
6.2093
```

See also
[`PWC`](@ref),
[`PWL`](@ref),
[`PWQuadratic`](@ref),
[`PWCubic`](@ref),
[`PWAkima`](@ref),
[`ContinuousFunction`](@ref),
[`Series`](@ref),
[`domain`](@ref).
"""
function PWCubic end
PWCubic(x::AbstractVector, y::AbstractVector) = ContinuousSignal(float(x), float(y), interp=DataInterpolations.CubicSpline)
PWCubic(x::AbstractVector, s::AbstractSignal) = PWCubic(x, s.(x))
PWCubic(x::AbstractVector, s::Function) = PWCubic(x, s.(x))
PWCubic(xint::Interval, yint::Interval; N=1001) = PWCubic(range(float(first(xint)), float(last(xint)), length=N), range(float(first(yint)), float(last(yint)), length=N))
PWCubic(s::AbstractIterableSignal) = PWCubic(xvals(s), yvals(s))
@signal_func PWCubic

"""
    PWAkima(xs, ys)
    PWAkima(x_interval, y_interval; N=pts)
    PWAkima(xs, signal)
    PWAkima(xs, function)
    PWAkima(signal)
Returns a non-smooth signal with piecewise-akima spline interpolation over the x-values.
An Akima spline interpolation is realistic for analog signals and hits each sample point
exactly.

# Variants

- `PWAkima(xs, ys)` takes a vector of x- and corresponding y-values.
- `PWAkima(x_inteval, y_interval, N=1001)` two intervals for the domain of the signal, using `N` samples.
- `PWAkima(xs, signal) the y-values come from sampling a signal `signal` at the x-values, `xs`
- `PWAkima(xs, function)` the y-values come from evaluating a function `function` at the x-values, `xs`
- `PWAkima(signal)` this creates a PWAkima signal using `PWAkima(xvals(signal), yvals(signal))`

# Examples

```jldoctest
julia> s = PWAkima(0:4, [0, 1, 1, 0, 3]);

julia> s(1) == 1.0 # samples maintained
true

julia> s(1.5)
1.0875

julia> t = PWAkima(0..1, 0..1, N=11); # time axis

julia> s2 = 1.5 + 3sin(2pi*t) + sin(2pi*3t)+10t;

julia> s2(0.75)
7.0

julia> s3 = PWL(s2); # convert to PWL

julia> round(s3(0.75), sigdigits=5)
6.7346
```

See also
[`PWC`](@ref),
[`PWL`](@ref),
[`PWQuadratic`](@ref),
[`PWCubic`](@ref),
[`PWAkima`](@ref),
[`ContinuousFunction`](@ref),
[`Series`](@ref),
[`domain`](@ref).
"""
function PWAkima end
PWAkima(x::AbstractVector, y::AbstractVector) = ContinuousSignal(float(x), float(y), interp=DataInterpolations.AkimaInterpolation)
PWAkima(x::AbstractVector, s::AbstractSignal) = PWAkima(x, s.(x))
PWAkima(xint::Interval, yint::Interval; N=1001) = PWAkima(range(float(first(xint)), float(last(xint)), length=N), range(float(first(yint)), float(last(yint)), length=N))
PWAkima(x::AbstractVector, s::Function) = PWAkima(x, s.(x))
PWAkima(s::AbstractIterableSignal) = PWAkima(xvals(s), yvals(s))
@signal_func PWAkima

"""
    Series(xs, ys)
    Series(xs, signal)
    Series(xs, function)
    Series(x_interval, y_interval; N=1001)
    Series(signal)
Returns a discrete point-wise signal with no interpolation.

# Variants
- `Series(xs, ys)` takes a vector of x- and corresponding y-values.
- `Series(xs, signal) the y-values come from sampling a signal `signal` at the x-values, `xs`
- `Series(xs, function)` the y-values come from evaluating a function `function` at the x-values, `xs`
- `Series(x_interval, y_interval, N=1001)` two intervals for the domain of the signal, using `N` samples.
- `Series(signal)` this creates a Series signal using `Series(xvals(signal), yvals(signal))`

# Examples

```jldoctest
julia> s = Series(0:4, [-1,1,2,-1,2]);

julia> s(3) # samples maintained
-1

julia> s2 = Series([0, 2, 4], s); # sample s2

julia> s3 = Series(-360:10:360, cosd); # cos in 10 degree steps

julia> s3(180)
-1.0

julia> s4 = PWAkima(s3); # convert to Akima interpolation

julia> round(s4(5), sigdigits=5)
0.99623
```

See also
[`PWL`](@ref),
[`PWC`](@ref),
[`PWQuadratic`](@ref),
[`PWCubic`](@ref),
[`PWAkima`](@ref),
[`ContinuousFunction`](@ref),
[`domain`](@ref).
"""
function Series end
Series(x::AbstractVector, y::AbstractVector) = ArraySignal(x, y)
Series(x::AbstractVector, s::AbstractSignal) = Series(x, s.(x))
Series(x::AbstractVector, s::Function) = Series(x, s.(x))
Series(xint::Interval, yint::Interval; N=1001) = Series(range(float(first(xint)), float(last(xint)), length=N), range(float(first(yint)), float(last(yint)), length=N))
Series(signal::AbstractSignal) = Series(xvals(signal), yvals(signal))


"""
    PWC(xs, ys)
    PWC(xs, signal)
    PWC(xs, function)
    PWC(x_interval, y_interval; N=1001)
    PWC(signal)
Returns a continuous signal with piecewise-constant interpolation between x-values.

# Variants
- `PWC(xs, ys)` takes a vector of x- and corresponding y-values.
- `PWC(xs, signal) the y-values come from sampling a signal `signal` at the x-values, `xs`
- `PWC(xs, function)` the y-values come from evaluating a function `function` at the x-values, `xs`
- `PWC(x_interval, y_interval, N=1001)` two intervals for the domain of the signal, using `N` samples.
- `PWC(signal)` this creates a PWC signal using `PWC(xvals(signal), yvals(signal))`

# Examples

```jldoctest
julia> s1 = PWC(0:3, [true, false, false, true]);

julia> s1(0.5)
true

julia> s1(1)
false

julia> sample_and_hold = PWC(0:45:360, sind);  # sin in degrees

julia> yvals(sample_and_hold)
9-element Vector{Float64}:
  0.0
  0.7071067811865476
  1.0
  0.7071067811865476
  0.0
 -0.7071067811865476
 -1.0
 -0.7071067811865476
  0.0
```

See also
[`PWL`](@ref),
[`PWQuadratic`](@ref),
[`PWCubic`](@ref),
[`PWAkima`](@ref),
[`ContinuousFunction`](@ref),
[`Series`](@ref),
[`domain`](@ref).
"""
function PWC end
PWC(x::AbstractVector, y::AbstractVector) = ContinuousSignal(x, y, interp=DataInterpolations.ConstantInterpolation)
PWC(x::AbstractVector, s::AbstractSignal) = PWC(x, s.(x))
PWC(x::AbstractVector, s::Function) = PWC(x, s.(x))
PWC(xint::Interval, yint::Interval; N=1001) = PWC(range(float(first(xint)), float(last(xint)), length=N), range(float(first(yint)), float(last(yint)), length=N))
PWC(s::AbstractIterableSignal) = PWC(xvals(s), yvals(s))
@signal_func PWC

"""
    ispwc(signal)
Returns true if the signal is a PWC signal.

# Examples

```jldoctest
julia> ispwc(PWC(0:2, [0, 1, 0]))
true

```
"""
function ispwc end
ispwc(::Any) = false
function ispwc(s::AbstractContinuousSignal)
    # FIXME: this doesn't work for things like 2*PWC()
    T = typeof(s)
    if hasfield(T, :f) && hasfield(typeof(s.f), :obj)
        return s.f.obj[] isa DataInterpolations.ConstantInterpolation
    end
    return false
end

#################
# Clip
##################
"""
    clip(signal, from..to)

Return a signal that is a window onto the original `signal` between the `from` and `to` x-axis points.
This function is very fast as no copies are made of the original signal.

# Examples

```jldoctest clip
julia> pwl = PWL(0.0:3, [0.0, 1, -1, 0]);

julia> s1 = clip(pwl, 0.2 .. 2.5);

julia> s1(0.2)
0.2

julia> s1(2.5)
-0.5

julia> s1(2.8)
ERROR: DomainError with 2.8:
2.8 is not in the domain of the signal: [0.2 .. 2.5]

julia> series = Series(-10:10, sin);

julia> s2 = clip(series, -5 .. 5);

julia> s2(0)
0.0

julia> s2(8)
ERROR: DomainError with 8:
8 is not in the domain of the signal: [-5 .. 5]
```

See also
[`domain`](@ref),
[`xshift`](@ref),
[`xscale`](@ref),
[`ZeroPad`](@ref).
"""
function clip end
function clip(s::AbstractArraySignal, interval::Interval)
    left = searchsortedfirst(xvals(s), first(interval), rev=descending(domain(s)))
    right = searchsortedlast(xvals(s), last(interval), rev=descending(domain(s)))
    x = @view xvals(s)[left:right]
    y = @view yvals(s)[left:right]
    similar(s; x, y)
end
function clip(s::AbstractContinuousSignal{X, Y}, interval::Interval) where {X, Y}
    left = searchsortedfirst(xvals(s), first(interval), rev=descending(domain(s)))
    right = searchsortedlast(xvals(s), last(interval), rev=descending(domain(s)))
    x = @view xvals(s)[left:right]
    x = EndpointAxis(x, X(first(interval)), X(last(interval)))
    similar(s; x)
end
function clip(interval::Interval)
    signal -> clip(signal, interval)
end
@signal_func clip

# Disable broadcasting inside a signal
Base.broadcastable(x::AbstractSignal) = Ref(x)

# helper to make a rational with eps(n) tolerance
asrational(n::Rational) = n
asrational(n::AbstractFloat) = rationalize(n)
asrational(n) = Rational(n)
