"""
    monotonicity(signal[, rising | falling | either])
    monotonicity(vector[, rising | falling | either])
Return the percentage of time that the signal is monotonic (not reversing back on itself).
`rising` check for monononically increasing, `falling` checks for monotonically decreasing,
and `either` checks the y-values at the endpoints to determine if it is increasing or
decreasing. The value is between `0.0` and `1.0` where `1.0` is fully monononic and `0.0`
is monotonic in the opposite direction.
To return the percentage of samples (irrespective of x-values) that are monotonic, use
`monotonicity(yvals(signal))`.
"""
function monotonicity end
function monotonicity(s::AbstractIterableSignal)
    monotonicity(s, either)
end
function monotonicity(s::AbstractIterableSignal, ::Type{either})
    y1 = s(xmin(s))
    yn = s(xmax(s))
    increasing = y1 < yn
    if increasing
        monotonicity(s, rising)
    else
        monotonicity(s, falling)
    end
end
function monotonicity(s::AbstractIterableSignal, ::Type{rising})
    x1 = xmin(s)
    y1 = s(x1)
    tot = xmax(s) - x1
    rev = zero(tot) # x duration that it is not monotonic
    for x2 in eachx(s)
        y2 = s(x2)
        if y2 < y1
            rev += x2 - x1
        end
        x1 = x2
        y1 = y2
    end
    return 1-rev/tot
end
function monotonicity(s::AbstractIterableSignal, ::Type{falling})
    x1 = xmin(s)
    y1 = s(x1)
    tot = xmax(s) - x1
    rev = zero(tot) # x duration that it is not monotonic
    for x2 in eachx(s)
        y2 = s(x2)
        if y1 < y2
            rev += x2 - x1
        end
        x1 = x2
        y1 = y2
    end
    return 1-rev/tot
end

# Vectors: sample monotonicity
function monotonicity(ys::AbstractVector, ::Type{either})
    if last(ys) >= first(ys)
        monotonicity(ys, rising)
    else
        monotonicity(ys, falling)
    end
end
function monotonicity(ys::AbstractVector)
    monotonicity(ys, either)
end
function monotonicity(ys::AbstractVector, ::Type{rising})
    y1 = first(ys)
    tot = 0
    fwd = 0 # occurances that are monotonic
    for y2 in ys
        tot += 1
        if tot == 1
            continue # can't tell if monononic with one value
        end
        if y1 <= y2
            fwd += 1
            if tot == 2
                fwd += 1 # first point is also considered monononic
            end
        end
        y1 = y2
    end
    return fwd/tot
end
function monotonicity(ys::AbstractVector, ::Type{falling}) # discrete signal
    y1 = first(ys)
    tot = 0
    fwd = 0 # occurances that are monotonic
    for y2 in ys
        tot += 1
        if tot == 1
            continue # can't tell if monononic with one value
        end
        if y2 <= y1
            fwd += 1
            if tot == 2
                fwd += 1 # first point is also considered monononic
            end
        end
        y1 = y2
    end
    return fwd/tot
end
@signal_func monotonicity

