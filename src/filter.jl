import SpecialFunctions: besseli

# The DSP module is distributed under the MIT license.
# Copyright 2012-2021 DSP.jl contributors
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# ControlSystems.jl is licensed under the MIT License:
# Copyright (c) 2014-2018: Jim Crist, Mattias Fält, Fredrik Bagge Carlson and other contributors:
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

################### FIR filter designs, based on DSP.jl ########################

abstract type FilterType end

"""
Lowpass(f)

Represents a low-pass filter with cut-off frequency w
"""
struct Lowpass{T} <: FilterType
    f::T
end

"""
Bandpass(f1, f2)

Represents a band-pass filter with a pass band between frequencies w1 and w2
"""
struct Bandpass{T} <: FilterType
    f1::T
    f2::T
end

"""
Highpass(f)

Represents a high-pass filter with cut-off frequency w

High-pass FIR filters require an impulse function that hampers integration.
Consider using a band-pass filter where possible.
"""
struct Highpass{T} <: FilterType
    f::T
end

"""
Bandstop(f1, f2)

Represents a band-stop filter with a stop band between frequencies w1 and w2

Band-stop FIR filters require an impulse function that hampers integration.
Consider using other filter types where possible.
"""
struct Bandstop{T} <: FilterType
    f1::T
    f2::T
end

function Base.getproperty(ft::FilterType, f::Symbol)
    if f == :w
        getfield(ft, :f)*2π
    elseif f == :w1
        getfield(ft, :f1)*2π
    elseif f == :w2
        getfield(ft, :f2)*2π
    else
        getfield(ft, f)
    end
end

function firprototype(ftype::Lowpass, span)
    f = 2*ftype.f
    FiniteFunction{Float64, Float64}((-span/2)..(span/2), x->f*sinc(f*x))
end

function firprototype(ftype::Highpass, span)
    f = 2*ftype.f
    d = (-span/2)..(span/2)
    imp = zeropad(impulse(span/1000), d)
    FiniteFunction{Float64, Float64}(d, x->imp(x)-f*sinc(f*x))
end

function firprototype(ftype::Bandpass, span)
    f1 = 2*ftype.f1
    f2 = 2*ftype.f2
    FiniteFunction{Float64, Float64}((-span/2)..(span/2), x->f2*sinc(f2*x) - f1*sinc(f1*x))
end

function firprototype(ftype::Bandstop, span)
    f1 = 2*ftype.f1
    f2 = 2*ftype.f2
    d = (-span/2)..(span/2)
    imp = zeropad(impulse(span/1000), d)
    FiniteFunction{Float64, Float64}(d, x->imp(x) - (f2*sinc(f2*x) - f1*sinc(f1*x)))
end

"""
hanning

A hanning windowing function over the domain -0.5..0.5
"""
const hanning = FiniteFunction{Float64, Float64}(-0.5..0.5, x->0.5*(1+cos(2pi*x)))

"""
gaussian(σ)

A gaussian windowing function over the domain -0.5..0.5
"""
function gaussian(σ)
    FiniteFunction{Float64, Float64}(-0.5..0.5, x->exp(-0.5*(x/σ)^2))
end

"""
kaiser(α)

A kaiser windowing function over the domain -0.5..0.5
"""
function kaiser(α)
    pf = 1.0/besseli(0,pi*α)
    FiniteFunction{Float64, Float64}(-0.5..0.5, x->pf*besseli(0, pi*α*(sqrt(1 - (2x)^2))))
end

scalefactor(flt::AbstractSignal, ::Union{Lowpass, Bandstop}) = integral(flt)
function scalefactor(flt::AbstractSignal, ftype::Highpass)
    # s = FiniteFunction{Float64, Float64}(x->sinpi(20*ftype.w*x))
    # integral(flt*s)
    1
end
function scalefactor(flt::AbstractSignal, ftype::Bandpass)
    # freq = (ftype.w1+ftype.w2)/2
    # s = FiniteFunction{Float64, Float64}(x->sinpi(2*freq*x))
    # integral(flt*s)
    1
end

"""
firfilter(ftype, span, window=hanning)

A filter design method based on windowed sinc functions.

`ftype` can be a `Lowpass`, `Highpass`, `Bandpass`, or `Bandstop`
`span` is the truncated length of the filter
`window` is the windowing function that is applied, defaults to hanning.

To filter a signal, use `convolution(filter, signal)`
To see the frequency response of the filter, use `sample(FT(sample(filter, tstep)), fmin:fmax)`

# Example

```jldoctest
julia> hp = firfilter(Highpass(750.0), 0.05); # 750 Hz highpass filter

julia> hptf = abs(sample(FT(sample(hp, 0.001)), 0.0:1000)); # frequency response magnitude

julia> hptf(0) < 0.01 # in stop band
true

julia> hptf(1000) > 0.99 # in pass band
true

julia> round(cross(hptf, rising(0.5)), sigidigts=3) # corner frequency
750.0

julia> t = PWL(0:0.0001:1, 0:0.0001:1); # 1 second signal

julia> s100 = sinpi(2*100*t); # 100 Hz component

julia> s1000 = sinpi(2*1000*t); # 1000 Hz component

julia> s = s100 + s1000; # signal with 100 Hz and 1000 Hz components

julia> s_hp = sample(convolution(hp, s), xvals(s)); # filter out low frequency signal

julia> err = rms(clip(s_hp - s1000, 0.1..0.9)) < 0.01; # error in filtered signal
true
```

See also
[`LowPass`](@ref),
[`HighPass`](@ref),
[`BandPass`](@ref),
[`BandStop`](@ref),
[`hanning`](@ref),
[`gaussian`](@ref),
[`kaiser`](@ref),
[`convolution`](@ref),
[`iirfilter`](@ref),
"""

function firfilter(ftype::FilterType, span, window=hanning)
    w = xscale(window, span)
    proto = firprototype(ftype, span)
    y = w*proto
    # area = scalefactor(y, ftype)
    # y/area
    y
end

"""
window(s, w)

Apply window `w` to signal `s`.
"""
function window(s, w=hanning)
    # scale window to signal size
    wscaled = xscale(w, xspan(s))
    # find the middle of the signal
    middle = (xmin(s)+xmax(s))/2
    # shift the window to the middle of the signal
    w = xshift(wscaled, middle)
    # multiply
    w*s
end

############################ IIR filter design, based on DSP.jl and ControlSystems.jl ##################################

# We adapted code from DSP for IIR filter design
# We adapted code from ControlSystems to convert the ZPK filter to State Space
# We use OrdinaryDiffEq for simulating the system
using OrdinaryDiffEq
using Polynomials: Polynomial, coeffs
using LinearAlgebra: diagm, checksquare, LAPACK, I, diag

########################################### Stuff adapted from ControlSystems ###########################################

# T the numeric type of the transfer function
# TR the type of the roots
struct SisoZpk{T,TR<:Number}
    z::Vector{TR}
    p::Vector{TR}
    k::T
    function SisoZpk{T,TR}(z::Vector{TR}, p::Vector{TR}, k::T) where {T<:Number, TR<:Number}
        if k == zero(T)
            p = TR[]
            z = TR[]
        end
        if TR <: Complex && T <: Real
            z, p = copy(z), copy(p)
            pairup_conjugates!(z) || throw(ArgumentError("zpk model should be real-valued, but zeros do not come in conjugate pairs."))
            pairup_conjugates!(p) || throw(ArgumentError("zpk model should be real-valued, but poles do not come in conjugate pairs."))
        end
        new{T,TR}(z, p, k)
    end
end
function SisoZpk{T,TR}(z::Vector, p::Vector, k::Number) where {T<:Number, TR<:Number}
    SisoZpk{T,TR}(Vector{TR}(z), Vector{TR}(p), T(k))
end
function SisoZpk{T}(z::Vector, p::Vector, k::Number) where T
    TR = complex(T)
    SisoZpk{T,TR}(Vector{TR}(z), Vector{TR}(p), T(k))
end
function SisoZpk(z::AbstractVector{TZ}, p::AbstractVector{TP}, k::T) where {T<:Number, TZ<:Number, TP<:Number} # NOTE: is this constructor really needed?
    TR = promote_type(TZ,TP)
    SisoZpk{T,TR}(Vector{TR}(z), Vector{TR}(p), k)
end

# tzeros is not meaningful for transfer function element? But both zero and zeros are taken...
tzeros(f::SisoZpk) = f.z # Do minreal first?,
poles(f::SisoZpk) = f.p # Do minreal first?

numpoly(f::SisoZpk{<:Real}) = f.k*prod(roots2real_poly_factors(f.z))
denpoly(f::SisoZpk{<:Real}) = prod(roots2real_poly_factors(f.p))

numpoly(f::SisoZpk) = f.k*prod(roots2poly_factors(f.z))
denpoly(f::SisoZpk) = prod(roots2poly_factors(f.p))

numvec(f::SisoZpk) = reverse(coeffs(numpoly(f))) # FIXME: reverse?!
denvec(f::SisoZpk) = reverse(coeffs(denpoly(f))) # FIXME: reverse?!

isproper(f::SisoZpk) = (length(f.z) <= length(f.p))


""" Reorder the vector x of complex numbers so that complex conjugates come after each other,
    with the one with positive imaginary part first. Returns true if the conjugates can be
    paired and otherwise false."""
function pairup_conjugates!(x::AbstractVector)
    i = 0
    while i < length(x)
        i += 1
        imag(x[i]) == 0 && continue

        # Attempt to find a matching conjugate to x[i]
        j = findnext(==(conj(x[i])), x, i+1)
        j === nothing && return false

        tmp = x[j]
        x[j] = x[i+1]
        # Make sure that the complex number with positive imaginary part comes first
        if imag(x[i]) > 0
            x[i+1] = tmp
        else
            x[i+1] = x[i]
            x[i] = tmp
        end
        i += 1 # Since it is a pair and the conjugate was found
    end
    return true
end

# NOTE: Tolerances for checking real-ness removed, shouldn't happen from LAPACK?
# TODO: This doesn't play too well with dual numbers..
# Allocate for maxiumum possible length of polynomial vector?
#
# This function rely on that the every complex roots is followed by its exact conjugate,
# and that the first complex root in each pair has positive imaginary part. This format is always
# returned by LAPACK routines for eigenvalues.
function roots2real_poly_factors(roots::Vector{cT}) where cT <: Number
    T = real(cT)
    poly_factors = Vector{Polynomial{T}}()
    for k in eachindex(roots)
        r = roots[k]

        if isreal(r)
            push!(poly_factors,Polynomial{T}([-real(r),1]))
        else
            if imag(r) < 0 # This roots was handled in the previous iteration # TODO: Fix better error handling
                continue
            end

            if k == length(roots) || r != conj(roots[k+1])
                throw(ArgumentError("Found pole without matching conjugate."))
            end

            push!(poly_factors,Polynomial{T}([real(r)^2+imag(r)^2, -2*real(r), 1]))
            # k += 1 # Skip one iteration in the loop
        end
    end

    return poly_factors
end
# This function should hande both Complex as well as symbolic types
function roots2poly_factors(roots::Vector{T}) where T <: Number
    return [Polynomial{T}([-r, 1]) for r in roots]
end

# Conversion to statespace on controllable canonical form
function siso_tf_to_ss(f::SisoZpk{T}) where T

    num0, den0 = numvec(f), denvec(f)
    # Normalize the numerator and denominator to allow realization of transfer functions
    # that are proper, but not strictly proper
    num = num0 / den0[1]
    den = den0 / den0[1]

    N = length(den) - 1 # The order of the rational function f

    # Get numerator coefficient of the same order as the denominator
    bN = length(num) == N+1 ? num[1] : 0

    if N == 0 #|| num == zero(Polynomial{T})
        A = zeros(T, (0, 0))
        B = zeros(T, (0, 1))
        C = zeros(T, (1, 0))
    else
        A = diagm(1 => ones(T, N-1))
        A[end, :] .= -reverse(den)[1:end-1]

        B = zeros(T, (N, 1))
        B[end] = one(T)

        C = zeros(T, (1, N))
        C[1:min(N, length(num))] = reverse(num)[1:min(N, length(num))]
        C[:] -= bN * reverse(den)[1:end-1] # Can index into polynomials at greater inddices than their length
    end
    D = fill(bN, (1, 1))

    return A, B, C, D
end

"""
`A, B, C, T = balance_statespace{S}(A::Matrix{S}, B::Matrix{S}, C::Matrix{S}, perm::Bool=false)`
`sys, T = balance_statespace(sys::StateSpace, perm::Bool=false)`
Computes a balancing transformation `T` that attempts to scale the system so
that the row and column norms of [T*A/T T*B; C/T 0] are approximately equal.
If `perm=true`, the states in `A` are allowed to be reordered.
This is not the same as finding a balanced realization with equal and diagonal observability and reachability gramians, see `balreal`
"""
function balance_statespace(A::AbstractMatrix, B::AbstractMatrix, C::AbstractMatrix, perm::Bool=false)
    nx = size(A, 1)
    nu = size(B, 2)
    ny = size(C, 1)

    # Compute the transformation matrix
    mag_A = abs.(A)
    mag_B = max.(abs.(B), false) # false is 0 of lowest type
    mag_C = max.(abs.(C), false)
    T = balance_transform(mag_A, mag_B, mag_C, perm)

    # Perform the transformation
    A = T*A/T
    B = T*B
    C = C/T

    return A, B, C, T
end

"""
`T = balance_transform{R}(A::AbstractArray, B::AbstractArray, C::AbstractArray, perm::Bool=false)`
`T = balance_transform(sys::StateSpace, perm::Bool=false) = balance_transform(A,B,C,perm)`
Computes a balancing transformation `T` that attempts to scale the system so
that the row and column norms of [T*A/T T*B; C/T 0] are approximately equal.
If `perm=true`, the states in `A` are allowed to be reordered.
This is not the same as finding a balanced realization with equal and diagonal observability and reachability gramians, see `balreal`
See also `balance_statespace`, `balance`
"""
function balance_transform(A::AbstractArray, B::AbstractArray, C::AbstractArray, perm::Bool=false)
    nx = size(A, 1)
    # Compute a scaling of the system matrix M
    R = promote_type(eltype(A), eltype(B), eltype(C), Float32) # Make sure we get at least BlasFloat
    T = R[A B; C zeros(R, size(C*B))]

    size(T,1) < size(T,2) && (T = [T; zeros(R, size(T,2)-size(T,1),size(T,2))])
    size(T,1) > size(T,2) && (T = [T zeros(R, size(T,1),size(T,1)-size(T,2))])
    S = diag(balance(T, false)[1])
    Sx = S[1:nx]
    Sio = S[nx+1]
    # Compute permutation of x (if requested)
    pvec = perm ? balance(A, true)[2] * [1:nx;] : [1:nx;]
    # Compute the transformation matrix
    T = zeros(R, nx, nx)
    T[pvec, :] = Sio * diagm(0 => R(1)./Sx)
    return T
end

"""
    S, P, B = balance(A[, perm=true])

Compute a similarity transform `T = S*P` resulting in `B = T\\A*T` such that the row
and column norms of `B` are approximately equivalent. If `perm=false`, the
transformation will only scale `A` using diagonal `S`, and not permute `A` (i.e., set `P=I`).
"""
function balance(A, perm::Bool=true)
    n = checksquare(A)
    B = copy(A)
    job = perm ? 'B' : 'S'
    ilo, ihi, scaling = LAPACK.gebal!(job, B)

    S = diagm(0 => scaling)
    for j = 1:(ilo-1)   S[j,j] = 1 end
    for j = (ihi+1):n   S[j,j] = 1 end

    P = Matrix{Int}(I,n,n)
    if perm
        if ilo > 1
            for j = (ilo-1):-1:1 cswap!(j, round(Int, scaling[j]), P) end
        end
        if ihi < n
            for j = (ihi+1):n    cswap!(j, round(Int, scaling[j]), P) end
        end
    end
    return S, P, B
end

############################## stuf cribbed from DSP ###################################

#
# Butterworth prototype
#

function Butterworth(::Type{T}, n::Integer) where {T<:Real}
    n > 0 || error("n must be positive")

    poles = zeros(Complex{T}, n)
    for i = 1:div(n, 2)
        w = convert(T, 2i-1)/2n
        pole = complex(-sinpi(w), cospi(w))
        poles[2i-1] = pole
        poles[2i] = conj(pole)
    end
    if isodd(n)
        poles[end] = -1
    end
    SisoZpk(Complex{T}[], poles, one(T))
end

"""
    Butterworth(n)

``n`` pole Butterworth filter.
"""
Butterworth(n::Integer) = Butterworth(Float64, n)

#
# Chebyshev type I and II prototypes
#

function chebyshev_poles(::Type{T}, n::Integer, ε::Real) where {T<:Real}
    p = zeros(Complex{T}, n)
    μ = asinh(convert(T, 1)/ε)/n
    b = -sinh(μ)
    c = cosh(μ)
    for i = 1:div(n, 2)
        w = convert(T, 2i-1)/2n
        pole = complex(b*sinpi(w), c*cospi(w))
        p[2i-1] = pole
        p[2i] = conj(pole)
    end
    if isodd(n)
        w = convert(T, 2*div(n, 2)+1)/2n
        pole = b*sinpi(w)
        p[end] = pole
    end
    p
end

function Chebyshev1(::Type{T}, n::Integer, ripple::Real) where {T<:Real}
    n > 0 || error("n must be positive")
    ripple >= 0 || error("ripple must be non-negative")

    ε = sqrt(10^(convert(T, ripple)/10)-1)
    p = chebyshev_poles(T, n, ε)
    k = one(T)
    for i = 1:div(n, 2)
        k *= abs2(p[2i])
    end
    if iseven(n)
        k /= sqrt(1+abs2(ε))
    else
        k *= real(-p[end])
    end
    SisoZpk(Complex{T}[], p, k)
end

"""
    Chebyshev1(n, ripple)
`n` pole Chebyshev type I filter with `ripple` dB ripple in
the passband.
"""
Chebyshev1(n::Integer, ripple::Real) = Chebyshev1(Float64, n, ripple)

function Chebyshev2(::Type{T}, n::Integer, ripple::Real) where {T<:Real}
    n > 0 || error("n must be positive")
    ripple >= 0 || error("ripple must be non-negative")

    ε = 1/sqrt(10^(convert(T, ripple)/10)-1)
    p = chebyshev_poles(T, n, ε)
    for i = eachindex(p)
        p[i] = inv(p[i])
    end

    z = zeros(Complex{T}, n-isodd(n))
    k = one(T)
    for i = 1:div(n, 2)
        w = convert(T, 2i-1)/2n
        ze = complex(zero(T), -inv(cospi(w)))
        z[2i-1] = ze
        z[2i] = conj(ze)
        k *= abs2(p[2i])/abs2(ze)
    end
    isodd(n) && (k *= -real(p[end]))

    SisoZpk(z, p, k)
end

"""
    Chebyshev2(n, ripple)
`n` pole Chebyshev type II filter with `ripple` dB ripple in
the stopband.
"""
Chebyshev2(n::Integer, ripple::Real) = Chebyshev2(Float64, n, ripple)

#
# Elliptic prototype
#
# See Orfanidis, S. J. (2007). Lecture notes on elliptic filter design.
# Retrieved from http://www.ece.rutgers.edu/~orfanidi/ece521/notes.pdf

# Compute Landen sequence for evaluation of elliptic functions
function landen(k::Real)
    niter = 7
    kn = Vector{typeof(k)}(undef, niter)
    # Eq. (50)
    for i = 1:niter
        kn[i] = k = abs2(k/(1+sqrt(1-abs2(k))))
    end
    kn
end

# cde computes cd(u*K(k), k)
# sne computes sn(u*K(k), k)
# Both accept the Landen sequence as generated by landen above
for (fn, init) in ((:cde, :(cospi(u/2))), (:sne, :(sinpi(u/2))))
    @eval begin
        function $fn(u::Number, landen::Vector{T}) where T<:Real
            winv = inv($init)
            # Eq. (55)
            for i = length(landen):-1:1
                oldwinv = winv
                winv = 1/(1+landen[i])*(winv+landen[i]/winv)
            end
            w = inv(winv)
        end
    end
end

# sne inverse
function asne(w::Number, k::Real)
    oldw = NaN
    while w != oldw
        oldw = w
        kold = k
        # Eq. (50)
        k = abs2(k/(1+sqrt(1-abs2(k))))
        # Eq. (56)
        w = 2*w/((1+k)*(1+sqrt(1-abs2(kold)*w^2)))
    end
    2*asin(w)/π
end

function Elliptic(::Type{T}, n::Integer, rp::Real, rs::Real) where {T<:Real}
    n > 0 || error("n must be positive")
    rp > 0 || error("rp must be positive")
    rp < rs || error("rp must be less than rs")

    # Eq. (2)
    εp = sqrt(10^(convert(T, rp)/10)-1)
    εs = sqrt(10^(convert(T, rs)/10)-1)

    # Eq. (3)
    k1 = εp/εs
    k1 >= 1 && error("filter order is too high for parameters")

    # Eq. (20)
    k1′² = 1 - abs2(k1)
    k1′ = sqrt(k1′²)
    k1′_landen = landen(k1′)

    # Eq. (47)
    k′ = one(T)
    for i = 1:div(n, 2)
        k′ *= sne(convert(T, 2i-1)/n, k1′_landen)
    end
    k′ = k1′²^(convert(T, n)/2)*k′^4

    k = sqrt(1 - abs2(k′))
    k_landen = landen(k)

    # Eq. (65)
    v0 = -im/convert(T, n)*asne(im/εp, k1)

    z = Vector{Complex{T}}(undef, 2*div(n, 2))
    p = Vector{Complex{T}}(undef, n)
    gain = one(T)
    for i = 1:div(n, 2)
        # Eq. (43)
        w = convert(T, 2i-1)/n

        # Eq. (62)
        ze = complex(zero(T), -inv(k*cde(w, k_landen)))
        z[2i-1] = ze
        z[2i] = conj(ze)

        # Eq. (64)
        pole = im*cde(w - im*v0, k_landen)
        p[2i] = pole
        p[2i-1] = conj(pole)

        gain *= abs2(pole)/abs2(ze)
    end

    if isodd(n)
        pole = im*sne(im*v0, k_landen)
        p[end] = pole
        gain *= abs(pole)
    else
        gain *= 10^(-convert(T, rp)/20)
    end

    SisoZpk(z, p, gain)
end

"""
    Elliptic(n, rp, rs)
`n` pole elliptic (Cauer) filter with `rp` dB ripple in the
passband and `rs` dB attentuation in the stopband.
"""
Elliptic(n::Integer, rp::Real, rs::Real) = Elliptic(Float64, n, rp, rs)

# Create a lowpass filter from a lowpass filter prototype
transform_prototype(ftype::Lowpass, proto::SisoZpk{ZP, K}) where {ZP, K} =
    SisoZpk{ZP, K}(ftype.w * proto.z, ftype.w * proto.p,
              proto.k * ftype.w^(length(proto.p)-length(proto.z)))

# Create a highpass filter from a lowpass filter prototype
function transform_prototype(ftype::Highpass, proto::SisoZpk)
    z = proto.z
    p = proto.p
    k = proto.k
    nz = length(z)
    np = length(p)
    TR = Base.promote_eltype(z, p)
    newz = zeros(TR, max(nz, np))
    newp = zeros(TR, max(nz, np))

    num = one(eltype(z))
    for i = 1:nz
        num *= -z[i]
        newz[i] = ftype.w / z[i]
    end

    den = one(eltype(p))
    for i = 1:np
        den *= -p[i]
        newp[i] = ftype.w / p[i]
    end

    abs(real(num) - 1) < np*eps(real(num)) && (num = 1)
    abs(real(den) - 1) < np*eps(real(den)) && (den = 1)
    SisoZpk(newz, newp, oftype(k, k * real(num)/real(den)))
end

# Create a bandpass filter from a lowpass filter prototype
function transform_prototype(ftype::Bandpass, proto::SisoZpk)
    z = proto.z
    p = proto.p
    k = proto.k
    nz = length(z)
    np = length(p)
    ncommon = min(nz, np)
    TR = Base.promote_eltype(z, p)
    newz = zeros(TR, 2*nz+np-ncommon)
    newp = zeros(TR, 2*np+nz-ncommon)
    for (oldc, newc) in ((p, newp), (z, newz))
        for i = eachindex(oldc)
            b = oldc[i] * ((ftype.w2 - ftype.w1)/2)
            pm = sqrt(b^2 - ftype.w2 * ftype.w1)
            newc[2i-1] = b + pm
            newc[2i] = b - pm
        end
    end
    SisoZpk(newz, newp, oftype(k, k * (ftype.w2 - ftype.w1) ^ (np - nz)))
end

# Create a bandstop filter from a lowpass filter prototype
function transform_prototype(ftype::Bandstop, proto::SisoZpk)
    z = proto.z
    p = proto.p
    k = proto.k
    nz = length(z)
    np = length(p)
    npairs = nz+np-min(nz, np)
    TR = Base.promote_eltype(z, p)
    newz = Vector{TR}(undef, 2*npairs)
    newp = Vector{TR}(undef, 2*npairs)

    num = one(eltype(z))
    for i = 1:nz
        num *= -z[i]
        b = (ftype.w2 - ftype.w1)/2/z[i]
        pm = sqrt(b^2 - ftype.w2 * ftype.w1)
        newz[2i-1] = b - pm
        newz[2i] = b + pm
    end

    den = one(eltype(p))
    for i = 1:np
        den *= -p[i]
        b = (ftype.w2 - ftype.w1)/2/p[i]
        pm = sqrt(b^2 - ftype.w2 * ftype.w1)
        newp[2i-1] = b - pm
        newp[2i] = b + pm
    end

    # Any emaining poles/zeros are real and not cancelled
    npm = sqrt(-complex(ftype.w2 * ftype.w1))
    for (n, newc) in ((np, newp), (nz, newz))
        for i = n+1:npairs
            newc[2i-1] = -npm
            newc[2i] = npm
        end
    end

    abs(real(num) - 1) < np*eps(real(num)) && (num = 1)
    abs(real(den) - 1) < np*eps(real(den)) && (den = 1)
    SisoZpk(newz, newp, oftype(k, k * real(num)/real(den)))
end

function statespace(x, p, t)
    s, A, B = p
    dx = A*x + B*s(t)
end

function iirfilter(responsetype::FilterType, designmethod::SisoZpk)
    zpk = transform_prototype(responsetype, designmethod)
    A, B, C, D = siso_tf_to_ss(zpk)
    A, B, C, T = balance_statespace(A, B, C)
    A, B, C, D
end

function filt((A, B, C, D), s::AbstractSignal; algo=Rodas4(), rtol=1e-6, atol=1e-15, kwargs...)
    u0 = zeros(size(B))
    prob = ODEProblem(statespace, u0, (xmin(s),xmax(s)), (s, A, B))
    sol = solve(prob, algo; reltol=rtol, abstol=atol, kwargs...)
    # return sol
    x = sol.t
    f(x) = (C*sol(x) + D*s(x))[1]
    similar(s; x, f)
end

function filt(filter::AbstractSignal, s::AbstractSignal)
    convolution(filter, s)
end