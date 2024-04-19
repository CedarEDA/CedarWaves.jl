export DxCheckResult, DyCheckResult, YCheckResult, satisfied, get_name

struct DxCheckResult
    meas::DxMeasure
    domain::Interval
end

function satisfied(c::DxCheckResult)
    return c.meas.pt1.x + minimum(c.domain) <=
           c.meas.pt2.x <=
           c.meas.pt1.x + maximum(c.domain)
end
get_name(c::DxCheckResult) = get_name(c.meas)

function Base.in(m::DxMeasure, domain::Interval)
    return DxCheckResult(m, domain)
end

struct DyCheckResult
    meas::TwoPointHeightMeasure
    domain::Interval
end

function satisfied(c::DyCheckResult)
    return c.meas.height ∈ c.domain
end
get_name(c::DyCheckResult) = get_name(c.meas)

function Base.in(m::TwoPointHeightMeasure, domain::Interval)
    return DyCheckResult(m, domain)
end


struct YCheckResult
    meas::YMeasure
    domain::Interval
end
satisfied(c::YCheckResult) = c.meas.value ∈ c.domain
get_name(c::YCheckResult) = get_name(c.meas)

function Base.in(m::YMeasure, domain::Interval)
    return YCheckResult(m, domain)
end

satisfied(c::Bool) = c
