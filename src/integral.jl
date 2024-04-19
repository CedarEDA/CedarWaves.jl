const default_atol = 1e-12
const default_rtol = sqrt(eps(Float64))

"""
    integral(signal, [domain; options...])
    integral(function, domain; [options...])
Returns the integral (via numerical integration) of a continuous
function or signal over its domain, according to the formula:

```math
\\mathrm{integral}(s)=\\int_{\\mathrm{xmin}(s)}^{\\mathrm{xmax}(s)} s(x)\\,\\mathrm{d}x
```

```math
\\mathrm{integral}\\big(s, (a,b)\\big)=\\int_{a}^{b} s(x)\\,\\mathrm{d}x
```

For signals if no domain is provided then it will use the domain of the signal.

# Options

The following keyword options are supported:
* `rtol`: relative error tolerance (defaults to `sqrt(eps)` in the precision of the endpoints.
* `atol`: absolute error tolerance (defaults to `1e-12`).  Note that for small currents it's recommended to use `0`.
* `maxevals`: maximum number of function evaluations (defaults to `10^7`)
* `order`: order of the integration rule (defaults to `7`).

# Examples

```jldoctest
julia> integral(PWL(0:2, [0,1,0])) ≈ 1
true

julia> integral(x -> exp(-x), 0..Inf) ≈ 1
true

julia> integral(sin, pi .. 2pi) ≈ -2
true
```

See also
[`sum`](@ref).
"""
function integral(signal::AbstractSignal, x_interval=domain(signal); atol=default_atol, rtol=default_rtol, kwargs...)
    val, err = QuadGK.quadgk(signal, first(x_interval), last(x_interval); atol, rtol, kwargs...)
    return val
end
function integral(signal, x_interval=domain(signal); atol=default_atol, rtol=default_rtol, kwargs...)
    val, err = QuadGK.quadgk(signal, first(x_interval), last(x_interval); atol, rtol, kwargs...)
    return val
end
@signal_func integral
#function _integralcomplex(signal, xs::AbstractInterval; error_value::Bool=false, atol=default_atol, rtol=default_rtol, kwargs...)::Complex{Float64}
#    # Error value always ignored
#    val, err = QuadGK.quadgk(signal, first(xs), last(xs); atol, rtol, kwargs...)
#    return val
#end
#function _integralreal(signal, xs::AbstractInterval; error_value::Bool=false, atol=default_atol, rtol=default_rtol, kwargs...)::Float64
#    # Error value always ignored
#    val, err = QuadGK.quadgk(signal, first(xs), last(xs); atol, rtol, kwargs...)
#    return val
#end

"""
    derivative(signal)
Returns the derivative of continuous signal, `signal`.

```jldoctest
julia> s1 = derivative(PWL(0:3, [0, -2, -1, -1]));

julia> s1(0)
-2.0

julia> s1(0.5)
-2.0

julia> s1(1.5)
1.0

julia> s1(2.5)
0.0
```
"""
function derivative(s::AbstractContinuousSignal)
    similar(s; f=x -> ForwardDiff.derivative(s, x))
end
@signal_func derivative

#function derivative(func)
#    x -> ForwardDiff.derivative(func, x)
#end

