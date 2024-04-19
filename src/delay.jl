
"""
    eachdelay(signal1, signal2; supply_levels, dir1=rising, dir2=rising,
                        delay_yth1_pct=0.5, delay_yth2_pct=delay_yth1_pct,
                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct,
                        name="delay", options...)
    delays(signal1, signal2; kwargs...)
    delay(signal1, signal2; kwargs...)
Returns a delay measurement of a `signal1` in the `dir1` direction crossing `delay_yth1_pct` to the
`dir2` crossing direction of `signal2` at `delay_yth2_pct` threshold.

# Arguments

- `signal1`: the signal to measure the start of the delay
- `signal2`: the signal to measure the end of the delay
- `supply_levels`: the supply levels in a list, like `(vss, vdd)`. If not provided they will be infered from the input signals.
- `delay_yth1_pct`: the y-values in percent of `supply_levels` at which to look for the first crossing.
- `delay_yth2_pct`: the y-values in percent of `supply_levels` at which to look for the second crossing.
- `dir1`: the direction to look for the first crossing (default `rising`)
- `dir2`: the direction to look for the second crossing (default `rising`)
- `transition_low_pct`: the lower threshold (default 0.1) to determine a transition to measure delay
- `transition_high_pct`: the upper threshold (default `1- transition_low_pct`) to determine a transition to measure delay
- `name`: the name of the measure (default `delay`)
- `sigdigits`: the number of sigdigits to display

The delay measurement is an object containing the plot of the delay as well as
attributes for measurements related to delay, such as:
- `name`: the name of the measurement
- `value`: the value of the delay measurement
- `pt1`: the crossing of the first signal that was measured
- `pt2`: the crossing of the second signal that was measured
- `dx`: the delay time (`pt2.x - pt1.x`) -- same as `value`
- `dy`: the vertical change (`pt2.y - pt1.y`)
- `slope`: the slew rate (`dy/dx`)

The properties can be accessed as properties like `meas.dx` to get the transition time.

# Examples

```jldoctest
julia> t = 0:0.005:1
0.0:0.005:1.0

julia> freq = 2
2

julia> y = @. 0.5*(1 + sin(2pi*freq*t) + 1/3*sin(2pi*freq*3t) + 1/5*sin(2pi*freq*5t));

julia> s1 = PWL(t, y);

julia> s2 = 1 - s1;

julia> meas = delay(s2, s1)
0.25

julia> round(meas.pt1.x, sigdigits=3)
0.25

julia> round(meas.pt2.x, sigdigits=3)
0.5

julia> meas/2
0.125
```

See also
[`risetime`](@ref),
[`falltime`](@ref),
[`slewrate`](@ref),
[`period`](@ref),
[`frequency`](@ref).
"""
function eachdelay(signal1::AbstractSignal, signal2::AbstractSignal; supply_levels=nothing, dir1=rising, dir2=rising,
                        delay_yth1_pct=0.5, delay_yth2_pct=delay_yth1_pct,
                        transition_low_pct=0.1, transition_high_pct=1-transition_low_pct, name="delay", options...)
    #@assert signal1 !== signal2 "For delay, signals must not be the same" # should this be true?
    yths1 = rel2abs_thresholds([transition_low_pct, delay_yth1_pct, transition_high_pct]; supply_levels, signal=signal1)
    yths2 = rel2abs_thresholds([transition_low_pct, delay_yth2_pct, transition_high_pct]; supply_levels, signal=signal2)
    trs1 = eachtransition(signal1; dir=dir1, yths=yths1) |> collect
    trs2 = eachtransition(signal2; dir=dir2, yths=yths2) |> collect

    function closest_transitions(trs1::Vector{T}, trs2::Vector{T}) where {T}
        matched_transitions = Pair{T,T}[]
        length(trs1) == 0 && return matched_transitions
        # Find a match in trs1 for every transition in trs2.
        # We assume here that `trs2` is the "output", and that
        # every transition of the output must be matched with a
        # transition in the input, but some input transitions
        # may not have a matching output transition (e.g. ignored
        # clock pulses).  This is quite an assumption.
        earlier_idx = 1
        earlier_tr = trs1[earlier_idx]
        for later_idx in 1:length(trs2)
            # Find the first `earlier_idx` that fails the `is_earlier()` check:
            is_earlier(earlier_idx, later_idx) = trs1[earlier_idx].crosses[1].x <= trs2[later_idx].crosses[1].x
            while earlier_idx < length(trs1) && is_earlier(earlier_idx, later_idx)
                earlier_idx += 1
            end

            # Ending edge condition; we failed out of the `while` loop due to `earlier_idx >= length(trs1)`
            if is_earlier(earlier_idx, later_idx)
                push!(matched_transitions, trs1[earlier_idx] => trs2[later_idx])
            # Typical condition
            elseif earlier_idx > 1 && is_earlier(earlier_idx-1, later_idx)
                push!(matched_transitions, trs1[earlier_idx-1] => trs2[later_idx])
            end
        end
        return matched_transitions
    end
    Iterators.map(
        tr12 -> DelayMeasure(tr12[1], tr12[2]; name, options...),
        closest_transitions(trs1, trs2),
    )
end

function delays(signal1::AbstractSignal, signal2::AbstractSignal, args...; kwargs...)
    collect(eachdelay(signal1, signal2, args...; kwargs...))
end
@doc (@doc eachdelay) delays

function delay(signal1::AbstractSignal, signal2::AbstractSignal, args...; kwargs...)
    first(eachdelay(signal1, signal2, args...; kwargs...))
end
@doc (@doc eachdelay) delay

@signal_func eachdelay
@signal_func delays
@signal_func delay

@testitem "delay" begin
    #using .CedarWaves, Test
    q = PWL([0.0, 1.0, 1.1, 2.0, 2.1, 3.0, 3.1, 4.0, 4.1, 5.0],
            [0.7, 0.7, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0])
    clk = PWL([0.0, 0.5, 0.6, 1.5, 1.6, 2.5, 2.6, 3.5, 3.6, 5.0],
              [1.0, 1.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0])
    @test delays(clk, q, dir1=falling, dir2=rising, supply_levels=[0, 1]) ≈ [1.5, 1.5]
    @test delays(clk, q, dir1=rising, dir2=rising, supply_levels=[0, 1]) ≈ [0.5, 0.5]
    @test delays(clk, q, dir1=rising, dir2=falling, supply_levels=[0, 1]) ≈ [1.5]
    @test delays(clk, q, dir1=falling, dir2=falling, supply_levels=[0, 1]) ≈ [0.5]
    @test delays(clk, q, dir1=either, dir2=either, supply_levels=[0, 1]) ≈ [0.5, 0.5, 0.5]
    @test delays(clk, q, dir1=either, dir2=rising, supply_levels=[0, 1]) ≈ [0.5, 0.5]
    @test delays(clk, q, dir1=either, dir2=falling, supply_levels=[0, 1]) ≈ [0.5]
    @test delays(clk, q, dir1=rising, dir2=either, supply_levels=[0, 1]) ≈ [0.5]


    # Corner cases:
    q = PWL([0.0, 1.0, 1.1, 2.0, 2.1, 3.0, 3.1, 4.0, 4.1, 5.0],
            [0.7, 0.7, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0])
    clk = PWL([0.0, 0.5, 0.6, 1.5, 1.6, 2.5, 2.6, 3.5, 3.6, 5.0],
              [0.6, 0.6, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 1.0, 1.0])
    d2s = delays(clk, q, dir1=falling, dir2=rising, supply_levels=[0, 1])
    @test length(d2s) == 1
    d2 = only(d2s)
    @test d2 ≈ 1.5
    @test d2.pt1.x ≈ 2.55
    @test d2.pt2.x ≈ 4.05

end

@testitem "trying to reproduce missing variable" begin
    a = Iterators.flatten(([1, 2],
                           [3, 4]))
    b = Iterators.flatten(([2, 3],
                           [4, 5]))
    c = a .* b
    y = 1
    @test length(c) == 4
end