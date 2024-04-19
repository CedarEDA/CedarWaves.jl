using IterTools: interleaveby, partition

function Interval(x1::CrossMeasure, x2::CrossMeasure)
    Interval(float(x1), float(x2))
end
function Interval(x1::CrossMeasure, x2::Real)
    Interval(float(x1), x2)
end
function Interval(x1::Real, x2::CrossMeasure)
    Interval(x1, float(x2))
end

"""
    ThresholdGroup(thresholds, repeat=1)

A specification for a possibly repeating set of threshold levels.
It takes a list of valid thresholds and a range of possible repetitions.

# Examples

```repl
ThresholdGroup(rising(0.5), 1:10) # rising edge at 0.5V repeated 1 to 10 times in a row

ThresholdGroup([rising(0.2), rising(0.8)], 1) # either rising 0.2 or 0.8

rise_pattern = [ThresholdGroup(rising(0.1*1.2)), ThresholdGroup(rising(0.9*1.2))] # Rising edge 10% to 90% of 1.2V

fall_pattern = [ThresholdGroup(falling(0.9*1.2)), ThresholdGroup(falling(0.1*1.2))] # Falling edge 90% to 10% of 1.2V

rf_pat = ThresholdGroup([rise_pattern, fall_pattern]) # rising or falling pattern
```
"""
struct ThresholdGroup
    thresholds::Set
    repeat::UnitRange{Int64}
    function ThresholdGroup(thresholds, repeat=1:1)
        if thresholds isa Threshold
            thresholds = [thresholds]
        end
        if repeat isa Int
            repeat = repeat:repeat
        end
        T = eltype(thresholds)
        new(Set(thresholds), repeat)
    end
end

function ThresholdGroup(thresholds, ::typeof(*))
    ThresholdGroup(thresholds, 0:typemax(Int64))
end

function ThresholdGroup(thresholds, ::typeof(+))
    ThresholdGroup(thresholds, 1:typemax(Int64))
end

Base.convert(::Type{ThresholdGroup}, threshold::Threshold) = ThresholdGroup(threshold)

"""
    match(signal, crosses, pattern)

Matches a signal segmented at the given points against a pattern of thresholds.
The pattern is matched at the start of crosses,
for matching a pattern anywhere see `find` and `findall`.
"""
function match(crosses, pattern::Vector{<:ThresholdGroup})
    rep = 1
    idx = 1
    res = eltype(crosses)[]
    for meas in crosses
        yth = meas.yth
        @label retry
        idx > length(pattern) && return res
        thgrp = pattern[idx]
        # the current threshold matches the pattern
        match = yth in thgrp.thresholds || either(yth) in thgrp.thresholds
        maxrep = rep <= last(thgrp.repeat)
        minrep = rep > first(thgrp.repeat)
        if match && maxrep
            # println("matched $yth $rep times")
            rep += 1
        elseif match && !maxrep
            # println("matched $yth but exchausted $rep, retry next")
            idx += 1
            rep = 1
            @goto retry
        elseif !match && minrep
            # println("$yth != $(thgrp.thresholds), but satisfied $(thgrp.repeat.start) times, retry next")
            idx += 1
            rep = 1
            @goto retry
        elseif !match && !minrep
            # println("$yth != $(thgrp.thresholds), not satisfied")
            return
        end
        push!(res, meas)
    end
    # println("done $idx $(length(pattern)), $rep $(last(pattern).repeat)")
    # we're at the last pattren and met the repeat requirement
    # or all the remaining patterns are optional
    if idx == length(pattern) && rep-1 in pattern[end].repeat ||
        all(x->x.repeat.start == 0, pattern[idx+1:end])
        res
    end
end

# We don't support fully generic recursive groups,
# but this handles at least the outer OR case
# See the either case of eachtransition for example usage
function match(crosses, pattern::ThresholdGroup)
    something((match(crosses, th) for th in pattern.thresholds)..., Some(nothing))
end

"""
    findall(crosses, pattern)

Find all matches of a pattern in a signal segmented at the given points.
Returns an iterator of matching crosses.

"""
function findall(crosses, pattern)
    res = Iterators.map(function((n, _),)
        seg = Iterators.drop(crosses, n-1)
        match(seg, pattern)
    end, Iterators.enumerate(crosses))
    fs = Iterators.filter(x -> x!==nothing, res)
    Iterators.map(Vector{CrossMeasure}, fs) # FIXME: is there a better way than this hack for type stability?
end
#function findall(crosses, pattern)
#    findall(crosses, convert(Vector{ThresholdGroup}, pattern))
#end

"""
    find(crosses, pattern)

Find the first match of a pattern in a signal segmented at the given points.
Returns the first matching segment.
"""
function find(crosses, pattern)
    first(findall(crosses, pattern))
end

# """
#     eachcrosspattern(signal, pattern; exclude=[])
#     crosspatterns(...)
#     crosspattern(...)
# Find crosses that match sequence of thresholds in a `pattern`.
# The return value is a Vector of CrossMeasure objects that match each pattern.
#
# #Variations
#     - `eachcrosspattern` returns a lazy iterator of a vector of `CrossMeasure` objects of the same length as the `pattern`.
#     - `crosspatterns` collects the `eachcrosspattern` results into a Vector of Vectors of `CrossMeasure` objects.
#     - `crosspattern` returns the first occurance of `eachcrosspattern` pattern match.
#
# For example to find rising edeges use `[rising(0.1), rising(1.1)]`.  This will find occurances
# of a rising edge from 0.1 to 1.1.
#
# The `exclude` argument is a list of extra thresholds
# which allows for more complex patterns by adding extra thresholds the pattern be specified to ignore the extra ones.
# For example, to find rising edges that do not fallback
# around 0.6V use `crosspattern(s, [rising(0.1), rising(1.1)], exclude=[falling(0.6)])` as this will not match
# a sequence of `[rising(0.1), falling(0.6), rising(1.1)]`.
#
# # Examples
#
# ```julia
# julia> ys = [0, 15, 0, 80, 100, 100, 80, 20, 80, 0, 0, 80, 20, 80, 100, 100, 80, 0, 15, 0];
#
# julia> xs = 1:length(ys);
#
# julia> s = PWL(xs, ys);
#
# julia> rising_transitions = crosspatterns(s, [rising(10), rising(90)])
# 2-element Vector{Vector{CrossMeasure}}:
#  [3.125, 4.5]
#  [11.125, 14.5]
#
# julia> falling_transitions = crosspatterns(s, [falling(90), falling(10)])
# 2-element Vector{Vector{CrossMeasure}}:
#  [6.5, 9.875]
#  [16.5, 17.875]
#
# julia> rising_transitions_fallback = crosspatterns(s, [rising(10), falling(50), rising(90)]) # match rising edges with fallback
# 1-element Vector{Vector{CrossMeasure}}:
#  [11.125, 12.5, 14.5]
#
# julia> falling_transitions_fallback = crosspatterns(s, [falling(90), rising(50), falling(10)]) # match falling edges with fallback
# 1-element Vector{Vector{CrossMeasure}}:
#  [6.5, 8.5, 9.875]
#
# julia> clean_falling_transitions = crosspatterns(s, [falling(90), falling(10)], exclude=rising(50))
# 1-element Vector{Vector{CrossMeasure}}:
#  [16.5, 17.875]
#
# julia> clean_rising_transitions = crosspatterns(s, [rising(10), rising(90)], exclude=falling(50))
# 1-element Vector{Vector{CrossMeasure}}:
#  [3.125, 4.5]
# ```
#
# See also
# [`eachcross`](@ref),
# [`crosses`](@ref),
# [`cross`](@ref),
# [`ThresholdGroup`](@ref).
# """
function eachcrosspattern(signal::AbstractSignal, pattern; exclude=[])
    pattern = convert(Vector{ThresholdGroup}, pattern)
    if !(exclude isa AbstractVector)
        exclude = [exclude]
    end
    exclude = convert(Vector{Threshold}, exclude)
    for p in pattern
        for t in p.thresholds
            push!(exclude, t)
        end
    end
    crosses = eachcross(signal, exclude)
    findall(crosses, pattern)
end
function crosspatterns(signal::AbstractSignal, pattern; exclude=[])
    collect(eachcrosspattern(signal, pattern; exclude=exclude))
end
@doc (@doc eachcrosspattern) crosspatterns

function crosspattern(signal::AbstractSignal, pattern; exclude=[])
    first(eachcrosspattern(signal, pattern; exclude=exclude))
end
@doc (@doc eachcrosspattern) crosspattern
@signal_func eachcrosspattern
@signal_func crosspatterns
@signal_func crosspattern

"""
    extract_supply_levels(signal)
Algorithmically determines the supply levels of a signal.  Currently it returns `(ymin, ymax)`
but in the future will take a histogram of the signal and return the two most common levels if it is
a strong bi-modal distribution and if not then return the ymin and ymax of the signal.

# Examples
```jldoctest
julia> s = PWL(0:3, [0, 0, 1.2, 1.2]);

julia> extract_supply_levels(s)
2-element Vector{Float64}:
 0.0
 1.2
```

See also
[`rel2abs_thresholds`](@ref),
[`eachtransition`](@ref),
[`transitions`](@ref),
[`risetimes`](@ref),
[`falltimes`](@ref),
[`slewrates`](@ref),
[`delays`](@ref).
"""
function extract_supply_levels(signal::AbstractSignal)
    lvls = collect(extrema(signal; trace=false))
    @assert length(lvls) > 1 "Must have more than one supply level ($(lvls)), is the signal a constant?"
    return lvls
end
@signal_func extract_supply_levels


"""
    rel2abs_thresholds(rel_thresholds; supply_levels=nothing, signal=nothing, check_percent_bounds=true)
Returns the absolute values (as real numbers) from a vector of relative percentages or thresholds.
If `supply_levels` is specified (as `(vss, vdd)`) then the absolute thresholds are calculated from their full scale.
Otherwise, if `signal` is provided then the supply levels are automatically extracted from the signal with `extract_supply_levels`.
By default the relative thresholds are checked to be between 0 and 1, but this can be disabled with `check_percent_bounds=false`.

# Examples
```julia
julia> rel2abs_thresholds([0.3, 0.5, 0.7], supply_levels=(0, 1.2))
3-element Vector{Float64}:
 0.36
 0.6
 0.84

julia> s = PWL(0:3, [0, 0, 1.2, 1.2]);

julia> rel2abs_thresholds([rising(0.3), falling(0.5), rising(0.7)], signal=s)
3-element Vector{Float64}:
 0.36
 0.6
 0.84
```

See also
[`extract_supply_levels`](@ref),
[`eachtransition`](@ref),
[`transitions`](@ref),
[`risetimes`](@ref),
[`falltimes`](@ref),
[`slewrates`](@ref),
[`delays`](@ref).
"""
function rel2abs_thresholds(rel_thresholds; supply_levels=nothing, signal=nothing, check_percent_bounds::Bool=true)
    if check_percent_bounds
        check_percents(rel_thresholds)
    end
    if isnothing(signal) && isnothing(supply_levels)
        throw(ArgumentError("rel2abs_thresholds: must specify either a `signal` or `supply_levels`"))
    end
    if !isnothing(supply_levels)
        if length(supply_levels) < 2
            throw(ArgumentError("rel2abs_thresholds: `supply_levels` must be of length 2 or more"))
        end
    end
    supply_levels = collect(@something(supply_levels, extract_supply_levels(signal)))
    vss = minimum(supply_levels)
    vdd = maximum(supply_levels)
    yth = rel_thresholds .* (vdd - vss) .+ vss
end

"""
    eachtransition(signal; supply_levels, dir=[rising|falling|either],
                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                        yths = rel2abs_thresholds([transition_low_pct, transition_high_pct]; supply_levels, signal),
                        name="TransitionMeasure")
    transitions(signal; kwargs...)
    transition(signal; kwargs...)

Finds the transitions in a `signal` that make a complete transition from `transition_low_pct`
to `transition_high_pct` (for `dir=rising`), or from `transition_high_pct` to `transition_low_pct`
(for `dir=falling`), or in either direction with `dir=either`.
The thresholds are percentages of the full swing supply levels, typically `supply_levels=(vss, vdd)` , so `0.5` is mid rail.
The thresholds by default are provided in percentages:
- `transition_low_pct`: the lower threshold (default 0.1)
- `transition_high_pct`: the upper threshold (default 0.9)
Optionally, the thresholds can be provided as absolute values by using `yths` instead of `transition_low_pct` and `transition_high_pct`,
such as `yths=[0.2, 1.6]` for 0.2 and 1.6 (Volts).

# Variations
- `eachtransition` returns a lazy iterator of TransistionMeasure objects that contain the threshold measures.
- `transitions` returns an eager collection of transitions
- `transition` returns the first transition

# Examples


See also
[`rel2abs_thresholds`](@ref),
[`risetimes`](@ref),
[`falltimes`](@ref),
[`transitions`](@ref),
[`slewrates`](@ref),
[`delays`](@ref).
"""
function eachtransition(signal::AbstractSignal; supply_levels=nothing, dir=either,
                           transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                           name="TransitionMeasure",
                           yths = rel2abs_thresholds([transition_low_pct, transition_high_pct]; supply_levels, signal))
    check_percents(; transition_low_pct, transition_high_pct)
    crosses = eachcross(signal, yths)
    rising_pattern = [
        ThresholdGroup(rising(yths[begin])),
        ThresholdGroup(either.(yths[begin+1:end-1]), *),
        ThresholdGroup(rising(yths[end])),
    ]
    falling_pattern = [
        ThresholdGroup(falling(yths[end])),
        ThresholdGroup(either.(yths[begin+1:end-1]), *),
        ThresholdGroup(falling(yths[begin])),
    ]
    matches = if dir == rising
        findall(crosses, rising_pattern)
    elseif dir == falling
        findall(crosses, falling_pattern)
    else
        findall(crosses, ThresholdGroup([rising_pattern, falling_pattern]))
    end

    # Return transition objects
    Iterators.map(matches) do crosses
        TransitionMeasure(crosses; name)
    end
end
@signal_func eachtransition

function transitions(signal::AbstractSignal; kwargs...)
    collect(eachtransition(signal; kwargs...))
end
@doc (@doc eachtransition) transitions
@signal_func transitions

function transition(signal::AbstractSignal; kwargs...)
    first(eachtransition(signal; kwargs...))
end
@doc (@doc eachtransition) transition
@signal_func transition

"""
    eachrisetime(signal; supply_levels, select=maximum,
                        risetime_low_pct=0.2, risetime_high_pct=1-risetime_low_pct,
                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                        yths = rel2abs_thresholds([transition_low_pct, risetime_low_pct, risetime_high_pct, transition_high_pct]; supply_levels, signal),
                        name="risetime",
                        options...)
    risetimes(...)
    risetime(...)

Returns risetime measurements of a signal, `signal`.
A rising edge is determined by a rising crossing at `transition_low_pct` and `transition_high_pct` thresholds.
The measurement is done at the `risetime_low_pct` and `risetime_high_pct` thresholds.
This provides robustness to ensure a full transition happens when measuring risetime at thresholds that are not
close to the rails.
The percent values are between 0 and 1 and are converted to absolute values by `rel2abs_thresholds`.
To pass in absolute values directly use `risetime(signal, yths=[0.4, 0.6, 1.2, 1.6])`
In the event of fallback around the risetime low/high thresholds there can be multiple risetime measurements.
The `monotonicity` property of the risetime can be used to check for fallback.
The `select` function reduces the multiple crossings to 1 and by default it takes the `maximum`.

# Variations:

- `eachrisetime` returns a lazy iterator
- `risetimes` returns an eager collection of risetimes
- `risetime` returns the first risetime

# Options

- `sigdigits`: the number of sigdigits to display (default $(MEASURE_DEFAULTS[:sigdigits]))

# Examples

```@repl
t = 0:0.005:1
freq = 2
y = @. 0.5*(1 + sin(2pi*freq*t) + 1/3*sin(2pi*freq*3t) + 1/5*sin(2pi*freq*5t));
s = PWL(t, y)
rt1 = risetime(s) # default is 20% to 80%
rt2 = risetime(s, risetime_low_pct=0.3) # 30% to 70%
rt3 = risetime(s, yths=[0.1, 0.3, 1.5, 1.7]) # absolute values
```

In addition the risetime measure object returned acts as its value when used in a mathematical expression:

```@repl
rt1/2
```

See also
[`rel2abs_thresholds`](@ref),
[`falltimes`](@ref),
[`transitions`](@ref),
[`slewrates`](@ref),
[`delays`](@ref).
"""
function eachrisetime(signal::AbstractSignal; supply_levels=nothing,
                        risetime_low_pct=0.2, risetime_high_pct=1-risetime_low_pct,
                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                        yths = rel2abs_thresholds([transition_low_pct, risetime_low_pct, risetime_high_pct, transition_high_pct]; supply_levels, signal),
                        select=maximum,
                        name="risetime",
                        trace::Bool=true, options...
                        )
    check_percents(; risetime_low_pct, risetime_high_pct, transition_low_pct, transition_high_pct)
    trs = eachtransition(signal; dir=rising, yths, name)
    Iterators.map(trs) do tr
        meas = RisetimeMeasure(tr; name, select,
                            transition_low = rising(first(yths)),
                            transition_high = rising(last(yths)),
                            low_threshold = rising(yths[length(yths)<=3 ? 1 : 2]),
                            high_threshold = rising(yths[length(yths)<=3 ? length(yths) : length(yths)-1]),
                            options...)
        if trace
            meas
        else
            meas.value
        end
    end
end
function risetimes(signal::AbstractSignal; kwargs...)
    collect(eachrisetime(signal; kwargs...))
end
@doc (@doc eachrisetime) risetimes

function risetime(signal::AbstractSignal; kwargs...)
    first(eachrisetime(signal; kwargs...))
end
@doc (@doc eachrisetime) risetime
@signal_func eachrisetime
@signal_func risetimes
@signal_func risetime

"""
    eachfalltime(signal; supply_levels, select=maximum,
                        falltime_low_pct=0.2, falltime_high_pct=1-falltime_low_pct,
                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                        yths = rel2abs_thresholds([transition_low_pct, risetime_low_pct, risetime_high_pct, transition_high_pct]; supply_levels, signal),
                        name="falltime",
                        options...)
    falltimes(...)
    falltime(...)

Returns falltime measurements of a signal, `signal`.
A falling edge is determined by a falling crossing at `transition_low_pct` and `transition_high_pct`.
The falltime is measured by the falling crossings at `falltime_low_pct` and `falltime_high_pct`.
In the event of fallback around the falltime low and high thresholds there can be multiple falltime measurements
since which crossing to use is ambiguous.  The `select` function reduces the multiple crossings to 1 and by default
it takes the `maximum`.

# Variations:

- `eachfalltime` returns a lazy iterator
- `falltimes` returns an eager collection of falltimes
- `falltime` returns the first falltime

# Options

- `sigdigits`: the number of sigdigits to display (default $(MEASURE_DEFAULTS[:sigdigits]))

# Examples

```@repl
t = 0:0.005:1
freq = 2
y = @. 0.5*(1 + sin(2pi*freq*t) + 1/3*sin(2pi*freq*3t) + 1/5*sin(2pi*freq*5t));
s = PWL(t, y)
meas = falltime(s)
ft1 = falltime(s) # default is 20% to 80%
ft2 = falltime(s, risetime_low_pct=0.3) # 30% to 70%
ft3 = falltime(s, yths=[0.1, 0.3, 1.5, 1.7]) # absolute values
```

In addition the falltime measure object returned acts as its value when used in a mathematical expression:

```@repl
ft1/2
```

See also
[`risetimes`](@ref),
[`transitions`](@ref),
[`slewrates`](@ref),
[`delays`](@ref).
"""
function eachfalltime(signal::AbstractSignal; supply_levels=nothing,
                            falltime_low_pct=0.2, falltime_high_pct=1-falltime_low_pct,
                            transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                            select=maximum,
                            yths = rel2abs_thresholds([transition_low_pct, falltime_low_pct, falltime_high_pct, transition_high_pct]; supply_levels, signal),
                            trace::Bool=true,
                            name="falltime", options...
                        )
    check_percents(; falltime_low_pct, falltime_high_pct, transition_low_pct, transition_high_pct)
    yths = sort(yths)
    trs = transitions(signal; dir=falling, yths, name)
    Iterators.map(trs) do tr
        meas = FalltimeMeasure(tr; name, select,
                            transition_low = falling(first(yths)),
                            transition_high = falling(last(yths)),
                            low_threshold = falling(yths[length(yths)<=3 ? 1 : 2]),
                            high_threshold = falling(yths[length(yths)<=3 ? length(yths) : length(yths)-1]),
                            options...)
        if trace
            return meas
        else
            return meas.value
        end
    end
end
@signal_func eachfalltime

function falltimes(signal::AbstractSignal; kwargs...)
    collect(eachfalltime(signal; kwargs...))
end
@doc (@doc eachfalltime) falltimes
@signal_func falltimes

function falltime(signal::AbstractSignal; kwargss...)
    first(eachfalltime(signal; kwargss...))
end
@doc (@doc eachfalltime) falltime
@signal_func falltime

function transitions_to_periods(trs::Vector{TransitionMeasure}; name, transition_low, transition_high, period_threshold)
    if length(trs) == 0
        return PeriodMeasure[]
    end
    _, trs2 = Iterators.peel(trs)
    pairs = Iterators.zip(trs, trs2)
    Iterators.map(pairs) do pr
        a = pr[1]
        b = pr[2]
        # FIXME: for fallback cases this should return multiple periods for each combination of crosses
        PeriodMeasure(a, b; name, transition_low, transition_high, period_threshold)
    end
end

"""
    eachperiod(signal; supply_levels, dir=rising, period_pct=0.5,
                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                        name="PeriodMeasure")
    periods(signal; kwargs...)
    period(signal; kwargs...)

Returns the periods of signal from edge to edge of the `signal`.
The default edge is from rising to rising (`dir=rising`) but can be changed to
falling to falling (`dir=falling`) or both with (`dir=either`).

# Variations

- `eachperiod` returns a lazy iterator of periods
- `periods` returns an eager collection of periods
- `period` returns the first period

# Examples

```julia
julia> s = PWL(0:15, repeat([0, 100, 100, 0, 0, 100, 100, 0], outer=2));

julia> ps = periods(s)
3-element Vector{PeriodMeasure}:
 4
 4
 4

julia> inspect(ps);

See also
[`rel2abs_thresholds`](@ref),
[`periods`](@ref),
[`risetimes`](@ref),
[`falltimes`](@ref),
[`transitions`](@ref),
[`slewrates`](@ref),
[`delays`](@ref).
```
"""
function eachperiod(signal::AbstractSignal; supply_levels=nothing, dir=rising,
                            period_pct=0.5,
                            transition_low_pct=0.1,
                            transition_high_pct=1-transition_low_pct,
                            yths = rel2abs_thresholds([transition_low_pct, period_pct, transition_high_pct]; signal, supply_levels),
                            name="PeriodMeasure")
    if length(yths) != 3
        throw(ArgumentErorr("eachperiod: `yths` must be a vector of length 3"))
    end
    transition_low, period_threshold, transition_high = yths
    if dir != falling
        period_threshold = rising(period_threshold)
        rising_trs = transitions(signal; dir=rising, yths) #FIXME: use eachtransition
        rising_periods = transitions_to_periods(rising_trs; name, transition_low, transition_high, period_threshold)
        ps = rising_periods
    end
    if dir != rising
        period_threshold = falling(period_threshold)
        falling_trs = transitions(signal; dir=falling, yths)
        falling_periods = transitions_to_periods(falling_trs; name, transition_low, transition_high, period_threshold)
        ps = falling_periods
    end
    if dir == either
        ps = interleaveby((r, f) -> r.pt2 < f.pt1, rising_periods, falling_periods)
    end
    return ps
end
@signal_func eachperiod

function periods(signal::AbstractSignal; kwargs...)
    collect(eachperiod(signal; kwargs...))
end
@doc (@doc eachperiod) periods
@signal_func periods

function period(signal::AbstractSignal; kwargs...)
    first(eachperiod(signal; kwargs...))
end
@doc (@doc eachperiod) period
@signal_func period

"""
    eachfrequency(signal; supply_levels=nothing, dir=rising, frequency_pct=0.5,
                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                        name="FrequencyMeasure")
    frequencies(...)
    frequency(...)
Returns the two-point frequency of a signal, measured at the first two full transitions
by `signal` from `transition_low_pct` to `transition_high_pct`.  The frequency is measured
at the reference level defined by `frequency_pct` (default is 0.5 which is the midpoint of the `supply_levels`).
The default edge is from rising to rising (`dir=rising`) but can be changed to
falling to falling (`dir=falling`) or both with (`dir=either`).

# Examples

```julia
t = 0:0.005:2
freq = 2
y = @. 0.5*(1 + sin(2pi*freq*t) + 1/3*sin(2pi*freq*3t) + 1/5*sin(2pi*freq*5t));
s = PWL(t, y)
meas = frequency(s)
```

See also
[`rel2abs_thresholds`](@ref),
[`periods`](@ref),
[`risetimes`](@ref),
[`falltimes`](@ref),
[`transitions`](@ref),
[`slewrates`](@ref),
[`delays`](@ref).
"""
function eachfrequency(signal::AbstractSignal; supply_levels=nothing, dir=rising, frequency_pct=0.5,
                            transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                            yths = rel2abs_thresholds([transition_low_pct, frequency_pct, transition_high_pct]; supply_levels, signal),
                            name="FrequencyMeasure")
    pers = eachperiod(signal; yths, dir, name)
    Iterators.map(pers) do per
        FrequencyMeasure(per)
    end
end
@signal_func eachfrequency

function frequencies(signal::AbstractSignal; kwargs...)
    collect(eachfrequency(signal; kwargs...))
end
@doc (@doc eachfrequency) frequencies
@signal_func frequencies

function frequency(signal::AbstractSignal; kwargs...)
    first(eachfrequency(signal; kwargs...))
end
@doc (@doc eachfrechency) frequency
@signal_func frequency

"""
    eachslewrate(signal; supply_levels, dir=[rising|falling|either],
                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                        name="SlewRateMeasure")
    slewrate(signal; kwargs...)
    slew(signal; kwargs...)
Returns a slewrate measurement of a signal, `signal`.

# Options
- `name`: the name of the measure
- `sigdigits`: the number of sigdigits to display

# Examples

```julia
t = 0:0.005:1
freq = 2
y = @. 0.5*(1 + sin(2pi*freq*t) + 1/3*sin(2pi*freq*3t) + 1/5*sin(2pi*freq*5t));
s = PWL(t, y)
meas = slewrate(s)
meas.dy/meas.dx
```

In addition the slewrate measure object returned acts as its value when used in a mathematical expression:

```julia
meas/2
```

See also
[`risetimes`](@ref),
[`falltimes`](@ref),
[`transitions`](@ref),
[`frequencies`](@ref),
[`periods`](@ref),
[`delays`](@ref).
"""
function eachslewrate(signal::AbstractSignal; supply_levels=nothing, dir=rising, name="slewrate",
                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                        risetime_low_pct=0.2, risetime_high_pct=1-risetime_low_pct,
                        falltime_low_pct=risetime_low_pct,
                        falltime_high_pct=1-risetime_low_pct)
    yths_rise = rel2abs_thresholds([transition_low_pct, risetime_low_pct, risetime_high_pct, transition_high_pct]; supply_levels, signal)
    yths_fall = rel2abs_thresholds([transition_low_pct, falltime_low_pct, falltime_high_pct, transition_high_pct]; supply_levels, signal)
    if dir != rising
        falling_trs = transitions(signal; yths=yths_fall, dir=falling)
        trs = falling_trs
    end
    if dir != falling
        rising_trs = transitions(signal; dir=rising, yths=yths_rise)

        trs = rising_trs
    end
    if dir == either
        trs = interleaveby((r, f) -> r.crosses[1] < f.crosses[1], rising_trs, falling_trs)
    end
    Iterators.map(trs) do tr
        SlopeMeasure(tr.crosses[begin+1], tr.crosses[end-1]; name)
    end
end
@signal_func eachslewrate

function slewrates(signal::AbstractSignal; kwargs...)
    collect(eachslewrate(signal; kwargs...))
end
@doc (@doc eachslewrate) slewrates
@signal_func slewrates

function slewrate(signal::AbstractSignal; kwargs...)
    first(eachslewrate(signal; kwargs...))
end
@doc (@doc eachslewrate) slewrate
@signal_func slewrate


#"""
#    eachperioddelay(signal; supply_levels, dir=[rising|falling|either], period_pct=0.5,
#                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
#                        name="PeriodMeasure")
#    perioddelays(signal; kwargs...)
#    perioddelay(signal; kwargs...)
#"""

"""
    BandwidthMeasure(point1, point2; response=:lowpass, name="BandwidthMeasure", options...)
Measurment of the bandwidth of a signal (`point2.x - point1.x`).

The returned BandwidthMeasure object has the following properties:
- `name`: the name of the measurement
- `response`: is either `:lowpass`, `:highpass`, `:bandpass`, or `:bandreject` (default is `:lowpass`)
- `yth`: the threshold used to find the crossing points
- `pt1`: the crossing point of the first Threshold
- `pt2`: the crossing point of the second Threshold
- `value`: this is the bandwidth of the signal (`pt2.x - pt1.x`)
"""
struct BandwidthMeasure <: DxMeasure
    name::String
    response::Symbol
    select::Function
    pt1
    pt2
    options::MeasureOptions
end
function BandwidthMeasure(pt1::AbstractMeasure, pt2::AbstractMeasure; response=:lowpass, select=maximum, name="BandwidthMeasure", options...)
    BandwidthMeasure(name, response, select, pt1, pt2, MeasureOptions(options))
end
get_value(m::BandwidthMeasure) = m.pt2.x - m.pt1.x
Base.zero(m::BandwidthMeasure) = BandwidthMeasure(zero(m.pt1), zero(m.pt2); m.name, m.response, m.options)
Base.one(m::BandwidthMeasure) = BandwidthMeasure(zero(one(m.pt1)), one(m.pt2); m.name, m.response, m.options)
Base.oneunit(m::BandwidthMeasure) = BandwidthMeasure(zero(m.pt1), oneunit(m.pt2); m.name, m.response, m.options)


"""
    bandwidth(signal, yth; response=:lowpass, name=response, select=minimim, options...)
Returns the bandwidth of a frequency-domain `signal`.
If the y-values of the signal are complex then it will be converted to magnitude.
The `yth` will be automatically converted to `rising` or `falling` depending
on the filter `response` type.
The `yth` is threshold in same units as `signal`, not a drop from the maximum.
If multiple crossings are found then the `select` function is used to select the one to use.

The following types of `response` filter responses are supported:
- `:lowpass`: a lowpass filter with exactly one falling edge (Default)
- `:highpass`: a highpass filter with exactly one rising edge
- `:bandpass`: a bandpass filter with exactly one rising edge followed by exactly one falling edge
- `:bandreject`: a notch filter with exactly one falling edge followed by exactly one rising edge

# Examples

To get 3dB bandwidth use:
```julia
# if `signal` is in dB:
bandwidth(signal, ymax(signal) - 3, response=:lowpass)

# if `signal` is in linear units:
bandwidth(signal, ymax(signal)/2, response=:lowpass)
```
"""
function bandwidth(signal::AbstractSignal, yth; response::Symbol=:lowpass,
                                                name=string(response),
                                                select=minimum, options...)
    s = signal
    if ytype(s) <: Complex
        s = abs(s)
    end
    rises = crosses(s, rising(yth); name, options...)
    falls = crosses(s, falling(yth); name, options...)
    if response == :lowpass
        if length(falls) == 0
            pt1 = pt2 = CrossMeasure(s, NaN, falling(yth))
            return BandwidthMeasure(pt1, pt2; response, select, options)
        end
        val = select(falls)
        idx = findfirst(==(val), falls)
        if isnothing(idx)
            pt1 = pt2 = CrossMeasure(s, NaN, falling(yth))
            return BandwidthMeasure(s, pt1, pt2; response, select, options)
        end
        pt1 = XMeasure(s, xmin(s))
        pt2 = falls[idx]
        return BandwidthMeasure(pt1, pt2; response, select, options)
    elseif response == :highpass
        if length(rises) == 0
            pt1 = pt2 = CrossMeasure(s, NaN, rising(yth))
            return BandwidthMeasure(pt1, pt2; response, select, options)
        end
        val = select(rises)
        idx = findfirst(==(val), rises)
        if isnothing(idx)
            pt1 = pt2 = CrossMeasure(s, NaN, rising(yth))
            return BandwidthMeasure(pt1, pt2; response, select, options)
        end
        pt1 = rises[idx]
        pt2 = XMeasure(s, xmax(s))
        return BandwidthMeasure(pt1, pt2; response, select, options)
    elseif response == :bandpass
        combos = [f - r for r in rises, f in falls]
        if length(combos) == 0
            pt1 = CrossMeasure(s, NaN, falling(yth))
            pt2 = CrossMeasure(s, NaN, rising(yth))
            return BandwidthMeasure(pt1, pt2; response, select, options)
        end
        val = select(combos)
        idx = findfirst(==(val), combos)
        if isnothing(idx)
            pt1 = CrossMeasure(s, NaN, falling(yth))
            pt2 = CrossMeasure(s, NaN, rising(yth))
            return BandwidthMeasure(pt1, pt2; response, select, options)
        end
        idxrise = idx[1]
        idxfall = idx[2]
        pt1 = rises[idxrise]
        pt2 = falls[idxfall]
        return BandwidthMeasure(pt1, pt2; response, select, options)
    elseif response == :bandreject
        combos = [f - r for r in rises, f in falls]
        if length(combos) == 0
            pt1 = CrossMeasure(s, NaN, rising(yth))
            pt2 = CrossMeasure(s, NaN, falling(yth))
            return BandwidthMeasure(pt1, pt2; response, select, options)
        end
        val = select(combos)
        idx = findfirst(==(val), combos)
        if isnothing(idx)
            pt1 = CrossMeasure(s, NaN, rising(yth))
            pt2 = CrossMeasure(s, NaN, falling(yth))
            return BandwidthMeasure(pt1, pt2; response, select, options)
        end
        idxrise = idx[1]
        idxfall = idx[2]
        pt1 = falls[idxfall]
        pt2 = rises[idxrise]
        return BandwidthMeasure(pt1, pt2; response, select, options)
    end
    throw(ArgumentError("`response=$response` must be one of :lowpass, :highpass, :bandpass, :bandreject"))
end
@signal_func bandwidth

function plot_inspector_label(m::BandwidthMeasure, prop::Symbol; midx, show_index::Bool, sigdigits::Int=9)
    idxstr = show_index ? idx2str(midx) : ""
    """
    $(typeof(m))$(idxstr) at $prop
    name: $(m.name)
    response: $(m.response)
    select: $(m.select)
    dx: $(display_value(m.dx; sigdigits))
    pt1.x: $(display_value(m.pt1.x; sigdigits))
    pt1.y: $(display_value(m.pt1.y))
    pt2.x: $(display_value(m.pt2.x; sigdigits))
    pt2.y: $(display_value(m.pt2.y))
    """
end
