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
    Pkg.activate(temp=true)
    Pkg.develop(path="../..")
    Pkg.add(["Plots", "PlutoUI", "PyCall"])
	using Plots
	gr() # use GR backend for Plots
	using PlutoUI, CedarWaves, PyCall
end

# ╔═╡ b39a77ba-4eff-11ec-28f8-e1d8787ad044
md"""# Easily Create and Debug Robust Custom Measurements

This demo showcases the following:
1. **High Productivity**: any user can quickly debug and write custom measurements
2. **Robust Measurements for Automation**: users can easily write custom, robust measurements so analog circuits can be optimized 
4. **Flexible**: measures can be used in math expressions and extra info is avaiable

## In CedarWaves
"""

# ╔═╡ f3cc22c5-d819-44ff-be9f-9ffd1e1a895a
md"""
### 1. High Productivity

##### Task: Write a custom `falltime` measurement that ignores glitches

Generate a test waveform with interactive parameters:
- Number of odd harmonics: $(@bind Nharm Slider(1:10, default=3, show_value=true))
- Frequency: $(@bind freq Scrubbable(1:0.5:10, default=5.5))
- Set number of data `points` per period: $(@bind points Select([10 => 10, 15 => 15, 20 => 20, 40 => 40, 60 => 60, 80 => 80, 100 => 100, 10^3 => "1k", 10^4 => "10k", 10^5 => "100k", 10^6 => "1M"], default=40))
- Set interpolation method $(@bind Interp Select([PWL => "Linear", PWQuadratic => "Quadratic", PWCubic => "Cubic", PWAkima => "Akima"]))
"""

# ╔═╡ b52ddd91-bdd7-49a8-9b86-0482bef32ec1
begin
	function sin_harmonic(freq, Nharm, xs)
		harms = range(1, step=2, length=Nharm)
		ys = [sum(n -> sin(2*pi*freq*n*x)/n, harms) for x in xs]
	end
	# one period:
	xs = range(0, 1, length=round(Int, points*freq))
	ys = sin_harmonic(freq, Nharm, xs)
	signal = Interp(xs, ys)
	yth = 0.75
	nothing
end

# ╔═╡ a6e27f01-b7da-4ffd-99ac-5a141da79b63
md"""
**To see glitch issue**, check $(@bind do_meas CheckBox(default=false)) to measure the `falltime`
"""

# ╔═╡ e48b497c-90c5-4661-92aa-714d10689d82
begin
	meas1 = falltime(signal, yth, -yth)
	if do_meas
		res = meas1
	else
		res = signal
	end
	plot(res, ylim=(-1.2, 1.2))
end

# ╔═╡ c18425a3-bae6-44c0-82b0-901111889129
begin
	if do_meas
		md"""
		!!! warning "Beware of Glitches"

			The measure isn't what is needed.  **Write a custom measurement to ignore the glitches**.
		"""
	else
		md"""
		!!! hint

			Click the checkbox above to show the measurement issue.
		"""
	end
end


# ╔═╡ e0777ccb-1d23-4690-89c2-9dba2a741bf2
md"""
### 2. Robust Measurements for Automation

Without **robust measurements** analog design cannot be optimized.  In this example the user wants to measure the transistion without the glitch.
"""

# ╔═╡ 2767721f-ca84-4f3f-9c51-a5a5270afee6
md"""#### A. Measure the first falling crossing at yth=$yth"""

# ╔═╡ fe0e719a-37a9-4131-83f5-2c73a23384b2
x1 = cross(signal, falling(yth))

# ╔═╡ eec2c874-88ac-4590-8c7a-728a8766b51b
md"**Plot measurement `x1`**"

# ╔═╡ 61959c35-55ff-44d4-851f-a0b8a8cb524a
plot(x1)

# ╔═╡ 820b65c8-6d75-4217-9fc2-bbc65ec70bb1
md"""
!!! note 

	To ignore glitches we will find the crossing at the second threshold first and then will search backwards to the first falling edge.
"""

# ╔═╡ 9c2bb95e-4522-496b-8be4-67056c438ded
md"#### B. Find next falling edge at yth = $(-yth)"

# ╔═╡ 301fdaa2-83ff-4e75-a9f3-e4a480e912ac
x2 = cross(signal, falling(-0.8))

# ╔═╡ 3bb45b64-9a62-48e7-8bcd-82915837274b
md"**Plot the crossing measurement `x2`**"

# ╔═╡ d8609f06-1847-4b2a-afcb-29243c671de5
plot(x2)

# ╔═╡ e9b42293-d732-4302-85d7-0851b5854a04
md"#### C. Find the previous falling crossing at $yth"

# ╔═╡ ebd6962b-fd37-4e26-8e98-b3582448537c
x1b = cross(clip(signal, x1 .. x2), falling(yth), N=-1)

# ╔═╡ 36c6cfe1-c409-4b8c-ad10-ec2c74b44674
md"**Plot the crossing measurement**"

# ╔═╡ 56bfdf76-1ad5-469d-bb5c-b31bb6d36053
plot(x1b)

# ╔═╡ 8d9d227f-1adb-44cb-b6b3-2383ec38ca5e
md"### D. Calculate the falltime (without glitches)"

# ╔═╡ a131ef14-e05e-45bb-9c1d-fa5f6623544e
tfall = x2 - x1b

# ╔═╡ 02a50859-0d31-4c0e-bd30-840de19d5c9a
md"#### E. For a summary plot clip the waveform to the measurement"

# ╔═╡ 7e93d582-136e-4bfd-bb85-23d0c81f3a9e
tfall_signal = clip(signal, x1b .. x2)

# ╔═╡ e29565f9-2b74-48d0-9098-8cbe8d232839
md"**Use `TwoPointMeasure` to complete the measurement**."

# ╔═╡ 3b91fb81-333a-4d9e-b5a3-4ef58c0f4175
meas = TwoPointMeasure(tfall_signal, tfall, name="falltime")

# ╔═╡ 93e33ddf-4e74-43e6-a7f4-0ae78947501a
md"""
In **CedarWaves** it is easy to write custom measurements and they run at full speed so it is much easier to **automate** analog design.
"""

# ╔═╡ 7a494416-aaa6-4f42-b353-0ca0fbc1b822
md"""
### 3. Flexible


##### Use Measures in Math Equations

Measures can be used in regular math expressions and will automatically convert to a number.  For example:
"""

# ╔═╡ f6847212-3786-4f34-a315-92bcfab4f3a1
half_fall = meas/2

# ╔═╡ daf0c2ab-7880-4e60-95f7-a8e787bd1d1b
md"##### Extra code"

# ╔═╡ f6b020f7-dda6-4790-bba3-897551d3f546
function rnd(val, sigdigits)
	round(val; sigdigits)
end

# ╔═╡ 24e7e784-47a1-4cfb-b207-862af2ddc512
md"""
##### Measures Provide Extra Measurement Info

As displayed in the legend of the plot above the measure has many properties that can be used:

| Property    | Description                  | Value                |
|:----------- |:---------------------------- |:--------------------:|
| `.signal`   | The clipped zoomed in signal | (see plot above)     |
| `.name`     | User provide name for measure| $(meas.name)         |
| `.sigdigits`   | Significant digits to display| $(meas.sigdigits)       |
| `.dx`       | Change in x                  | $(rnd(meas.dx,3))    |
| `.dy`       | Change in y                  | $(rnd(meas.dy,3))    |
| `.SR`       | Slewrate of crossing points  | $(rnd(meas.SR,3))    |
| `.x1`       | First cross x-value          | $(rnd(meas.x1,3))    |
| `.y1`       | First cross y-value          | $(rnd(meas.y1,3))    |
| `.x2`       | Second cross x-value         | $(rnd(meas.x2,3))    |
| `.y2`       | Second cross y-value         | $(rnd(meas.y2,3))    |

This makes measurements much more **flexible**, **easier to use** and **debug**.
"""

# ╔═╡ Cell order:
# ╟─12cc55d1-0e20-4440-8b64-ad5ccb678230
# ╟─b52ddd91-bdd7-49a8-9b86-0482bef32ec1
# ╟─b39a77ba-4eff-11ec-28f8-e1d8787ad044
# ╟─f3cc22c5-d819-44ff-be9f-9ffd1e1a895a
# ╟─e48b497c-90c5-4661-92aa-714d10689d82
# ╟─a6e27f01-b7da-4ffd-99ac-5a141da79b63
# ╟─c18425a3-bae6-44c0-82b0-901111889129
# ╟─e0777ccb-1d23-4690-89c2-9dba2a741bf2
# ╟─2767721f-ca84-4f3f-9c51-a5a5270afee6
# ╠═fe0e719a-37a9-4131-83f5-2c73a23384b2
# ╟─eec2c874-88ac-4590-8c7a-728a8766b51b
# ╠═61959c35-55ff-44d4-851f-a0b8a8cb524a
# ╟─820b65c8-6d75-4217-9fc2-bbc65ec70bb1
# ╟─9c2bb95e-4522-496b-8be4-67056c438ded
# ╠═301fdaa2-83ff-4e75-a9f3-e4a480e912ac
# ╟─3bb45b64-9a62-48e7-8bcd-82915837274b
# ╠═d8609f06-1847-4b2a-afcb-29243c671de5
# ╟─e9b42293-d732-4302-85d7-0851b5854a04
# ╠═ebd6962b-fd37-4e26-8e98-b3582448537c
# ╟─36c6cfe1-c409-4b8c-ad10-ec2c74b44674
# ╠═56bfdf76-1ad5-469d-bb5c-b31bb6d36053
# ╟─8d9d227f-1adb-44cb-b6b3-2383ec38ca5e
# ╠═a131ef14-e05e-45bb-9c1d-fa5f6623544e
# ╟─02a50859-0d31-4c0e-bd30-840de19d5c9a
# ╠═7e93d582-136e-4bfd-bb85-23d0c81f3a9e
# ╟─e29565f9-2b74-48d0-9098-8cbe8d232839
# ╠═3b91fb81-333a-4d9e-b5a3-4ef58c0f4175
# ╟─93e33ddf-4e74-43e6-a7f4-0ae78947501a
# ╟─7a494416-aaa6-4f42-b353-0ca0fbc1b822
# ╠═f6847212-3786-4f34-a315-92bcfab4f3a1
# ╟─24e7e784-47a1-4cfb-b207-862af2ddc512
# ╟─daf0c2ab-7880-4e60-95f7-a8e787bd1d1b
# ╟─f6b020f7-dda6-4790-bba3-897551d3f546
