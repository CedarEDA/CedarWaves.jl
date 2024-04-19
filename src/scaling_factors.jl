module SIFactors

# User must manually import the symbols they want, eg:
# using CedarWaves.SIFactors: T, G, M, k, m, u, n, p, f

"""
    ScalingFactor(scale)
A `10^scale` scaling factor for writing numbers with SI multipliers, such as `3.3n` or `5.5M`.
"""
struct ScalingFactor
    scale::Int
end

"""
    snapnearest(number, n=1)
Round a number to the shortest printing float (looking at the current and the `n` previous and next floating point numbers).
"""
function snapnearest(number::Real, n::Int = 1)
    x = float(number)
    snapped = x
    minlen = length(string(x))
    prev = x
    next = x
    for i in 1:n
        prev = prevfloat(prev)
        next = nextfloat(next)
        for y in (prev, next)
            len = length(string(y))
            if len < minlen
                minlen = len
                snapped = y
            end
        end
    end
    return snapped
end

# Negative exponents are imprecise (1e-10) in floating point,
# so we use the positive exponent and divide instead of multiply
# to avoid floating point rounding errors.
function Base.:*(x::Number, s::ScalingFactor)
    if s.scale > 0
        scaled = Float64(Base.TwicePrecision(x) * Base.power_by_squaring(Base.TwicePrecision{Float64}(10.0), s.scale))
    else
        scaled = Float64(Base.TwicePrecision(x) / Base.power_by_squaring(Base.TwicePrecision{Float64}(10.0), -s.scale))
    end
    return snapnearest(scaled)
end

Y = ScalingFactor(24)
Z = ScalingFactor(21)
E = ScalingFactor(18)
P = ScalingFactor(15)
T = ScalingFactor(12)
G = ScalingFactor(9)
M = ScalingFactor(6)
K = ScalingFactor(3)
k = ScalingFactor(3)
m = ScalingFactor(-3)
u = ScalingFactor(-6)
μ = ScalingFactor(-6)
n = ScalingFactor(-9)
p = ScalingFactor(-12)
f = ScalingFactor(-15)
a = ScalingFactor(-18)
z = ScalingFactor(-21)
y = ScalingFactor(-24)



end # module SIFactors