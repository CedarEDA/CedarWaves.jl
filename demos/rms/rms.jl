### A Pluto.jl notebook ###
# v0.17.2

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 12cc55d1-0e20-4440-8b64-ad5ccb678230
begin
	# To run in REPL: import Pluto; Pluto.run() # and then load rms.jl in browser
    import Pkg
    Pkg.activate(Base.current_project())
	using Plots
	gr() # use GR backend for Plots
	using PlutoUI, CedarWaves, PyCall
	nothing
end

# ╔═╡ b39a77ba-4eff-11ec-28f8-e1d8787ad044
md"""# Custom Root Mean Square (RMS) Calculator Example"""

# ╔═╡ f3cc22c5-d819-44ff-be9f-9ffd1e1a895a
md"""##### Task: write a custom RMS function based on the textbook equation
```math
\text{RMS}(f) = \sqrt {{1 \over {T_2-T_1}} {\int_{T_1}^{T_2} {[f(t)]}^2\, {\rm d}t}}
```

This is a simple function yet it demonstrates the drastic improvement in productivity of **CedarWaves**.
"""

# ╔═╡ 882b8c9b-22a2-47c7-b1e1-3d47839768a0
md"""
## In CedarWaves it is...
1. **Simple**: most users can write this one line custom function in minutes
2. **Accurate**: correct handling of interpolation of continuous signals
3. **Fast & Interactive**: 10,000x faster than the competition
4. **Educational**: enhance creative and intellectual abilities of engineers
"""

# ╔═╡ 7de99f7a-bad3-430d-95bd-00400ceb2f67
md"""### 1. Simple
Most users could write a one-line **CedarWaves** custom RMS function in a few minutes:
"""

# ╔═╡ 002f23c8-78c2-4b1e-880d-6399dfa15ef2
RMS(f) = sqrt(1/xspan(f) * integral(f^2))

# ╔═╡ b27682d6-dbcb-4bc4-a47d-c4f5fb947a50
md"""
In the competitor's tools a function using their `integral` method will return an inaccurate result (see next section).
"""

# ╔═╡ 26270d22-64a0-4b55-bf3c-a49cc9b5a17a
md"""### 2. Accurate
**CedarWaves** corretly handles the **interpolation of continuous sampled signals** so calculations are easy to write correctly. """

# ╔═╡ c60a2dd7-b467-4d60-870f-4ccc79fbe741
md"""
Set number of simulation time points on a line segment: $(@bind Ns Slider(2:30, default=6, show_value=true))
"""

# ╔═╡ f63470b8-fefd-4727-b2e1-2f8ac7c5adc3
begin
	markershape = :circle
	xsegment = range(0, 1, length=Ns)
	ysegment = [2*x - 1 for x in xsegment]
	plt = plot(xsegment, ysegment, legend=:bottomright, label="Input signal", title="Squaring a line segment should be quadratic"; markershape)
	plot!(plt, xsegment, ysegment.^2, label="points^2 (Competition)"; markershape)
	cw_segment = PWL(xsegment, ysegment)
	plot!(plt, cw_segment^2, label="signal^2 (CedarWaves)")
end

# ╔═╡ 66de4afa-38a2-4e42-b9f3-c8578cf2958e
md"""
##### Explanation

The user defined functions in competitor's tools only operate on the simulation time points so the integration of the squared line segment will be a trapezoidal (red curve above) instead of quadratic (green curve above).

Using the competitor's `integral` built-in function would result in this inaccurate solution:
"""

# ╔═╡ ea34674e-4e8a-47fe-900e-04eb928d2ed3
function rms_points(xs, ys)
	area = 0.0
	for i in 2:length(xs)
		dx = xs[i] - xs[i-1]
		y1 = ys[i-1]
		y2 = ys[i]
		area += dx*(y1^2+y2^2)/2 # trapezoidal shape
	end
	sqrt(area/(xs[end]-xs[begin]))
end


# ╔═╡ b2adf4ad-778b-4b21-b78f-a2219e6c8c23
md"""
Customers complain so RMS is written with the correct algorithm below by taking the squared integral of a quadratic shape (green curve above):
"""

# ╔═╡ c640f840-c13e-4505-acfc-49cae0548673
function rms_signal(xs, ys)
	area = 0.0
	for i in 2:length(xs)
		dx = xs[i] - xs[i-1]
		y1 = ys[i-1]
		y2 = ys[i]
		dy = y2 - y1
		area += dx*(dy^2/3 + y1*y2) # quadratic shape
	end
	sqrt(area/(xs[end]-xs[begin]))
end


# ╔═╡ 519ef9c5-2167-4e43-9d19-993b530b6737
md"""
But this is very difficult for users to understand and write custom functions when non-linear combinations (squaring, multiplying, dividing, etc.) of signals are operated on.  As a result the competition's math functions will have an error of a few percent.
"""

# ╔═╡ 11da33ad-7e03-4a06-9eb0-e47b7b01fe90
md"""#### Accurate and Smooth Interpolation Methods

Analog waveforms are smooth so PWL interpolation is not realistic.
**CedarWaves** correctly handles smooth interpolation methods.

For example a SIN with with a few samples should have an RMS value of 1/sqrt(2) = $(round(1/sqrt(2), sigdigits=8)).  Lets see the different interpolation methods:

- Interpolation method: $(@bind Interp1 Select([PWL => "Linear (traditional)", PWQuadratic => "Quadratic (not recommended)", PWCubic => "Cubic (analog)", PWAkima => "Akima (analog)", PWC => "Constant (digital or S&H)"], default=PWL))
- Set number of data `points`: $(@bind points1 Slider(10:10:100, default=20, show_value=true))
- Mofidy test wavefrom frequency: `sin(2π` $(@bind freq1 Scrubbable(1:0.5:10, default=2))` t)`
"""

# ╔═╡ 223ae244-d4b0-439f-a4cc-f693f6fc3f8b
md"""### 3. Fast and Interactive"""

# ╔═╡ 48918f41-5625-4f38-be89-933442b3a95f
md"""
##### Benchmark RMS of a signal with many time points
"""

# ╔═╡ 9465de93-619f-4849-9e4e-d1ea07e0f186
md"""
- Interpolation method: $(@bind Interp Select([PWL => "Linear (traditional)", PWCubic => "Cubic (analog)", PWAkima => "Akima (analog)"], default=PWL))
- Set number of data `points`: $(@bind points Select([10^3 => "1k points", 10^4 => "10k points", 10^5 => "100k points", 10^6 => "1M points", 10^7 => "10M points", 10^8 => "100M points", 500_000_000 => "500M points"], default=10^6))
- Input waveform: `cos(2π` $(@bind f1 Scrubbable(1:20, default=2)) ` t )` `*` `cos(2π` $(@bind f2 Scrubbable(1:20, default=1)) ` t)`
"""

# ╔═╡ d89e6180-c995-4c55-b98c-a02399a8cbc9
begin
	pch = @bind(do_py, CheckBox(default=false))
	jch = @bind(do_jl, CheckBox(default=false))
	cch = @bind(do_cw, CheckBox(default=false))
	md"""
	##### Benchmark Results
	**Enable**: $pch Python | $jch Julia | $cch CedarWaves 
	"""
end

# ╔═╡ e5dc1149-bcd0-4568-a771-018b83257adf
md"""##### Explanation"""

# ╔═╡ f30211af-cada-44f2-bd06-43926b767504
md"""
**In Skill** the syntax has a much steeper learning curve and the user must write out their own integral squared function:

```lisp
procedure( rms(xs, ys)
    prog( (area x1 y1 x2 y2)
        area = 0.0
        x1 = car(xs)
        y1 = car(ys)
        foreach( (x2 y2), cdr(xs), cdr(ys),
            dx = x2 - x1
            dy = y2 - y1
            area = area + dx * (expt(dy, 2.0) / float(3) + y1 * y2) ; quadratic shape
            x1 = x2
            y1 = y2
        )
        return(sqrt(area / (car(last(xs)) - car(xs))))
    ) ;prog
) ;procedure
```

Indexing values is replaced with `car` and `cdr` and it uses integer division so the `/3` must be converted to a float.  This is much harder to read, understand and debug.
"""

# ╔═╡ 161923e7-649c-4a40-81ed-e35a377c71e1
md"""
**In TCL** the syntax is difficult and extra functions must be used to register the function and also read the values from the waveforms to get into TCL (which will slow things down more)

```tcl
proc rms {xs ys} {
    set area 0.0
    for {set i 1} {$i < [llength $xs]} {incr i} {
        set x1 [lindex $xs [expr {$i-1}]]
        set y1 [lindex $ys [expr {$i-1}]]
        set x2 [lindex $xs $i]
        set y2 [lindex $ys $i]
        set dx [expr {$x2 - $x1}] 
        set dy [expr {$y2 - $y1}] 
        set area [expr {$area + $dx*($dy**2/3.0 + $y1*$y2)}]
    }
    return [expr {sqrt($area/([lindex $xs end] - [lindex $xs 0]))}]
}
```
"""

# ╔═╡ cd4ea8cd-eb04-47f2-a2d4-c7fe04c07c47
md"""**In Python** user must write out their own integral squared function.  Thankfully the syntax is more familiar to engineers:"""

# ╔═╡ 11aa5e35-1070-463e-8f28-fdcf95d4c815
md"""
```python
def rms_signal_py(xs, ys):
    area = 0.0
    for i in range(1, len(xs)):
        dx = xs[i] - xs[i-1]
        y1 = ys[i-1]
        y2 = ys[i]
        dy = y2 - y1
        area += dx*(dy**2/3 + y1*y2)  # quadratic shape
    return math.sqrt(area/(xs[-1] - xs[0]))
```
"""

# ╔═╡ b51ea679-59c6-4934-ab08-2f4fdfb9255e
md"""**In Julia** (without **CedarWaves**) user must write their own function too but it is much faster and has an easy syntax:
"""

# ╔═╡ 05416ce6-6925-47ba-a614-fee18c1d3199
function rms(xs, ys)
	area = 0.0
	for i in 2:length(xs)
		dx = xs[i] - xs[i-1]
		y1 = ys[i-1]
		y2 = ys[i]
		dy = y2 - y1
		area += dx*(dy^2/3 + y1*y2) # quadratic shape
	end
	sqrt(area/(xs[end]-xs[begin]))
end

# ╔═╡ b2c302ff-c0a9-42e1-b135-aca7bf8fa6b7
md"""
**In CedarWaves** it is a simple definition of `RMS(f) = sqrt(1/xspan(f) * integral(f^2))` (see above) is both accurate, fast and general purpose.
"""

# ╔═╡ 7484026a-7424-46e8-944c-d96d312dc2f7
md"""
### 4. Educational

**CedarWaves** is fast, interactive and easy to make task specific GUIs.  

Engineers can quickly experiment and validate assumpions and **learn new things**, such as:

1. Which interpolation method works the best?
2. Why does constant interpolation of uniform samples approximate sine waves so well?
3. Understand approximate error conditions for different types of signals.

"""

# ╔═╡ 65950a7f-e2b7-4397-a5aa-e8ffb32e3031
md"### Appendix"

# ╔═╡ c66524d2-482b-495e-9ff0-1aa141ebcb3f
md"**Additional code below:**"

# ╔═╡ 82a57cbf-4a6e-444a-992f-1105010ff119
begin
	# Helper functions:
	rnd(val, sigdigits) = round(val; sigdigits)
	
	function xfact(val, ref; sigdigits=2)
		x = ref/val
		isnan(x) && return "NaN"
		v = rnd(x, sigdigits)
		if v > 15 
			v = round(Int, v)
		end
		string(v, "x")
	end
	
	err(val, ref, sigdigits=4) = (round((val-ref)/ref*100; sigdigits))
	
	function nicetime(sec; suffix="", sigdigits=2)
		fmt(sec, mult, suffix) = string(round(sec*mult; sigdigits), " $suffix")
		if sec < 1e-6
			fmt(sec, 1e9, "ns$suffix")
		elseif sec < 1e-3
			fmt(sec, 1e6, "us$suffix")
		elseif sec < 1
			fmt(sec, 1e3, "ms$suffix")
		elseif isnan(sec)
			sec
		else
			fmt(sec, 1, "s$suffix")
		end
	end
	md"Helper functions:"
end

# ╔═╡ 5f113191-50dc-4730-a4ee-95e2440625ad
begin
	sigdigits = 8
	rmsp = rnd(rms_points(xsegment, ysegment), sigdigits)
	rmsq = rnd(rms_signal(xsegment, ysegment), sigdigits)
	rmscw = rnd(RMS(PWL(xsegment, ysegment)), sigdigits)
	theory = rnd(1/sqrt(3), sigdigits)
	rmsp_err = err(rmsp, theory)
	rmsq_err = err(rmsq, theory)
	rmscw_err = err(rmscw, theory)
md"""
##### Accuracy of **$(Ns) point** RMS calculation

| RMS Method     | Lines of Code | RMS ($Ns pts) | Error (%)  |
|:-------------- |:-------------:|:------------- | ---------- |
| points^2       | 7             | $rmsp         | $rmsp_err  | 
| signal^2       | 8             | $rmsq         | $rmsq_err  | 
| RMS CedarWaves | 1             | $rmscw        | $rmscw_err |

**CedarWaves** results are always **accurate** with much better **ease of use**.

Competitor's results will be inaccurate unless the user understands how interpolation works and writes out a special algorithm to do the correct math (see below).  This must be done for all non-linear math functions and is very complex for users to do in general.  Competitor's math on non-linear combinations of signals will have a few percent error.
"""	
end

# ╔═╡ 13807c64-2562-4e1c-b0b9-62a9baf63567
begin
	t1 = range(0, 1, length=points1)
	y1 = @. sin(2*pi*freq1*t1)
	sig_interp = Interp1(t1, y1)
	rms_interp = RMS(sig_interp)
	label1 = Interp1 == PWL ? "Linear Interpolation" : Interp1 == PWQuadratic ? "Quadratic Interpolation" : Interp1 == PWCubic ? "Cubic Interpolation" : Interp1 == PWAkima ? "Akima Interpolation" : Interp1 == PWC ? "Constant Interpolation" : "Unknown"
	err1 = err(rms_interp, 1/sqrt(2), 2)
	title1 = "$label1: RMS = $(round(rms_interp, sigdigits=7))\n($(err1)% error)"
	plt1 = plot(sig_interp, title=title1)
	plot!(plt1, t1, y1, markershape=:circle, seriestype=:scatter, color=:black)
end

# ╔═╡ 3847f718-6e75-40e5-82c3-655fc531f5c6
begin
	# Tcl (twice as slow as Python):
	rmstl = NaN
	rmstlt = 3.0*points/10^6
	rmstln = nicetime(rmstlt, suffix="†")
	rmstlx = xfact(rmstlt, rmstlt)
	md"**TCL** benchmark code:"
end

# ╔═╡ 7dd6d976-2dec-4eba-bd68-ec189a8c92c6
begin
	alloct = @elapsed begin
		t = range(0, 1, length=points)
		y = @. cospi(2*f1*t) * cospi(2*f2*t)
	end
	allocn = nicetime(alloct)
	allocx = xfact(alloct, rmstlt)
	sig_bm = Interp(t, y)
end

# ╔═╡ ea009a30-2f71-4619-98ce-69997e925b28
begin
	# Skill (same speed as Python):
	rmsil = NaN
	rmsilt = 1.6*points/10^6
	rmsiln = nicetime(rmsilt, suffix="†")
	rmsilx = xfact(rmsilt, rmstlt)
	md"**Skill** benchmark code:"
end

# ╔═╡ ce808be7-ad3f-4898-8679-3788f002f0a2
begin
py"""
import math
def rms_signal_py(xs, ys):
    area = 0.0
    for i in range(1, len(xs)):
        dx = xs[i] - xs[i-1]
        y1 = ys[i-1]
        y2 = ys[i]
        dy = y2 - y1
        area += dx*(dy**2/3 + y1*y2)  # quadratic shape
    return math.sqrt(area/(xs[-1] - xs[0]))
"""
# import python function into Julia's namespace:
rms_signal_py = py"rms_signal_py"
end

# ╔═╡ e404b095-a8f7-46fd-8b45-f1a3a4b310d8
begin
	# Python:
	rmspy = do_py ? rnd(rms_signal_py(t, y), 8) : NaN
	rmspyt = do_py ? rnd(@elapsed(rms_signal_py(t, y)), 4) : NaN
	rmspyn = nicetime(rmspyt)
	rmspyx = xfact(rmspyt, rmstlt)
	md"**Python** benchmark code:"
end

# ╔═╡ 27679118-38ed-419e-8af5-b0dfbb21e70b
begin
	# Julia:
	rmsjl = do_jl ? rnd(rms_signal(t, y), 8) : NaN
	rmsjlt = do_jl ? rnd(@elapsed(rms_signal(t, y)), 4) : NaN
	rmsjln = nicetime(rmsjlt)
	rmsjlx = xfact(rmsjlt, rmstlt)
	md"**Julia** benchmark code:"
end

# ╔═╡ d31437b8-4471-489a-bf74-0866ef0c36e1
begin
	# CedarWaves:
	rmscw2 = do_cw ? rnd(RMS(sig_bm), 8) : NaN
	rmscwt = do_cw ? rnd(@elapsed(RMS(sig_bm)), 4) : NaN
	rmscwn = nicetime(rmscwt)
	rmscwx = xfact(rmscwt, rmstlt)
	md"**CedarWaves** benchmark code, `RMS(f) = sqrt(1/xspan(f) * integral(f^2))`:"
end

# ╔═╡ 8bc0ed0d-5241-4859-8230-230959c4bea0
md"""
Calculating RMS on a **$(points)** point waveform ("†" is estimated time):
	
| Implementation     |LoC | Result  | Run Time | Speed-up |
|:------------------ |----|:-------:|:------------:| -------- |
| TCL signal         | 13 | $rmstl  | $rmstln      | $rmstlx  |
| Skill signal       | 15 | $rmsil  | $rmsiln      | $rmsilx  |
| Python signal      | 10 | $rmspy  | $rmspyn      | $rmspyx  |
| Julia  signal      | 10 | $rmsjl  | $rmsjln      | $rmsjlx  |
| CedarWaves function|  1 | $rmscw2 | $rmscwn      | $rmscwx  |
| |
| (create input wave)|    |         | $allocn      | $allocx  |
"""


# ╔═╡ Cell order:
# ╟─12cc55d1-0e20-4440-8b64-ad5ccb678230
# ╟─b39a77ba-4eff-11ec-28f8-e1d8787ad044
# ╟─f3cc22c5-d819-44ff-be9f-9ffd1e1a895a
# ╟─882b8c9b-22a2-47c7-b1e1-3d47839768a0
# ╟─7de99f7a-bad3-430d-95bd-00400ceb2f67
# ╠═002f23c8-78c2-4b1e-880d-6399dfa15ef2
# ╟─b27682d6-dbcb-4bc4-a47d-c4f5fb947a50
# ╟─26270d22-64a0-4b55-bf3c-a49cc9b5a17a
# ╟─c60a2dd7-b467-4d60-870f-4ccc79fbe741
# ╟─f63470b8-fefd-4727-b2e1-2f8ac7c5adc3
# ╟─5f113191-50dc-4730-a4ee-95e2440625ad
# ╟─66de4afa-38a2-4e42-b9f3-c8578cf2958e
# ╠═ea34674e-4e8a-47fe-900e-04eb928d2ed3
# ╟─b2adf4ad-778b-4b21-b78f-a2219e6c8c23
# ╠═c640f840-c13e-4505-acfc-49cae0548673
# ╟─519ef9c5-2167-4e43-9d19-993b530b6737
# ╟─11da33ad-7e03-4a06-9eb0-e47b7b01fe90
# ╟─13807c64-2562-4e1c-b0b9-62a9baf63567
# ╟─223ae244-d4b0-439f-a4cc-f693f6fc3f8b
# ╟─48918f41-5625-4f38-be89-933442b3a95f
# ╟─7dd6d976-2dec-4eba-bd68-ec189a8c92c6
# ╟─9465de93-619f-4849-9e4e-d1ea07e0f186
# ╟─d89e6180-c995-4c55-b98c-a02399a8cbc9
# ╟─8bc0ed0d-5241-4859-8230-230959c4bea0
# ╟─e5dc1149-bcd0-4568-a771-018b83257adf
# ╟─f30211af-cada-44f2-bd06-43926b767504
# ╟─161923e7-649c-4a40-81ed-e35a377c71e1
# ╟─cd4ea8cd-eb04-47f2-a2d4-c7fe04c07c47
# ╟─11aa5e35-1070-463e-8f28-fdcf95d4c815
# ╟─b51ea679-59c6-4934-ab08-2f4fdfb9255e
# ╠═05416ce6-6925-47ba-a614-fee18c1d3199
# ╟─b2c302ff-c0a9-42e1-b135-aca7bf8fa6b7
# ╟─7484026a-7424-46e8-944c-d96d312dc2f7
# ╟─65950a7f-e2b7-4397-a5aa-e8ffb32e3031
# ╟─c66524d2-482b-495e-9ff0-1aa141ebcb3f
# ╟─82a57cbf-4a6e-444a-992f-1105010ff119
# ╟─3847f718-6e75-40e5-82c3-655fc531f5c6
# ╟─ea009a30-2f71-4619-98ce-69997e925b28
# ╟─e404b095-a8f7-46fd-8b45-f1a3a4b310d8
# ╠═ce808be7-ad3f-4898-8679-3788f002f0a2
# ╟─27679118-38ed-419e-8af5-b0dfbb21e70b
# ╟─d31437b8-4471-489a-bf74-0866ef0c36e1
