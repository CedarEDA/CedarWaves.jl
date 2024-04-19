"""
    impulse(width)
Returns a signal representing a finite impulse with a triangle of
`PWL([-width, 0, width], [0, 1/width, 0])`.
The intergral of the impulse is `1`.

# Examples

```jldoctest
julia> s = impulse(1e-12);

julia> integral(s)
1.0
```

See also
[`convolution`](@ref),
[`crosscorrelation`](@ref),
[`autocorrelation`](@ref).
"""
function impulse(width::Real)
    # triangle: area = 1/2*b*h
    # b = 2width
    # h = 1/width
    z = zero(width)
    w = width
    PWL([-w, z, w], [z, 1/w, z])
end


"""
    SIN(; amp, freq, offset=0, phi=0)
Returns a signal defined by `amp * sinpi((2*freq*x + phi)+offset)`.

# Examples
```jldoctest
julia> s = SIN(amp=3, freq=2, offset=1);

julia> s(1/2 * 1/4)
4.0
```

`SIN` is an infinite function and can be sampled to create a PWL function of a triangular wave by sampling
the zeros and peakes of a sine wave::

```jldoctest
julia> triangle = PWL(0:0.25:5, SIN(amp=1, freq=1));

julia> triangle.(0:0.25:1)
5-element Vector{Float64}:
  0.0
  1.0
  0.0
 -1.0
  0.0
```

See also
[`PWC`](@ref),
[`PWL`](@ref),
[`PWQuadratic`](@ref),
[`PWCubic`](@ref),
[`ContinuousFunction`](@ref),
[`Series`](@ref),
[`impulse`](@ref),
[`domain`](@ref).
"""
function SIN(; amp, freq, offset=0, phi=0)
    InfiniteFunction{Float64, Float64}(x->amp*sinpi(2*freq*x + phi)+offset)
end

"""
    bitpattern(digital_input; tbit, trise, tfall=trise, tdelay=0, supply_levels)
Returns a PWL signal representing a bit pattern of `digital_input` vector of bools.

Arguments:
- `digital_input`: vector of bools repersenting the sequence of bits
- `tbit`: time between bits/pulses
- `trise`: rise time of a pulse
- `tfall`: fall time of a pulse (default is `trise`)
- `tdelay`: delay before the first bit
- `supply_levels`: the values of the low and high state, like `(vss, vdd)`

# Examples
```julia
const n = 1e-9
s = bitpattern([false,true,false,true,true], tbit=10n, trise=1n, tfall=3n, tdelay=1n, supply_levels=(0, 1.2))
```
"""
function bitpattern(digital_input::AbstractVector{Bool}; tbit, trise, tfall=trise, supply_levels, tdelay=zero(tbit))
    lvls = collect(supply_levels)
    vss, vdd = extrema(lvls)
	if (trise + tfall) > tbit
		error("bitpattern with trise+tfall >= tbit is invalid")
	end
	if tdelay < zero(tdelay)
		error("Negative tdelay is not supported: $tdelay")
	end
	xtype = float(promote_type(typeof.([tbit, trise, tfall, tdelay])...))
	ytype = float(promote_type(typeof(vdd), typeof(vss)))
	xvec = xtype[]
	yvec = ytype[]

	# Handle initial delay:
	t = zero(xtype)
	first_bit, rest = Iterators.peel(digital_input)
	initial_value = first_bit ? vdd : vss
	if tdelay > zero(tdelay)
		push!(xvec, t)
		push!(yvec, initial_value)
		t = tdelay
	end

	# Handle first bit:
	push!(xvec, t)
	push!(yvec, initial_value)

	# Handle rest of bits:
	prev_bit = first_bit
	t += tbit
	for bit in rest
		if bit > prev_bit # rising
			tt = trise
			y1 = vss
			y2 = vdd
		elseif bit < prev_bit # falling
			tt = tfall
			y1 = vdd
			y2 = vss
		end
		if bit != prev_bit
			push!(xvec, t - tt/2)
			push!(yvec, y1)

			push!(xvec, t + tt/2)
			push!(yvec, y2)
		end
		prev_bit = bit
		t += tbit
	end
	# Handle last point
	push!(xvec, t)
	push!(yvec, prev_bit ? vdd : vss)

	# Return PWL
	PWL(xvec, yvec)
end