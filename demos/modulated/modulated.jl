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
md"""# AM Modulation with CedarWaves"""

# ╔═╡ f3cc22c5-d819-44ff-be9f-9ffd1e1a895a
md"""##### Task: write an AM calculator and take the RMS value:"""

# ╔═╡ 62298853-ccd4-4ec2-bdcd-8a9387fbf446
md"""
Input parameters:
- `N` is number of points in the signal: $(@bind N Select([10^3 => "1k points", 10^4 => "10k points", 10^5 => "100k points", 10^6 => "1M points", 10^7 => "10M points", 10^8 => "100M points", 500_000_000 => "500M points"], default=10^6))
- `s1` is the baseband signal of frequency `fb=`$(@bind fb Scrubbable(1:10, default=2)): (`s1 = sin(2π*f1*t)`)
- `s2` is the carrier signal of frequency `fc=`$(@bind fc Scrubbable(20:50, default=20)): (`s2 = cos(2π*f2*t)`)
- The mixer has an `offset` voltage of $(@bind offset Scrubbable(0:0.2:2, default=0)): (`mixed = s1 * s2 + offset`)
"""

# ╔═╡ 7ed00f06-08f9-4742-a1b6-7a911fa02f52
begin
	pch = @bind(do_py, CheckBox(default=false))
	md"""
	**Enable**: $pch Python (warning slow) 
	"""
end

# ╔═╡ c9e7a0d6-4c74-4f28-8474-4fcb514aec76
md"### In CedarWaves..."

# ╔═╡ 97747acf-5444-4e3e-9fc6-a2f326af5f2a
RMS(f) = sqrt(1/xspan(f) * integral(f^2))

# ╔═╡ 3942487a-8048-4e91-b04a-ff37cb46ab80
md"Run CedarWaves code:"

# ╔═╡ 058a4fc7-c3f3-469e-877c-f99a49eed81d
md"""### In Python ..."""

# ╔═╡ 853d2641-3b30-4a3d-92f6-a77e6b705091
begin
py"""
import math
def RMS_py(xs, ys):
    area = 0.0
    for i in range(1, len(xs)):
        dx = xs[i] - xs[i-1]
        y1 = ys[i-1]
        y2 = ys[i]
        dy = y2 - y1
        area += dx*(dy**2/3 + y1*y2)  # quadratic shape
    return math.sqrt(area/(xs[-1] - xs[0]))
	
def RMS_modulated_py(fb, fc, offset, xs):
	s1 = [math.sin(2*math.pi*fb*x) for x in xs]  # baseband signal
	s2 = [math.cos(2*math.pi*fc*x) for x in xs]  # carrier signal
	mixed = [s1[i]*s2[i] + offset for i in range(len(s1))]  # modulated signal
	return RMS_py(xs, mixed)
"""
# import python function into Julia's namespace:
RMS_modulated_py = py"RMS_modulated_py"
end


# ╔═╡ 0003c2f2-052d-4706-91f2-84c23600dbe4
md"Run Python code:"

# ╔═╡ c66524d2-482b-495e-9ff0-1aa141ebcb3f
md"**Additional code below:**"

# ╔═╡ d03289ca-5972-44f7-813f-864e6ddb52a9
md"Generate input signals:"

# ╔═╡ 07de82c5-4fe8-4985-8c15-c7691b412e8f
begin
	Ntxt = "1M"
	xs = [n/N for n in 0:N];
	t = PWCubic(xs, xs); # time vector as a CedarWaves signal
	nothing
end

# ╔═╡ b21007e7-2564-4682-bd1d-164e626067d4
begin
	tstart = time()

	s1 = sin(2*pi*fb*t)
	s2 = cos(2*pi*fc*t)
	mixed = s1*s2 + offset
	cw_val = RMS(mixed)
	
	tcalc = time()
	cw_val
end

# ╔═╡ 1b93a5a9-6cf8-408d-b8f4-8a010e15c357
begin
	py_t1 = time()
	py_val = if do_py
		RMS_modulated_py(fb, fc, offset, xs)
	else
		NaN
	end
	py_t2 = if do_py
		time()
	else 
		NaN
	end
end

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

# ╔═╡ 1a276e06-d637-4c92-b2cb-2f4b6c94c0f1
begin
	# Nice display of values:
	cw_err = err(cw_val, isapprox(cw_val, 0.5) ? 0.5 : cw_val)
	cw_time = tcalc - tstart
	cw_nt = nicetime(cw_time)
	cw_nv3 = rnd(cw_val, 3)
	cw_nv = rnd(cw_val, 8)
end

# ╔═╡ b6479417-5e2d-47ae-8982-99d7a4dd59a0
begin
	linewidth = 2
	color = :auto
	plt = plot(s1, label="$fb Hz baseband", xlabel="Time (s)", ylabel="Voltage"; linewidth, color)
	plot!(plt, s2, label="$fc Hz carrier"; color, linewidth=1)
	plot!(plt, mixed, label="modulated"; color, linewidth)
	
	tend = time()
	plot_time = tend - tcalc
	
	plot(plt, title="RMS(sin(2π fb t) * cos(2π fc *t) + offset)\ncalculated over 1M time points in $cw_nt ($cw_nv3 V)")
end

# ╔═╡ 6b73d2eb-d15a-4eaf-9758-710acee154f4
begin
	# Make Python results display nice
	py_time = py_t2 - py_t1
	py_nt = nicetime(py_time)
	py_nv = rnd(cw_val, 8)
end

# ╔═╡ 1da001b7-082c-457f-ab5f-84db7032a6c9
begin
	# Speedup calculation
	py_x = do_py ? "1x" : NaN
	cw_x = xfact(cw_time, py_time)
end

# ╔═╡ af7b3573-344b-48d8-817b-10763fa60623
md"""
| Tool  | Lines of Code | Result | Run Time | Speed-up |
|:----------- |:-------:|:------ |:--------:| -------- |
| CedarWaves  | 5       | $cw_nv | $cw_nt   | $cw_x   | 
| Python      | 15      | $py_nv | $py_nt   | $py_x   | 
"""


# ╔═╡ 427956cb-2093-4f7a-b83b-32e1830cf1d5
mixed

# ╔═╡ 374ec0a0-ed7d-4cc6-9e67-b6ede5c658a0
derivative(RMS(mixed))

# ╔═╡ Cell order:
# ╟─12cc55d1-0e20-4440-8b64-ad5ccb678230
# ╟─b39a77ba-4eff-11ec-28f8-e1d8787ad044
# ╟─f3cc22c5-d819-44ff-be9f-9ffd1e1a895a
# ╟─62298853-ccd4-4ec2-bdcd-8a9387fbf446
# ╟─b6479417-5e2d-47ae-8982-99d7a4dd59a0
# ╟─af7b3573-344b-48d8-817b-10763fa60623
# ╟─7ed00f06-08f9-4742-a1b6-7a911fa02f52
# ╟─c9e7a0d6-4c74-4f28-8474-4fcb514aec76
# ╠═97747acf-5444-4e3e-9fc6-a2f326af5f2a
# ╟─3942487a-8048-4e91-b04a-ff37cb46ab80
# ╠═b21007e7-2564-4682-bd1d-164e626067d4
# ╟─058a4fc7-c3f3-469e-877c-f99a49eed81d
# ╠═853d2641-3b30-4a3d-92f6-a77e6b705091
# ╟─0003c2f2-052d-4706-91f2-84c23600dbe4
# ╠═1b93a5a9-6cf8-408d-b8f4-8a010e15c357
# ╟─c66524d2-482b-495e-9ff0-1aa141ebcb3f
# ╟─1a276e06-d637-4c92-b2cb-2f4b6c94c0f1
# ╟─6b73d2eb-d15a-4eaf-9758-710acee154f4
# ╟─1da001b7-082c-457f-ab5f-84db7032a6c9
# ╟─d03289ca-5972-44f7-813f-864e6ddb52a9
# ╟─07de82c5-4fe8-4985-8c15-c7691b412e8f
# ╟─82a57cbf-4a6e-444a-992f-1105010ff119
# ╠═427956cb-2093-4f7a-b83b-32e1830cf1d5
# ╠═374ec0a0-ed7d-4cc6-9e67-b6ede5c658a0
