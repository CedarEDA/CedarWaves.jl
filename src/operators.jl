
# Binary operators
const BINARY_OPERATORS = [:(+), :(-), :(*), :(/), :(^), :(÷)]
for func in BINARY_OPERATORS
    @eval begin
        function (Base.$func)(s1::AbstractSignal, s2::AbstractSignal)
            ymap_signal($func, s1, s2)
        end
        function (Base.$func)(s::AbstractSignal, n::Number)
            ymap_signal(y->($func)(y, n), s)
        end
        function (Base.$func)(n::Number, s::AbstractSignal)
            ymap_signal(y->($func)(n, y), s)
        end
        @signal_func Base.$func
    end
end

# Unary functions
const UNARY_OPERATORS = [:(+), :(-)]
for func in UNARY_OPERATORS
    @eval begin
        function (Base.$func)(s1::K) where K <: AbstractSignal
            ymap_signal($func, s1)
        end
    end
end
const UNARY_BOOL_OPERATORS = [:(!)]
for func in UNARY_BOOL_OPERATORS
    @eval begin
        function (Base.$func)(s1::K) where K <: AbstractSignal
            ymap_signal($func, s1)
        end
    end
end
const INEQUALITY_OPERATORS = [:(<), :(>), :(<=), :(>=)]

# 1-arg functions that broadcast to y values
const ONE_ARG_BASE_MATH_FUNCS = [
    :sin, :cos, :sincos, :tan, :sind, :cosd, :tand, :sinpi, :cospi,
    :sincospi, :sinh, :cosh, :tanh, :asin, :acos, :atan, :asind,
    :acosd, :atand, :sec, :csc, :cot, :secd, :cscd, :cotd, :asec,
    :acsc, :acot, :asecd, :acscd, :acotd, :sech, :csch, :coth, :asinh,
    :acosh, :atanh, :asech, :acsch, :acoth, :sinc, :cosc, :deg2rad,
    :rad2deg, :log, :log2, :log10, :log1p, :frexp, :exp, :exp2,
    :exp10, :expm1,
    :ceil, :floor, :trunc, # TODO: These have two argument versions
    :abs, :abs2, :sign, :signbit, :sqrt, :isqrt, :cbrt,
    :real, :imag, :conj, :cis, :cispi, :ispow2,
    # handled elsewhere:
    # :angle,
]
for func in ONE_ARG_BASE_MATH_FUNCS
    @eval begin
        function (Base.$func)(s::AbstractSignal)  # Note: not Base.$func because of "import Base: ..."
            ymap_signal($func, s)
        end
        @signal_func Base.$func
    end
end

function (Base.round)(s1::AbstractSignal, args...; kwargs...)
    ymap_signal(y->round(y, args...; kwargs...), s1)
end
function (Base.round)(Type, s1::AbstractSignal, args...; kwargs...)
    ymap_signal(y->round(Type, y, args...; kwargs...), s1)
end

# functions that convert array (y-values) to scalar (of AbstractSeries):
#const FUNC_Y_TO_SCALAR = [:prod, :sum, :cumprod, :cumsum]
#for func in FUNC_Y_TO_SCALAR
#    @eval begin
#        "Calculate $(string($func)) on y-values of a Series signal"
#        function (Base.$func)(s1::K) where K <: AbstractDiscrete
#            ($func)(s1.y)
#        end
#    end
#end

# TODO ?
# hypot
# ldexp
# min
# max
# minmax
#:checked_{abs, neg, sub, mul, div, rem, fld, mod, cld, }
# copysign, flipsign
# modf, reim

function Base.in(x, s::AbstractSignal)
    try
        s(x)
        true
    catch e
        e isa DomainError || rethrow()
        false
    end
end