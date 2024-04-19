### A Pluto.jl notebook ###
# v0.17.2

using Markdown
using InteractiveUtils

# ╔═╡ 1d1453f8-14bc-482a-abbf-b283d9f839d3
@time begin
	using Pkg
	Pkg.activate(".")
	# Pkg.add(path="../../CedarWaves.jl")
	# Pkg.add(["WGLMakie", "JSServe"])
	# Pkg.add(["HDF5", "JLD"]) # Pepijns scope data example
end

# ╔═╡ c91bd816-4cd3-11ec-1087-abeeeb58cf88
@time begin
	using WGLMakie
	using JSServe
	using CedarWaves
	# using HDF5, JLD # Pepijns scope data example
end

# ╔═╡ 998b2b6c-9c9f-484b-9707-4d0672f23d04
Page()

# ╔═╡ 21f31964-e63f-44ee-947c-9b2fbbba8126
md"""
```javascript
// for some reason I need to quadruple WGLMakie plots resolution?! Why thou?
window.devicePixelRatio == 2
```
"""

# ╔═╡ d596eb65-a87f-4b22-9b4f-d45172b0c4cf
md"""
```javascript
// with a default Pluto setup (i.e., no custom CSS) this should do the trick
// window.getComputedStyle(document.querySelector("pluto-cell")).getPropertyValue("width")
let pluto_cell = document.querySelector("pluto-cell");
let pluto_cell_comp_style = window.getComputedStyle(pluto_cell);
let pluto_cell_width = pluto_cell_comp_style.getPropertyValue("width");
let pluto_output_width = (parseInt(pluto_cell_width.replace(/px/,""))-20)+"px"; // subtract 20px padding
```
"""

# ╔═╡ a1c8a39e-2285-45c9-88ff-a7aebcb18365
const pluto_cell_width = 340 # px

# ╔═╡ 8e861a49-6612-433e-ba3f-d0b763a6a594
grid_style = """
height: $(2pluto_cell_width)px;
display: grid;
grid-template-columns: 80% 20%;
grid-template-rows: 20% 10% 10% 60%;
grid-template-areas:
	"plot_full logo"
	"slider_pos ."
	"slider_perc color_picker"
	"plot_detail vert_slider";
""";

# ╔═╡ 0e43f799-49b6-4118-a4e4-edd77b6772c0
# App() do
# 	s1 = Slider(0:99; style="width: 100%; grid-area: slider_pos;")
# 	s2 = Slider(1:100; style="width: 100%; grid-area: slider_perc;")

# 	fig1 = Figure(resolution=(pluto_cell_width,68).*4) # why times 4? high dpi?
# 	ax1 = Axis(fig1[1,1])
# 	limits!(ax1, 0, 100, -1, 1)
# 	# ax1.aspect = AxisAspect(1)

# 	# I need two figures but I can't reset the second figure with <CTRL> + <CLIcK>
# 	fig2 = Figure(resolution=(pluto_cell_width,204).*4)
# 	ax2 = Axis(fig2[1,1])

# 	points = lift(s1,s2) do x, Δx
# 		Makie.Point2f[(x,-0.5),(x+Δx,-0.5),(x+Δx,+0.5),(x,+0.5)]
# 	end

# 	poly!(ax1, points, color=Makie.RGBAf(0,0,0,0.2))

# 	# return JSServe.DOM.div(fig1, s1, s2, fig2
# 	# 	; style=grid_style
# 	# )
# 	JSServe.columns(JSServe.TailwindCSS, # Tailwind resets after reevaluation...
# 		fig1,
# 		JSServe.columns(
# 			s1, 
# 			s2; class="p-6"), # padding gets ignored...
# 		fig2)
# end

# ╔═╡ 473bc982-a052-41c4-8136-e3875c21db99
# Slider(1:10) |> dump # Observable

# ╔═╡ 8abdd074-8c16-4757-855f-d22dfe0086e6
# d = load(joinpath(@__DIR__, "data.jld"))["data"]

# ╔═╡ 5c9d50ea-ad23-4e88-8025-c5aeaa779845
# lines(d[10_000:20_000])

# ╔═╡ 42766719-9dae-4217-9fcc-d49b0f7b95a6
# App() do
# 	s1 = Slider(1:99; style="width: 100%; grid-area: slider_pos;", class="mt-3")
# 	s2 = Slider(1:100; style="width: 100%; grid-area: slider_perc;", class="mt-3 mb-3")

# 	fig1 = Figure(resolution=(pluto_cell_width,68).*4) # why times 4? high dpi?
# 	ax1 = Axis(fig1[1,1])
# 	ax1.xticks = 0:10:100
	
# 	step_full_factor = 100 # aka resolution
# 	percent = length(d)÷100
	
# 	lines!(ax1, range(1,100; length=length(1:percent÷step_full_factor:length(d))),
# 		d[1:percent÷step_full_factor:end])
# 	xlims!(ax1, 1, 100) # length(d[1:percent÷step_full_factor:end]))
# 	# ax1.aspect = AxisAspect(1)

# 	@show max_p, min_p = ceil(max(d...); digits=1), floor(min(d...); digits=1)
	
# 	points = lift(s1,s2) do x, Δx
# 		Makie.Point2f[
# 			(x,      min_p),
# 			((x+Δx), min_p),
# 			((x+Δx), max_p),
# 			(x, 	 max_p)]
# 	end # add heuristics...

# 	poly!(ax1, points, color=Makie.RGBAf(0,0,0,0.2))

# 	# I need two figures but I can't reset the second figure with <CTRL> + <CLIcK>
# 	fig2 = Figure(resolution=(pluto_cell_width,204).*4)
# 	ax2 = Axis(fig2[1,1])

# 	step_detail = 1000
	
# 	data = lift(s1,s2) do x, Δx
# 		# update_cam!(ax2.scene, Rect(1,min_p,Δx*step_detail,max_p))
# 		xlims!(ax2, 1,Δx*step_detail)
# 		d[x*percent:percent÷step_detail:min((x+Δx)*percent,length(d))]
# 	end
	
# 	# limits!(ax2, 1, length(data[]), floor(min(data[]...); digits=1), ceil(max(data[]...); digits=1))

# 	lines!(ax2, data)
	
	
# 	# lines!(ax2, range(1,100; length=length(data[])), data) # why does this not work?
# 	# limits!(ax2, 1, length(data[]), floor(min(data[]...)), ceil(max(data[]...)))

# 	# lift(s1,s2) do _, _
# 	# 	@info "this should update!"
# 	# 	@show fig2.scene.limits[]
# 	# 	# update!(fig2.scene)
# 	# 	# update_cam!(fig2.scene, fig2.scene.camera)
# 	# 	update_limits!(fig2.scene,
# 	# 		Rectf(1, length(data[]), floor(min(data[]...)), ceil(max(data[]...))))
# 	# end

# 	# return JSServe.DOM.div(fig1, s1, s2, fig2
# 	# 	; style=grid_style
# 	# )
# 	JSServe.columns(JSServe.TailwindCSS, # Tailwind resets after reevaluation...
# 		fig1,
# 		JSServe.columns(
# 			s1, 
# 			s2; class="ml-5 mr-2"), # padding gets ignored...
# 		fig2)
# end

# ╔═╡ a41f3c97-3313-41cd-a5d9-3137883570b8
begin
	mem = Int64(1e9)
	mem_num = sizeof(1.0)
	N = mem ÷ mem_num
	@time t = range(0, 1, length = N+1)
	fc, freq = 1000, 2
	@time y = @. sin(2pi*fc*t)*cos(2pi*freq*t)
end;

# ╔═╡ 95b535ea-2c54-4eb4-b1df-3f5efe73d13b
@time modulated = PWL(t, y)

# ╔═╡ 1f547b9a-98a9-40c3-9f72-b3b483fbd505
# _, ŷ = toplot(modulated) # pixels

# ╔═╡ 045a3a5e-a74c-4f9f-b650-1b2ce0c011b2
# let
# 	f = Figure(resolution=(pluto_cell_width,68).*4)
# 	ax = Axis(f[1,1])
# 	# lines!(ax, toplot(modulated; pixels=100_000)...)
# 	lines!(ax, y[1:1250:end])
# 	# xlims!(ax, 1, 100)
# 	f
# end

# ╔═╡ 87f65776-ddbb-4076-813b-e4ce71e3f41e
# function inspect(s::Signal; pixels=100_000)
# 	App() do
# 		sx, sy = toplot(s; pixels=pixels)
# 		len_sx = length(sx)
# 		len_sy = length(sy)
# 		@show max_y = ceil(max(sy...); digits=1)
# 		@show min_y = floor(min(sy...); digits=1)
# 		percent = len_sx ÷ 100
		
		
# 		s1 = Slider(1:99; style="width: 100%;", class="mt-3")
# 		s2 = Slider(1:99; style="width: 100%;", class="my-3")

		
# 		fig1 = Figure(resolution=(pluto_cell_width,68).*4) # why times 4? high dpi?
# 		ax1 = Axis(fig1[1,1])
# 		# limits!(ax1, 1, 100, min_y, max_y)
# 		scale = 10_000
# 		lines!(ax1, sy#=[1:percent ÷ scale:end]=#) # down sample # omit sx :|
# 		points = lift(s1,s2) do x, Δx
# 			Makie.Point2f[
# 				(x,      min_y),
# 				(x+Δx,   min_y),
# 				(x+Δx,   max_y),
# 				(x, 	 max_y)]
# 		end # add heuristics...
# 		poly!(ax1, points, color=Makie.RGBAf(0,0,0,0.2))


# 		fig2 = Figure(resolution=(pluto_cell_width,204).*4)
# 		ax2 = Axis(fig2[1,1])
# 		data_y = lift(s1,s2) do x, Δx
# 			span = x*percent:percent:min((x+Δx)*percent,length(sy))
# 			tmp = sy[span]
# 			limits!(ax2,
# 				x, min((x+Δx),length(tmp)),
# 				floor(min(tmp...); digits=1), ceil(max(tmp...); digits=1))
# 			return tmp
# 		end
# 		lines!(ax2, data_y)
		
# 		JSServe.columns(JSServe.TailwindCSS,
# 			fig1,
# 			JSServe.columns(
# 				s1, 
# 				s2; class="ml-5 mr-2"),
# 			fig2)
# 	end
# end

# ╔═╡ bbb31bd2-3521-40de-95b3-27b61a2051b3
# inspect(modulated)

# ╔═╡ dddc86fa-ba79-4ae4-8576-b5a2d1c2e1f2
function inspect(a::AbstractArray)
	App() do
		len_a = length(a)
		@show max_y = ceil(max(a...); digits=1) # make this a function
		@show min_y = floor(min(a...); digits=1)
		@show percent = len_a ÷ 100 # div; some values will get lost
		
		
		s1 = Slider(0:99; style="width: 100%;", class="mt-3") # window pos
		s2 = Slider(1:100; style="width: 100%;", class="my-3") # window width

		
		fig1 = Figure(resolution=(pluto_cell_width,68).*4) # why times 4? high dpi?
		ax1 = Axis(fig1[1,1])
		hidexdecorations!(ax1, grid=false)

		# limits!(ax1, 1, 100, min_y, max_y)
		
		step_full = 10 # percent÷10 # percent÷(percent÷x) == x
		lines!(ax1, a[1:step_full:end]) # percent÷scale_full to variable

		# slider box
		@show step_full2 = length(1:step_full:len_a)÷100 # unpretty
		points = lift(s1, s2) do x, Δx
			Makie.Point2f[ # Rect?
				(x*step_full2,     min_y), # bottom left
				((x+Δx)*step_full2,  min_y), # bottom right
				((x+Δx)*step_full2,  max_y), # top right
				(x*step_full2, 	max_y)  # top left
			] 		
			# Rect(x*step_full2, min_y, (x+Δx)*step_full2, max_y) # nah dis weird
		end # add heuristics...
		poly!(ax1, points, color=Makie.RGBAf(0,0.1,0.4,0.2))


		fig2 = Figure(resolution=(pluto_cell_width,204).*4) # magic numbers: 68, 204
		ax2 = Axis(fig2[1,1])

		step_detail = 2 # percent÷5 # contrived div's and scales...		
		data_y = lift(s1, s2) do x, Δx
			# span = x*percent:percent:min((x+Δx)*percent,length(sy))
			hi = min((x+1+Δx)*percent, len_a)
			lo = (x+1)*percent
			span = lo:step_detail:hi
			tmp = a[span]
			# limits!(ax2,
				# x, min((x+Δx),length(tmp)),
				# floor(min(tmp...); digits=1), ceil(max(tmp...); digits=1))
			xlims!(ax2, 1, length(span)) # throws hella warnings when over 100%
			ylims!(ax2, floor(min(tmp...); digits=1), ceil(max(tmp...); digits=1)) # so much splatting
			return tmp
		end
		lines!(ax2, data_y)
		
		JSServe.columns(JSServe.TailwindCSS,
			fig1,
			JSServe.columns(
				s1, 
				s2; class="ml-5 mr-2"),
			fig2)
	end
end

# ╔═╡ 0b7572b4-38ba-4343-8cc6-29697eedbb21
function inspect(s::Signal; pixels=100_000)
	_, y = toplot(s, pixels=pixels)
	inspect(y)
end

# ╔═╡ 5ffcdc03-cad7-41b2-8f5d-ac3f0547d0ce
@time inspect(y[1:Int(1e3):end])

# ╔═╡ 6f5fb292-e693-424a-9882-71ae86a13362
modulated

# ╔═╡ db1e9a9a-5bd5-493f-bb1f-7f3d6d6a4b13
@time inspect(modulated)

# ╔═╡ 7932ff40-da0b-49c0-b6db-54b5756ce5f8


# ╔═╡ 908cfe7d-17ab-4305-8123-79923e890d56
# function inspect(f::Function, span::AbstractRange)

# end

# ╔═╡ b3c4d8d4-74ad-4c38-8bb2-5513fe3d7c88
# begin
# 	f = Figure()
# 	ax = Axis(f)
# 	dump(f.scene; maxdepth=1)
# 	dump(f.scene.camera; maxdepth=1)
# 	@show cameracontrols(f.scene)
# 	dump(ax; maxdepth=1)
# 	dump(ax.scene; maxdepth=1)
# end

# ╔═╡ Cell order:
# ╠═1d1453f8-14bc-482a-abbf-b283d9f839d3
# ╠═c91bd816-4cd3-11ec-1087-abeeeb58cf88
# ╠═998b2b6c-9c9f-484b-9707-4d0672f23d04
# ╟─21f31964-e63f-44ee-947c-9b2fbbba8126
# ╟─d596eb65-a87f-4b22-9b4f-d45172b0c4cf
# ╠═a1c8a39e-2285-45c9-88ff-a7aebcb18365
# ╟─8e861a49-6612-433e-ba3f-d0b763a6a594
# ╟─0e43f799-49b6-4118-a4e4-edd77b6772c0
# ╟─473bc982-a052-41c4-8136-e3875c21db99
# ╠═8abdd074-8c16-4757-855f-d22dfe0086e6
# ╟─5c9d50ea-ad23-4e88-8025-c5aeaa779845
# ╟─42766719-9dae-4217-9fcc-d49b0f7b95a6
# ╠═a41f3c97-3313-41cd-a5d9-3137883570b8
# ╠═95b535ea-2c54-4eb4-b1df-3f5efe73d13b
# ╟─1f547b9a-98a9-40c3-9f72-b3b483fbd505
# ╟─045a3a5e-a74c-4f9f-b650-1b2ce0c011b2
# ╟─87f65776-ddbb-4076-813b-e4ce71e3f41e
# ╟─bbb31bd2-3521-40de-95b3-27b61a2051b3
# ╠═dddc86fa-ba79-4ae4-8576-b5a2d1c2e1f2
# ╠═5ffcdc03-cad7-41b2-8f5d-ac3f0547d0ce
# ╠═0b7572b4-38ba-4343-8cc6-29697eedbb21
# ╠═6f5fb292-e693-424a-9882-71ae86a13362
# ╠═db1e9a9a-5bd5-493f-bb1f-7f3d6d6a4b13
# ╠═7932ff40-da0b-49c0-b6db-54b5756ce5f8
# ╟─908cfe7d-17ab-4305-8123-79923e890d56
# ╟─b3c4d8d4-74ad-4c38-8bb2-5513fe3d7c88
