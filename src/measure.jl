################ Measure Options ########
# Default options for measures
const MEASURE_DEFAULTS = Dict{Symbol,Any}(:sigdigits => 5, :trace => true)

export inspect

"A measure on an edge/transition"
abstract type AbstractTransitionMeasure <: AbstractMeasure end

struct MeasureOptions <: AbstractDict{Symbol, Any}
    dict::Dict{Symbol, Any}
end

MeasureOptions(; options...) = MeasureOptions(Dict(options))

Base.get(mo::MeasureOptions, key, default) = get(mo.dict, key, default)

function Base.propertynames(mo::MeasureOptions, private::Bool=false)
    opts = collect(union(keys(getfield(mo, :dict)), keys(MEASURE_DEFAULTS)))
    if private
        push!(opts, :dict)
    end
    sort!(opts)
end
function Base.getproperty(mo::MeasureOptions, option::Symbol)
    if haskey(getfield(mo, :dict), option)
        getfield(mo, :dict)[option]
    elseif haskey(MEASURE_DEFAULTS, option)
        MEASURE_DEFAULTS[option]
    elseif option == :dict
        getfield(mo, :dict)
    else
        error("Unknown measure option: $option")
    end
end
function Base.getindex(mo::MeasureOptions, option::Symbol)
    getproperty(mo, option)
end
function Base.getindex(mo::MeasureOptions, idx::Integer)
    prop = propertynames(mo)[idx]
    getproperty(mo, prop)
end
Base.haskey(mo::MeasureOptions, key::Symbol) = haskey(getfield(mo, :dict), key) || haskey(MEASURE_DEFAULTS, key)
Base.length(mo::MeasureOptions) = length(propertynames(mo))
function Base.iterate(mo::MeasureOptions, state::Integer=1)
    if state > length(mo)
        return nothing
    else
        prop = propertynames(mo)[state]
        value = getproperty(mo, prop)
        return ((prop => value), state + 1)
    end
end
function Base.setproperty!(mo::MeasureOptions, option::Symbol, value)
    dict = getfield(mo, :dict)
    dict[option] = value
end

################ Measure ###########################

function Base.propertynames(mo::AbstractMeasure, private::Bool=false)
    fields = fieldnames(typeof(mo))
    # measures always have a .value property:
    k = union([:value], fields)
    # add calculated properties:
    if :signal in fields && :x in fields
        k = union(k, [:y, :slope])
    end
    if :pt1 in fields && :pt2 in fields
        k = union(k, [:dx, :dy, :slope])
    end
    if :pt1 in fields && :pt2 in fields && private
        k = union(k, [:signal1, :signal2, :x1, :x2, :y1, :y2])
    end
    return k
end

function Base.getproperty(m::AbstractMeasure, key::Symbol)
    fields = fieldnames(typeof(m))
    if key in fields
        return getfield(m, key)
    elseif key == :value
        return get_value(m)  # API for user to define a way to calculate the value
    elseif key == :y && :signal in fields && :x in fields
        return getfield(m, :signal)(getfield(m, :x))
    elseif key == :slope && :signal in fields && :x in fields
        return derivative(getfield(m, :signal))(getfield(m, :x))
    elseif :pt1 in fields && :pt2 in fields
        pt1 = getfield(m, :pt1)
        pt2 = getfield(m, :pt2)
        if key == :signal1
            return pt1.signal
        elseif key == :signal2
            return pt2.signal
        elseif key == :dx
            return pt2.x - pt1.x
        elseif key == :dy
            return pt2.y - pt1.y
        elseif key == :slope
            return (m.pt2.y - m.pt1.y)/(m.pt2.x - m.pt1.x)
        elseif key == :x1
            return pt1.x
        elseif key == :y1
            return pt1.y
        elseif key == :x2
            return pt2.x
        elseif key == :y2
            return pt2.y
        else
            error("$(typeof(m)) has no property `$key`, use one of: `", join(propertynames(m), "`, `", "` or `"), "`")
        end
    else
        error("$(typeof(m)) has no property `$key`, use one of: `", join(propertynames(m), "`, `", "` or `"), "`")
    end
end
function Base.setproperty!(m::AbstractMeasure, option::Symbol, value)
    if option == :name && hasfield(typeof(m), option)
        setfield!(m, :name, value)
        return m
    end
    error("type $(typeof(m)) cannot set property `$option`, try `meas.options.$option = $value` instead.")
end
function get_value(::T) where T <: AbstractMeasure
    error("Missing definition of: get_value(m::$T) = ...")
end
function ScaledNumbersOutput.to_SI(m::AbstractMeasure)
    ScaledNumbersOutput.to_SI(get_value(m); m.options.sigdigits)
end
#function Base.show(io::IO, m::FunctionMeasure)
#    print(":$(m.name)")
#end
#function Base.round(m::Threshold{CrossMeasure}, args...; sigdigits, kwargs...)
#    val = round(m.value.x, args...; sigdigits, kwargs...)
#    T = typeof(m)
#    if T <: either
#        val = either(val)
#    elseif T <: rising
#        val = rising(val)
#    elseif T <: falling
#        val = falling(val)
#    end
#    return val
#end
function Base.round(m::Threshold, args...; sigdigits, kwargs...)
    v = round(m.value, args...; sigdigits, kwargs...)
    if m isa rising
        return rising(v)
    elseif m isa falling
        return falling(v)
    elseif m isa either
        return either(v)
    end
    error("Unknown threshold type: $(typeof(m))")
end
function Base.round(m::AbstractMeasure, prop::Symbol)
    round(getproperty(m, prop), sigdigits=m.options.sigdigits)
end
function Base.round(m::AbstractMeasure, val::Real)
    error("FIXME")
end
function display_value(val::Real; sigdigits::Int=5)
    ScaledNumbersOutput.to_SI(val; sigdigits)
end
function display_value(m::AbstractMeasure, val::Real; sigdigits=m.options.sigdigits)
    ScaledNumbersOutput.to_SI(val; m.options.sigdigits)
end
function display_value(m::AbstractMeasure, prop::Symbol; sigdigits=m.options.sigdigits)
    val = getproperty(m, prop)
    display_value(m, val; sigdigits)
end
function display_value(m::AbstractMeasure; sigdigits=m.options.sigdigits)
    ScaledNumbersOutput.to_SI(m.value; sigdigits)
end
function display_value(m::AbstractMeasure, values::Vector; sigdigits=m.options.sigdigits)
    string("[" * join([display_value(m, v; sigdigits) for v in values], ", ") * "]")
end
function display_value(m::AbstractMeasure, th::Threshold; sigdigits=m.options.sigdigits)
    return display_value(th; sigdigits)
end
function display_value(th::Threshold, prop::Symbol=:value; sigdigits=5)
    val = ScaledNumbersOutput.to_SI(getproperty(th, prop); sigdigits)
    if th isa rising
        return "rising($val)"
    elseif th isa falling
        return "falling($val)"
    elseif th isa either
        return "either($val)"
    end
    error("Unknown threshold type: $(typeof(th))")
end

for func in [:+, :-, :*, :/, :÷, :^, :%]
    @eval begin
        function (Base.$func)(m1::T1, m2::T2) where {T1<:AbstractMeasure, T2<:AbstractMeasure}
            name = "$(m1.name) $($func) $(m2.name)"
            value = ($func)(get_value(m1), get_value(m2))
            DerivedMeasure([m1, m2], value; name)
        end
        function (Base.$func)(m1::T1, m2::Real) where {T1<:AbstractMeasure}
            name = "$(m1.name) $($func) $(m2)"
            value = ($func)(get_value(m1), m2)
            DerivedMeasure(m1, value; name)
        end
        function (Base.$func)(m1::Real, m2::T2) where {T2<:AbstractMeasure}
            name = "$(m1) $($func) $(m2.name)"
            value = ($func)(m1, get_value(m2))
            DerivedMeasure(m2, value; name)
        end
        # To remove ambiguous errors:
        function (Base.$func)(m1::T1, m2::Integer) where {T1<:AbstractMeasure}
            name = "$(m1.name) $($func) $(m2)"
            value = ($func)(get_value(m1), m2)
            DerivedMeasure(m1, value; name)
        end
        function (Base.$func)(m1::Integer, m2::T2) where {T2<:AbstractMeasure}
            name = "$(m1) $($func) $(m2.name)"
            value = ($func)(m1, get_value(m2))
            DerivedMeasure(m2, value; name)
        end
    end
end
for func in [:<, :(==), :(<=)]
    @eval begin
        function (Base.$func)(m1::T1, m2::T2) where {T1<:AbstractMeasure, T2<:AbstractMeasure}
            ($func)(get_value(m1), get_value(m2))
        end
        function (Base.$func)(m1::T1, m2::Real) where {T1<:AbstractMeasure}
            ($func)(get_value(m1), m2)
        end
        function (Base.$func)(m1::ForwardDiff.Dual, m2::T2) where {T2<:AbstractMeasure}
            ($func)(m1, get_value(m2))
        end
        function (Base.$func)(m1::T1, m2::ForwardDiff.Dual) where {T1<:AbstractMeasure}
            ($func)(get_value(m1), m2)
        end
        function (Base.$func)(m1::Real, m2::T2) where {T2<:AbstractMeasure}
            ($func)(m1, get_value(m2))
        end
    end
end
Base.isinteger(a::AbstractMeasure) = isinteger(get_value(a))
Base.mod(a::AbstractMeasure, b::AbstractMeasure) = mod(get_value(a), get_value(b))
Base.floor(::Type{<:Integer}, a::AbstractMeasure) = floor(Integer, get_value(a))
Base.round(::Type{<:Integer}, a::AbstractMeasure) = round(Integer, get_value(a))
Base.isless(a::AbstractMeasure, b::AbstractMeasure) = isless(get_value(a), get_value(b))
Base.isless(a::AbstractMeasure, b::Real) = isless(get_value(a), b)
Base.isless(a::Real, b::AbstractMeasure) = isless(a, get_value(b))
Base.isless(a::AbstractMeasure, b::AbstractFloat) = isless(get_value(a), b)
Base.isless(a::AbstractFloat, b::AbstractMeasure) = isless(a, get_value(b))
for func in UNARY_OPERATORS
    @eval begin
        function (Base.$func)(m::T) where T <: AbstractMeasure
            ($func)(get_value(m))
        end
    end
end

function assoc(original::T; kwargs...) where T
    fields = fieldnames(T)
    updates = kwargs
    T(map(f->get(updates, f, getfield(original, f)), fields)...)
end


Base.isfinite(m::AbstractMeasure) = isfinite(get_value(m))
#Base.zero(m::AbstractMeasure) = assoc(m, value=zero(get_value(m)))
#Base.one(m::AbstractMeasure) = assoc(m, value=one(get_value(m)))
#Base.oneunit(m::AbstractMeasure) = assoc(m, value=oneunit(get_value(m)))
AbstractMeasure(m::AbstractMeasure) = m
#Base.AbstractFloat(m::AbstractMeasure) = float(get_value(m))
Base.abs(m::AbstractMeasure) = abs(get_value(m))

Base.promote_rule(::Type{M}, ::Type{S}) where {M<:AbstractMeasure, S<:AbstractFloat} = DerivedMeasure
Base.promote_rule(::Type{M}, ::Type{S}) where {M<:AbstractMeasure, S<:Integer} = DerivedMeasure
Base.Float64(m::AbstractMeasure) = convert(Float64, get_value(m))
Base.float(m::AbstractMeasure) = float(get_value(m))
Base.isnan(m::AbstractMeasure) = isnan(get_value(m))
#Base.sign(m::AbstractMeasure) = sign(get_value(m))

abstract type OnePointMeasure <: AbstractMeasure end


"""
    XMeasure(signal, x; options...)
Measurement of an X value with a corresponding Y value (such as a cross, xmin, xmax, etc).
"""
struct XMeasure <: OnePointMeasure
    name::String
    signal # input signal for measurement
    x      # x location of measurement
    options::MeasureOptions
end
function XMeasure(signal, x; name="XMeasure", options...)
    if !(x in domain(signal)) && !isnan(x)
        error("x value ($x) must be in domain of signal: $(domain(signal))")
    end
    XMeasure(name, signal, x, MeasureOptions(options))
end
get_value(m::XMeasure) = m.x
Base.zero(m::XMeasure) = XMeasure(m.signal, zero(get_value(m)); m.name, m.options)
Base.one(m::XMeasure) = XMeasure(m.signal, one(get_value(m)); m.name, m.options)
Base.oneunit(m::XMeasure) = XMeasure(m.signal, oneunit(get_value(m)); m.name, m.options)

"""
    YMeasure(signal, x; options...)
Measurement of an Y value at a given X value (such as a ymin, ymax, etc).
"""
struct YMeasure <: OnePointMeasure
    name::String
    signal   # input signal for measurement
    x        # x location of y measurement
    options::MeasureOptions
end
function YMeasure(signal, x; name="YMeasure", options...)
    if !(x in domain(signal)) && !isnan(x)
        error("x value ($x) must be in domain of signal: $(domain(signal))")
    end
    YMeasure(name, signal, x, MeasureOptions(options))
end
get_value(m::YMeasure) = m.signal(m.x)
Base.zero(m::YMeasure) = error("Error: not supported")
Base.one(m::YMeasure) = error("Error: not supported")
Base.oneunit(m::YMeasure) = error("Error: not supported")


"""
    YLevelMeasure(signal, y; options...)
Measurement of a Y value (level) with no corresponding X value (mean, etc).
"""
struct YLevelMeasure  <: AbstractMeasure
    name::String
    signal # signal to plot (using its clip range)
    # How to show position of measurement on plot:
    y
    options::MeasureOptions
end
function YLevelMeasure(signal::AbstractSignal, y; name="YLevelMeasure", options...)
    YLevelMeasure(name, signal, y, MeasureOptions(options))
end
get_value(m::YLevelMeasure) = m.y
Base.zero(m::YLevelMeasure) = YLevelMeasure(m.signal, zero(get_value(m)); m.name, m.options)
Base.one(m::YLevelMeasure) = YLevelMeasure(m.signal, one(get_value(m)); m.name, m.options)
Base.oneunit(m::YLevelMeasure) = YLevelMeasure(m.signal, oneunit(get_value(m)); m.name, m.options)

"""
    ylevel(signal, y; name, options...)
Measures the y value (level) of a signal at a given y value (level).
This is useful for being able to plot the signal along with the y-value.
"""
ylevel(s::AbstractSignal, y; name="ylevel", options...) = YLevelMeasure(s, y; name, options...)

"""
    CrossMeasure(signal, x; yth, options...)
Measurement of an X at an intersecting y-threshold (`yth`).
"""
struct CrossMeasure <: OnePointMeasure
    name::String
    signal         # input signal for measurement
    x              # x location of measurement
    yth            # y threshold
    options::MeasureOptions
end
function CrossMeasure(signal::AbstractSignal, x, yth::Threshold; name="cross", options...)
    CrossMeasure(name, signal, x, yth, MeasureOptions(options))
end
function CrossMeasure(signal::AbstractSignal, x, yth::AbstractMeasure; name="cross", options...)
    CrossMeasure(name, signal, x, Threshold(yth.y), MeasureOptions(options))
end
function CrossMeasure(signal::AbstractSignal, x, yth; name="cross", options...)
    CrossMeasure(name, signal, x, Threshold(yth), MeasureOptions(options))
end
function CrossMeasure(signal::AbstractSignal, x::AbstractMeasure; name="cross", options...)
    CrossMeasure(name, signal, x, Threshold(x.y), MeasureOptions(options))
end
get_value(m::CrossMeasure) = m.x
Base.zero(m::CrossMeasure) = CrossMeasure(m.signal, zero(get_value(m)), m.yth; m.name, m.options)
Base.one(m::CrossMeasure) = CrossMeasure(m.signal, one(get_value(m)), m.yth; m.name, m.options)
Base.oneunit(m::CrossMeasure) = CrossMeasure(m.signal, oneunit(get_value(m)), m.yth; m.name, m.options)

function (Base.:-)(m2::CrossMeasure, m1::CrossMeasure)
    DelayMeasure(m1, m2; m1.options, name="delay")
end
function (Base.:-)(m2::CrossMeasure, x::Real)
    if x in domain(m2.signal)
        m1 = XMeasure(m2.signal, x)
        DelayMeasure(m1, m2; m2.options, name="delay")
    else
        m2.value - x
    end
end
function (Base.:-)(x::Real, m1::CrossMeasure)
    if x in domain(m1.signal)
        m2 = XMeasure(m1.signal, x)
        DelayMeasure(m1, m2; m1.options, name="delay")
    else
        m1.value - x
    end
end
# remove ambiguous errors:
(Base.:-)(x::Integer, m1::CrossMeasure) = float(x) - m1
(Base.:-)(m1::CrossMeasure, x::Integer) = m1 - float(x)

"""
    DerivedMeasure(measure, value; name, options...)
    DerivedMeasure(measures, value; name, options...)
A measure that is derived from other measures.
"""
struct DerivedMeasure <: AbstractMeasure
    name::String
    measures::Vector{AbstractMeasure}
    value
    options::MeasureOptions
end
function DerivedMeasure(measure::AbstractMeasure, value; name="DerivedMeasure", options...)
    DerivedMeasure(name, AbstractMeasure[measure], value, MeasureOptions(options))
end
function DerivedMeasure(measures::Vector{<:AbstractMeasure}, value; name="DerivedMeasure", options...)
    DerivedMeasure(name, AbstractMeasure[m for m in measures], value, MeasureOptions(options))
end
get_value(m::DerivedMeasure) = m.value
Base.zero(m::DerivedMeasure) = DerivedMeasure(m.measures, zero(get_value(m)); m.name, m.options)
Base.one(m::DerivedMeasure) = DerivedMeasure(m.measures, one(get_value(m)); m.name, m.options)
Base.oneunit(m::DerivedMeasure) = DerivedMeasure(m.measures, oneunit(get_value(m)); m.name, m.options)
# Need this for `mean`
DerivedMeasure(f::Real) = DerivedMeasure(string(f), AbstractMeasure[], f, MeasureOptions())
# Needed for interval: cross(s, 0) .. 3.4
DerivedMeasure(f::AbstractMeasure) = DerivedMeasure(string(f), AbstractMeasure[f], get_value(f), f.options)

function crossings_dir(crosses::Vector{CrossMeasure})
    T1 = typeof(crosses[begin].yth)
    T2 = typeof(crosses[end].yth)
    if T1 == rising && T1 == rising
        return rising
    elseif T1 == falling && T1 == falling
        return falling
    else
        return either
    end
end

"""
    TransitionMeasure(; name, crosses, signal, options)
Measure of a transition by a set of crosses on the same signal.
"""
struct TransitionMeasure <: AbstractTransitionMeasure
    name::String
    signal
    dir
    crosses::Vector{CrossMeasure}
    monotonicity::Float64
    options::MeasureOptions
    function TransitionMeasure(; name::String, crosses::Vector{CrossMeasure}, signal=first(crosses).signal,
                                    dir = crossings_dir(crosses),
                                    options::MeasureOptions=MeasureOptions())
        if any(c.signal != signal for c in crosses)
            error("TransitionMeasure: all crosses must be on the same signal")
        end
        sig_tr = clip(signal, crosses[begin] .. crosses[end])
        mono = monotonicity(sig_tr)
        new(name, signal, dir, crosses, mono, options)
    end
end
function TransitionMeasure(crosses::Vector{CrossMeasure}; name="TransitionMeasure", options...)
    TransitionMeasure(; name, crosses, options=MeasureOptions(options))
end
get_value(m::TransitionMeasure) = last(m.crosses) - first(m.crosses)
Base.zero(m::TransitionMeasure) = TransitionMeasure(zero.(m.crosses); m.name, m.options)
Base.one(m::TransitionMeasure) = TransitionMeasure(zero.(one.(m.crosses)); m.name, m.options)
#? Base.oneunit(m::TransitionMeasure) = TransitionMeasure(oneunit.(zero.(m.crosses), oneunit(m.pt2); m.name, m.options)
function clip(tr::TransitionMeasure)
    TransitionMeasure(; tr.name, tr.crosses, signal=clip(tr.signal, tr.crosses[1].x .. tr.crosses[end].x), tr.options)
end



"""
    abstract type TwoPointMeasure <: AbstractMeasure end
A abstract result holder for a two-point measurement on a single signal.
The measure will display a graphical preview of the signal and
measurement and it can also be used like a regular number in math expressions.
User should create their own type with the minimum fields below:

```julia
struct MyMeasure <: TwoPointMeasure
    pt1::AbstractMeasure
    pt2::AbstractMeasure
    options::MeasureOptions
end
```
"""

"Two point measure"
abstract type TwoPointMeasure <: AbstractMeasure end

"Two point measure in the X direction"
abstract type DxMeasure <: TwoPointMeasure end

"""
    DelayMeasure(point1, point2; name="DelayMeasure", options...)
Measurement of the delay (`point2.x - point1.x`), of a signal

The returned DelayMeasure object has the following properties:
- `name`: the name of the measurement
- `pt1`: the crossing point of the first Threshold
- `pt2`: the crossing point of the second Threshold
- `value`
"""
struct DelayMeasure <: DxMeasure
    name::String
    pt1
    pt2
    options::MeasureOptions
end
function DelayMeasure(pt1::AbstractMeasure, pt2::AbstractMeasure; name="DelayMeasure", options...)
    DelayMeasure(name, pt1, pt2, MeasureOptions(options))
end
function DelayMeasure(transition1::TransitionMeasure, transition2::TransitionMeasure; name="DelayMeasure", options...)
    # expect a transition with 3 crosses at low_transition, delay_thresh, high_transition but will work also
    # if only 1 cross
    i1 = min(firstindex(transition1.crosses)+1, length(transition1.crosses))
    i2 = max(lastindex(transition2.crosses)-1, firstindex(transition2.crosses))
    DelayMeasure(name, transition1.crosses[i1], transition2.crosses[i2], MeasureOptions(options))
end
get_value(m::DelayMeasure) = m.pt2.x - m.pt1.x #get_value(m.pt2) - get_value(m.pt1)  # Maybe this should be m1 - m2?
Base.zero(m::DelayMeasure) = DelayMeasure(zero(m.pt1), zero(m.pt2); m.name, m.options)
Base.one(m::DelayMeasure) = DelayMeasure(zero(one(m.pt1)), one(m.pt2); m.name, m.options)
Base.oneunit(m::DelayMeasure) = DelayMeasure(zero(m.pt1), oneunit(m.pt2); m.name, m.options)


"""
    RisetimeMeasure(transition; name="RisetimeMeasure", options...)
Measurement of risetime of a transition from the `low_threshold` to the `high_threshold` threshold
"""
struct RisetimeMeasure <: DxMeasure
    name::String
    signal
    transition_low::Threshold
    transition_high::Threshold
    low_threshold::Threshold
    high_threshold::Threshold
    transition::TransitionMeasure
    values::Vector{Float64}
    select::Function
    pt1::CrossMeasure
    pt2::CrossMeasure
    monotonicity::Float64
    options::MeasureOptions
end
function RisetimeMeasure(transition::TransitionMeasure;
                            signal=transition.crosses[1].signal,
                            name="RisetimeMeasure",
                            transition_low=nothing,
                            transition_high=nothing,
                            low_threshold=nothing,
                            high_threshold=nothing,
                            select=maximum,
                            monotonicity=transition.monotonicity,
                            options...)
    @assert all(cross -> cross.signal == signal, transition.crosses) "all crosses on a transition must be on the same signal"
    yths =  unique(map(cr -> cr.yth, filter(cr -> cr.yth isa rising, transition.crosses)))
    comma = ", "
    @assert length(yths) >= 2 "RisetimeMeasure: transition must have at least two rising crosses at different thresholds: found $(join(yths, comma))"
    if isnothing(low_threshold)
        if length(yths) <= 3
            low_threshold = yths[begin]
        else
            low_threshold = yths[begin+1]
        end
    end
    if isnothing(high_threshold)
        if length(yths) <= 3
            high_threshold = yths[end]
        else
            high_threshold = yths[end-1]
        end
    end
    LHs = each_low_high(transition, low_threshold, high_threshold)
    values = [h.x - l.x for (l, h) in LHs]
    if isnothing(transition_low)
        transition_low = first(filter_crosses_by_threshold(transition, low_threshold))
    end
    if isnothing(transition_high)
        transition_high = last(filter_crosses_by_threshold(transition, high_threshold))
    end
    ### Figure out which two points to use to represent the risetime:
    value = select(values)
    # Select closest two points to the selected value
    errs = @. abs(values - value)
    v, idx = findmin(errs)
    pt1, pt2 = LHs[idx]
    RisetimeMeasure(name, signal, transition_low, transition_high, low_threshold, high_threshold, transition, values, select, pt1, pt2, monotonicity, MeasureOptions(options))
end

"""
    FalltimeMeasure(transition; name="FalltimeMeasure", options...)
Measurement of risetime (`point2.x - point1.x`), of a signal
"""
struct FalltimeMeasure <: DxMeasure
    name::String
    signal
    transition_low::Threshold
    transition_high::Threshold
    low_threshold::Threshold
    high_threshold::Threshold
    transition::TransitionMeasure
    values::Vector{Float64}
    select::Function
    pt1::CrossMeasure
    pt2::CrossMeasure
    monotonicity::Float64
    options::MeasureOptions
end
function FalltimeMeasure(transition::TransitionMeasure;
                            signal=transition.crosses[1].signal,
                            name="FalltimeMeasure",
                            low_threshold=nothing,
                            high_threshold=nothing,
                            transition_low=nothing,
                            transition_high=nothing,
                            select=maximum,
                            monotonicity=transition.monotonicity,
                            options...)
    @assert all(cross -> cross.signal == signal, transition.crosses) "all crosses on a transition must be on the same signal"
    yths =  unique(map(cr -> cr.yth, filter(cr -> cr.yth isa falling, transition.crosses)))
    comma = ", "
    @assert length(yths) >= 2 "FalltimeMeasure: transition must have at least two rising crosses at different thresholds: found $(join(yths, comma))"
    if isnothing(low_threshold)
        if length(yths) <= 3
            low_threshold = yths[end]
        else
            low_threshold = yths[end-1]
        end
    end
    if isnothing(high_threshold)
        if length(yths) <= 3
            high_threshold = yths[begin]
        else
            high_threshold = yths[begin+1]
        end
    end
    LHs = each_low_high(transition, low_threshold, high_threshold)
    values = [l.x - h.x for (l, h) in LHs]
    if isnothing(transition_low)
        transition_low = first(filter_crosses_by_threshold(transition, low_threshold))
    end
    if isnothing(transition_high)
        transition_high = last(filter_crosses_by_threshold(transition, high_threshold))
    end
    ### Figure out which two points to use to represent the falltime:
    value = select(values)
    # Select closest two points to the selected value
    errs = @. abs(values - value)
    v, idx = findmin(errs)
    pt2, pt1 = LHs[idx]
    FalltimeMeasure(name, signal, transition_low, transition_high, low_threshold, high_threshold, transition, values, select, pt1, pt2, monotonicity, MeasureOptions(options))
end

function filter_crosses_by_threshold(crosses::Vector{CrossMeasure}, threshold::Threshold)
    filter(cr -> cr.yth == threshold, crosses)
end
function filter_crosses_by_threshold(m::TransitionMeasure, threshold::Threshold)
    filter_crosses_by_threshold(m.crosses, threshold)
end
function filter_crosses_by_threshold(m::Union{RisetimeMeasure,FalltimeMeasure}, threshold::Threshold)
    filter_crosses_by_threshold(m.transition, threshold)
end
function get_value(m::Union{RisetimeMeasure,FalltimeMeasure})
    m.select(m.values)
end
function each_low_high(m::TransitionMeasure, low_threshold::Threshold, high_threshold::Threshold)
    lows = filter_crosses_by_threshold(m, low_threshold)
    highs = filter_crosses_by_threshold(m, high_threshold)
    pairs = [(l, h) for h in highs for l in lows]
end
function each_low_high(m::Union{RisetimeMeasure,FalltimeMeasure})
    each_low_high(m.transition, m.low_threshold, m.high_threshold)
end
#Base.zero(m::RisetimeMeasure) = RisetimeMeasure(m.transition; m.name, m.options)
#Base.one(m::RisetimeMeasure) = RisetimeMeasure(zero(one(m.pt1)), one(m.pt2); m.name, m.options)
#Base.oneunit(m::RisetimeMeasure) = RisetimeMeasure(zero(m.pt1), oneunit(m.pt2); m.name, m.options)

# Fixme:
#Base.zero(m::FalltimeMeasure) = FalltimeMeasure(zero(m.pt1), zero(m.pt2); m.name, m.options)
#Base.one(m::FalltimeMeasure) = FalltimeMeasure(zero(one(m.pt1)), one(m.pt2); m.name, m.options)
#Base.oneunit(m::FalltimeMeasure) = FalltimeMeasure(zero(m.pt1), oneunit(m.pt2); m.name, m.options)


"""
    DyMeasure(point1, point2; options...)
Measurement of a difference (`point2.y - point1.y`) in two Y values (`peak2peak`, etc.)
"""
struct DyMeasure <: TwoPointMeasure
    name::String
    pt1
    pt2
    options::MeasureOptions
end
function DyMeasure(pt1::AbstractMeasure, pt2::AbstractMeasure; name="DyMeasure", options...)
    DyMeasure(name, pt1, pt2, MeasureOptions(options))
end
get_value(m::DyMeasure) = m.pt2.y - m.pt1.y # get_value(m.pt2) - get_value(m.pt1)
Base.zero(m::DyMeasure) = error("Error: not supported")
Base.one(m::DyMeasure) = error("Error: not supported")
Base.oneunit(m::DyMeasure) = error("Error: not supported")

function (Base.:-)(m2::YMeasure, m1::YMeasure)
    DyMeasure(m1, m2)
end

"""
    SlopeMeasure(point1, point2; options...)
Measurement the slope of two measures (slewrate, etc.)
"""
struct SlopeMeasure <: TwoPointMeasure
    name::String
    signal
    pt1 # First point
    pt2 # Second point
    options::MeasureOptions
end
function SlopeMeasure(pt1::AbstractMeasure, pt2::AbstractMeasure; signal=pt1.signal, name="SlopeMeasure", options...)
    SlopeMeasure(name, signal, pt1, pt2, MeasureOptions(options))
end
get_value(m::SlopeMeasure) = (m.pt2.y - m.pt1.y) / (m.pt2.x - m.pt1.x)
Base.zero(m::SlopeMeasure) = error("Error: not supported")
Base.one(m::SlopeMeasure) = error("Error: not supported")
Base.oneunit(m::SlopeMeasure) = error("Error: not supported")
function (Base.:/)(dy::DyMeasure, dx::DxMeasure)
    SlopeMeasure(dx.pt1, dx.pt2; dx.options)
end

"""
    RatioMeasure(meas1, meas2; options...)
Measurement of a ratio (`meas2.value / meas1.value`) in two measures.
"""
struct RatioMeasure <: TwoPointMeasure
    name::String
    pt1
    pt2
    options::MeasureOptions
end
function RatioMeasure(pt1::AbstractMeasure, pt2::AbstractMeasure; name="RatioMeasure", options...)
    RatioMeasure(name, pt1, pt2, MeasureOptions(options))
end
get_value(m::RatioMeasure) = m.pt2.value / m.pt1.value
Base.zero(m::RatioMeasure) = RatioMeasure(m.pt1, zero(m.pt2); m.name, m.options)
Base.one(m::RatioMeasure) = RatioMeasure(one(m.pt1), one(m.pt2); m.name, m.options)
Base.oneunit(m::RatioMeasure) = RatioMeasure(one(m.pt1), oneunit(m.pt2); m.name, m.options)

#function (Base.:/)(m2::AbstractMeasure, m1::AbstractMeasure)
#    RatioMeasure(m1, m2)
#end

struct PeriodMeasure <: DxMeasure
    name::String
    signal
    period_threshold::Threshold
    pt1
    pt2
    values
    select::Function
    options::MeasureOptions
    function PeriodMeasure(transition1::TransitionMeasure, transition2::TransitionMeasure;
                                name="PeriodMeasure", select=maximum,
                                transition_low, transition_high, period_threshold::Threshold,
                                signal=transition1.signal, options::MeasureOptions=MeasureOptions())
        if transition1.signal != transition2.signal
            error("All transitions must be on the same signal")
        end
        cross1 = filter_crosses_by_threshold(transition1, period_threshold)
        cross2 = filter_crosses_by_threshold(transition2, period_threshold)
        values = [c2 - c1 for c1 in cross1 for c2 in cross2]
        pt1s = [c1 for c1 in cross1 for c2 in cross2]
        pt2s = [c2 for c1 in cross1 for c2 in cross2]
        value = select(values)
        # If user passes in `mean` for select, then we need to find the closest two points to the mean
        idx = last(findmin(sortperm(values, by=x->abs(x-value))))
        pt1 = pt1s[idx]
        pt2 = pt2s[idx]
        new(name, signal, period_threshold, pt1, pt2, values, select, options)
    end
    function PeriodMeasure(pt1::CrossMeasure, pt2::CrossMeasure;
                                name="PeriodMeasure", select=maximum,
                                transition_low, transition_high, period_threshold::Threshold=pt1.yth,
                                signal=pt1.signal, options::MeasureOptions=MeasureOptions())
        if pt1.signal != pt2.signal
            error("All crosses must be on the same signal")
        end
        values = [pt2.x - pt1.x]
        new(name, signal, period_threshold, pt1, pt2, values, select, options)
    end
end
function get_value(m::PeriodMeasure)
    m.pt2.x - m.pt1.x
end
function clip(m::PeriodMeasure)
    signal=clip(m.signal, m.pt1.x .. m.pt2.x)
    PeriodMeasure(m.pt1, m.pt2; m.name, m.options, signal)
end

struct FrequencyMeasure <: DxMeasure
    name::String
    signal
    frequency_threshold::Threshold
    pt1
    pt2
    values
    select::Function
    options::MeasureOptions
    function FrequencyMeasure(transition1::TransitionMeasure, transition2::TransitionMeasure;
                                name="PeriodMeasure", select=maximum, frequency_threshold::Threshold,
                                signal=transition1.signal, options::MeasureOptions=MeasureOptions())
        if transition1.signal != transition2.signal
            error("All transitions must be on the same signal")
        end
        cross1 = filter_crosses_by_threshold(transition1, frequency_threshold)
        cross2 = filter_crosses_by_threshold(transition2, frequency_threshold)
        values = [1/(c2 - c1) for c1 in cross1 for c2 in cross2]
        pt1s = [c1 for c1 in cross1 for c2 in cross2]
        pt2s = [c2 for c1 in cross1 for c2 in cross2]
        value = select(values)
        # If user passes in `mean` for select, then we need to find the closest two points to the mean
        idx = last(findmin(sortperm(values, by=x->abs(x-value))))
        pt1 = pt1s[idx]
        pt2 = pt2s[idx]
        new(name, signal, frequency_threshold, pt1, pt2, values, select, options)
    end
    function FrequencyMeasure(pt1::CrossMeasure, pt2::CrossMeasure;
                                name="FrequencyMeasure", select=maximum, frequency_threshold::Threshold=pt1.yth,
                                signal=pt1.signal, options::MeasureOptions=MeasureOptions())
        if pt1.signal != pt2.signal
            error("All crosses must be on the same signal")
        end
        values = [1/(pt2.x - pt1.x)]
        new(name, signal, frequency_threshold, pt1, pt2, values, select, options)
    end
end
function FrequencyMeasure(m::PeriodMeasure; name="FrequencyMeasure")
    FrequencyMeasure(m.pt1, m.pt2; name, m.select, frequency_threshold=m.period_threshold, m.signal, m.options)
end
function get_value(m::FrequencyMeasure)
    1/(m.pt2.x - m.pt1.x)
end
function clip(m::FrequencyMeasure)
    signal = clip(m.signal, m.transition1.crosses[1].x .. m.transition2.crosses[end].x)
    FrequencyMeasure(m.pt1, m.pt2; m.name, m.select, m.frequency_threshold, signal, m.options)
end


"""
    inspect(x)
Inspect the object, such as a measurement, to show more information (for debugging).
"""
function inspect end