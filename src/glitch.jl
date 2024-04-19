abstract type TwoPointAreaMeasure <: TwoPointMeasure end
function plot_inspector_label(m::TwoPointAreaMeasure, prop::Symbol; midx::Int, show_index::Bool, sigdigits::Int=9)
    idxstr = show_index ? "[$midx]" : ""
    """
    $(typeof(m))$(idxstr) at $prop
    name: $(m.name)
    width: $(display_value(m.width; sigdigits))
    height: $(display_value(m.height; sigdigits))
    area: $(display_value(m.area; sigdigits))
    pt1.x: $(display_value(m.pt1.x; sigdigits))
    pt1.yth: $(display_value(m.pt1.yth; sigdigits))
    pt2.x: $(display_value(m.pt2.x; sigdigits))
    pt2.yth: $(display_value(m.pt2.yth; sigdigits))
    """
end
abstract type TwoPointHeightMeasure <: TwoPointAreaMeasure end
struct GlitchMeasure <: TwoPointAreaMeasure
    name::String
    "Clipped signal between the two points"
    signal::AbstractContinuousSignal
    "First crossing point with full signal"
    pt1::CrossMeasure
    "Second crossing point with full signal"
    pt2::CrossMeasure
    "Height of the glitch"
    height
    "Width of the glitch"
    width
    "Area of the glitch"
    area
    options::MeasureOptions
    function GlitchMeasure(signal::AbstractContinuousSignal, c1::CrossMeasure, c2::CrossMeasure; name="Glitch", options...)
        s = clip(signal, c1.x .. c2.x)
        g = s - (c1.y + c2.y)/2
        area = integral(g)
        height = peak2peak(g)
        width = c2.x - c1.x
        new(name, s, c1, c2, height, width, area, MeasureOptions(options))
    end
end
struct OvershootMeasure <: TwoPointHeightMeasure
    name::String
    "Clipped signal between the two points"
    signal::AbstractContinuousSignal
    "First crossing point with full signal"
    pt1::CrossMeasure
    "Second crossing point with full signal"
    pt2::CrossMeasure
    "Height of overshoot"
    height
    "Width of overshoot"
    width
    "Area of overshoot"
    area
    options::MeasureOptions
    function OvershootMeasure(signal::AbstractContinuousSignal, c1::CrossMeasure, c2::CrossMeasure; name="Overshoot", options...)
        y1 = signal(c1.x)
        y2 = signal(c2.x)
        s = clip(signal, c1.x .. c2.x)
        g = s - (c1.y + c2.y)/2
        area = integral(g)
        height = peak2peak(g)
        width = c2.x - c1.x
        new(name, s, c1, c2, height, width, area, MeasureOptions(options))
    end
end
struct UndershootMeasure <: TwoPointHeightMeasure
    name::String
    "Clipped signal between the two points"
    signal::AbstractContinuousSignal
    "First crossing point with full signal"
    pt1::CrossMeasure
    "Second crossing point with full signal"
    pt2::CrossMeasure
    "Height of undershoot"
    height
    "Width of undershoot"
    width
    "Area of undershoot"
    area
    options::MeasureOptions
    function UndershootMeasure(signal::AbstractContinuousSignal, c1::CrossMeasure, c2::CrossMeasure; name="Undershoot", options...)
        y1 = signal(c1.x)
        y2 = signal(c2.x)
        s = clip(signal, c1.x .. c2.x)
        area = integral(s - c1.y)
        height = peak2peak(s)
        width = c2.x - c1.x
        new(name, s, c1, c2, height, width, area, MeasureOptions(options))
    end
end
get_value(m::TwoPointAreaMeasure) = m.area
get_value(m::TwoPointHeightMeasure) = m.height
#Base.zero(m::GlitchMeasure) = GlitchMeasure(zero(m.pt1), zero(m.pt2); m.name, m.options)
#Base.one(m::GlitchMeasure) = GlitchMeasure(zero(one(m.pt1)), one(m.pt2); m.name, m.options)
#Base.oneunit(m::GlitchMeasure) = GlitchMeasure(zero(m.pt1), oneunit(m.pt2); m.name, m.options)


"""
    eachglitch(signal; supply_levels, full_swing_low_pct=0.1, full_swing_high_pct=1-full_swing_low_pct,
                glitch_max_height_low_pct=0.3, glitch_max_height_high_pct=1-glitch_max_height_low_pct)
    glitches(...)
    glitch(...)

Find glitches in a signal that cross cross a threshold and then return back to the supply.
If a signal transitions a full swing then it is not considered a glitch and ignored.
The glitch is defined as a signal that crosses the full swing threshold, then crosses
the glitch height threshold, and then reverses and crosses the same full swing threshold again,
not making a full transition.
Separate thresholds are used for the low and high side of the signal.
`supply_levels` are the reference levels and the other parameters are percentages of the full swing (`vdd - vss`).

# Variations
- `eachglitch`: returns an iterator of glitch measures
- `glitches`: returns a vector of glitch measures
- `glitch`: returns the first glitch measure

# Examples
```jldoctest
julia> s = PWL(0:4, [0, 0, 0.5, 0, 1]);

julia> meas = glitch(s, glitch_max_height_low_pct=0.3) # area of glitch
0.32
```
"""
function eachglitch(signal::AbstractContinuousSignal;
                        supply_levels=nothing,
                        full_swing_low_pct = 0.1,
                        full_swing_high_pct = 1-full_swing_low_pct,
                        glitch_max_height_low_pct = 0.3,
                        glitch_max_height_high_pct = 1-glitch_max_height_low_pct,
                    )
    full_swing_low, full_swing_high, glitch_max_height_low, glitch_max_height_high = rel2abs_thresholds(
        [full_swing_low_pct, full_swing_high_pct, glitch_max_height_low_pct, glitch_max_height_high_pct]; supply_levels, signal)
    low_crosses = eachcross(signal, [full_swing_low, glitch_max_height_low, full_swing_high])
    # Low side glitches:
    low_pattern = [
                ThresholdGroup([rising(full_swing_low)], 1),
                ThresholdGroup([either(glitch_max_height_low)], 1:100000),
                ThresholdGroup([falling(full_swing_low)], 1)
            ]

    low_glitches_thresholds = findall(low_crosses, low_pattern) |> collect
    lows = map(low_glitches_thresholds) do ths
        GlitchMeasure(signal, first(ths), last(ths))
    end
    # High side glitches:
    high_crosses = eachcross(signal, [full_swing_low, glitch_max_height_high, full_swing_high])
    high_pattern = [
                ThresholdGroup([falling(full_swing_high)], 1),
                ThresholdGroup([either(glitch_max_height_high)], 1:100000),
                ThresholdGroup([rising(full_swing_high)], 1)
            ]
    high_glitch_thresholds = findall(high_crosses, high_pattern) |> collect
    highs = map(high_glitch_thresholds) do ths
        GlitchMeasure(signal, first(ths), last(ths))
    end
    append!(lows, highs)
end
@signal_func eachglitch

function glitches(signal::AbstractContinuousSignal; kwargs...)
    collect(eachglitch(signal; kwargs...))
end
@doc (@doc eachglitch) glitches
@signal_func glitches

function glitch(signal::AbstractContinuousSignal; kwargs...)
    first(eachglitch(signal; kwargs...))
end
@doc (@doc eachglitch) glitch
@signal_func glitch

"""
    eachovershoot(signal; supply_levels, overshoot_pct=0.05)
    overshoots(...)
    overshoot(...)

Finds the overshoots in a signal which the signal goes above the fully level by more than `overshoot_pct`.

# Variations
- `eachovershoot`: returns an iterator of overshoot measures
- `overshoots`: returns a vector of overshoot measures
- `overshoot`: returns the first overshoot measure
"""
function eachovershoot(signal::AbstractContinuousSignal;
                        supply_levels,
                        overshoot_pct = 0.05,
                    )

    vdd, overshoot_high = rel2abs_thresholds([1, 1+overshoot_pct]; signal, supply_levels, check_percent_bounds=false)
    crosses = eachcross(signal, [vdd, overshoot_high])
    pattern = [
                ThresholdGroup(rising(vdd)),
                ThresholdGroup(either(overshoot_high), 1:100000),
                ThresholdGroup(falling(vdd))
            ]
    overshoot_thresholds = findall(crosses, pattern)
    sigs = map(overshoot_thresholds) do ths
        OvershootMeasure(signal, first(ths), last(ths))
    end
end
@signal_func eachovershoot

function overshoots(signal::AbstractContinuousSignal; kwargs...)
    collect(eachovershoot(signal; kwargs...))
end
@doc (@doc eachovershoot) overshoots
@signal_func overshoots

function overshoot(signal::AbstractContinuousSignal; kwargs...)
    first(eachovershoot(signal; kwargs...))
end
@doc (@doc eachovershoot) overshoot
@signal_func overshoot

"""
    eachundershoot(signal; supply_levels=nothing, overshoot_pct=0.05)
    undershoots(...)
    undershoot(...)
Finds the undershoots in a signal where the signal goes outside of the supply levels by more than `undershoot_pct`.

# Variations
- `eachundershoot`: returns an iterator of undershoot measures
- `undershoots`: returns a vector of undershoot measures
- `undershoot`: returns the first undershoot measure

"""
function eachundershoot(signal::AbstractContinuousSignal;
                        supply_levels,
                        undershoot_pct = 0.05,
                    )
    undershoot_low, vss = rel2abs_thresholds([-undershoot_pct, 0]; supply_levels, signal, check_percent_bounds=false)
    crosses = eachcross(signal, [undershoot_low, vss])
    pattern = [
                ThresholdGroup(falling(vss)),
                ThresholdGroup(either(undershoot_low), 1:100000),
                ThresholdGroup(rising(vss))
            ]
    undershoot_thresholds = findall(crosses, pattern)
    sigs = map(undershoot_thresholds) do ths
        UndershootMeasure(signal, first(ths), last(ths))
    end
end
@signal_func eachundershoot

function undershoots(signal::AbstractContinuousSignal; kwargs...)
    collect(eachundershoot(signal; kwargs...))
end
@doc (@doc eachundershoot) undershoots
@signal_func undershoots

function undershoot(signal::AbstractContinuousSignal; kwargs...)
    first(eachundershoot(signal; kwargs...))
end
@doc (@doc eachundershoot) undershoot
@signal_func undershoot
