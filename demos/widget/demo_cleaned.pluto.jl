### A Pluto.jl notebook ###
# v0.17.2

using Markdown
using InteractiveUtils

# ╔═╡ ffa12350-4ea7-11ec-159f-6926d19c55af
begin
	using Pkg
	Pkg.activate(".")
	Pkg.instantiate()

	using TimerOutputs
	const to = TimerOutput()
end;

# ╔═╡ dc5512e1-17e4-432a-a1be-1924b922449c
@timeit to "load packages" begin
	using CedarWaves
	using WGLMakie
	using JSServe
end

# ╔═╡ b264768c-4d81-4d90-b179-e7567bfb3142
md"""
# Widget
"""

# ╔═╡ 4992f5d2-619c-4d7b-9725-155f64b75712


# ╔═╡ 6b9914b9-b652-4a1f-badf-69b124e93380
md"""
## Setup
"""

# ╔═╡ 56b1a3e3-3f5d-4952-ab21-96c74e253595
@timeit to "page call" Page(listen_port=rand(9500:9999))

# ╔═╡ aab2cb9f-90e9-4d32-a920-68f632b9200d
# precompiles/load page session; must be run even with sysimage
@timeit to "first plot" lines(rand(1_000, 2))

# ╔═╡ 57914f0f-67a1-467e-ad75-226d151e363a
md"""
!!! warning
    ### Relevant Issue: [[Link]](https://github.com/SimonDanisch/JSServe.jl/issues/107)
    * this may be the culprit of the time snag...
"""

# ╔═╡ 66977069-a913-49ef-935c-d74864cb001d
md"""
* the proclaimed 144.xxx seconds page load time was closer to 300 seconds aka. 5 minutes!? you 4 real?
* [[Link]](https://github.com/SimonDanisch/JSServe.jl/blob/master/src/display.jl#L139-L172) does'nt clear up any confusion...
* once everything is loaded/has been run once displaying the widget usualy takes less than 6 s.
"""

# ╔═╡ 81319b09-e179-40b9-adb7-192266c677fe


# ╔═╡ 245a4d89-6e3d-4f4f-ab67-8f292c50320e
md"""
## Function
"""

# ╔═╡ 31045c52-2145-4d47-a261-80c5b25765ed
begin # helper functions
	min_down(x; digits=1) = floor(min(x...); digits=digits)
	max_up(x; digits=1) = ceil(max(x...); digits=digits)
end;	

# ╔═╡ 8dfdaa40-bc66-4acf-83a4-b5c7a689bc6a
const pluto_cell_width = 340 # AUTOMATE

# ╔═╡ eb96b1f6-d277-4158-96f7-52c71f4a6be2
"""
	inspect(signal::AbstractArray)

Opens a `WGLMakie.jl/JSServe.jl` powered widget in the corresponding cell which has two sliders, allowing the user to scroll over the input `signal` and "zooming" into parts of it.

# TODO:
* fix magic numbers: `68`, `204`
* add heuristics for `[min|max]_y`
* fix limits 
* fix dpi in `Figure(; resolution=XXX)`
* expose variables
"""
function inspect(signal::AbstractArray, full_length=5_000, detail_length=500)
	len_signal = length(signal)
	max_window, min_window = let (min_w, max_w) = extrema(signal) # single pass
		((max_w > 0) ? (max_w * 1.05) : (max_w * 0.95)),
		((min_w < 0) ? (min_w * 1.05) : (min_w * 0.95)) # ± 5%
	end
	percent = len_signal ÷ 100 # div → some values may get lost?!

	return App() do		
		window_pos = JSServe.Slider(0:99; style="width: 100%;", class="mt-3")
		window_width = JSServe.Slider(1:100; style="width: 100%;", class="my-3")

		
		@timeit to "full signal" begin
			fig_full = Figure(resolution=(pluto_cell_width, 68) .* 4)
			ax_full = Axis(fig_full[1, 1])
			hidexdecorations!(ax_full, grid=false)
			step_full = min(len_signal ÷ full_length, 1)
			lines!(ax_full, signal[1:step_full:end])
			xlims!(ax_full, 1, len_signal ÷ step_full)
		end

		
		@timeit to "window" begin
			step_window = (len_signal ÷ step_full) ÷ 100
			@timeit to "window lift" window = lift(window_pos, window_width) do x, Δx
				Makie.Point2f[
					(x * step_window, min_window), # bottom left
					((x + Δx) * step_window, min_window), # bottom right
					((x + Δx) * step_window, max_window), # top right
					(x * step_window, max_window) # top left
				]
			end
			poly!(ax_full, window; color=Makie.RGBAf(0.0, 0.1, 0.4, 0.2))
		end

		
		@timeit to "detail signal" begin
			fig_detail = Figure(resolution=(pluto_cell_width, 204) .* 4) 
			ax_detail = Axis(fig_detail[1, 1])
			hidexdecorations!(ax_detail, grid=false)	
			@timeit to "detail lift" detail = lift(window_pos, window_width) do x, Δx
				hi = max(1, min((x + Δx) * percent, len_signal))
				lo = max(1, x * percent)
				step_detail = max((hi - lo) ÷ detail_length, 1)
				span = lo:step_detail:hi
				tmp = signal[span]
				xlims!(ax_detail, 1, length(span))
				ylims!(ax_detail, min_down(tmp), max_up(tmp))
				return tmp
			end
			lines!(ax_detail, detail)
		end

	
		JSServe.columns(
			JSServe.TailwindCSS,
			fig_full,
			JSServe.columns(
				window_pos, 
				window_width;
				class="ml-5 mr-2",
			),
			fig_detail,
		)
	end
end

# ╔═╡ f362433f-f002-400f-b230-642a00198b93


# ╔═╡ cec616cd-04fb-442b-8780-bbf20d7bc1d3
md"""
## Execution
"""

# ╔═╡ e2b83d08-4598-47ad-a2ff-faf959fd9f67
begin
	t = 1:1_000_000
	y = @. sin(t / 1200π) * cos(t / 4800π)
end;

# ╔═╡ 77a6db6d-948a-4632-a54e-d17817549d68
@timeit to "widget" inspect(y)

# ╔═╡ b5c8f85f-c3ad-4cfe-9fa4-dbca330be64b
to

# ╔═╡ 299b4af4-5279-455f-917a-0dad959684ca
md"""
```
 ──────────────────────────────────────────────────────────────────────────
                                   Time                   Allocations      
                           ──────────────────────   ───────────────────────
     Tot / % measured:           425s / 1.90%           8.63GiB / 2.66%    

 Section           ncalls     time   %tot     avg     alloc   %tot      avg
 ──────────────────────────────────────────────────────────────────────────
 first plot             1    4.31s  53.5%   4.31s    144MiB  61.3%   144MiB
 widget                 1    3.75s  46.5%   3.75s   91.0MiB  38.7%  91.0MiB
   detail signal        1    943ms  11.7%   943ms   24.9MiB  10.6%  24.9MiB
     detail lift        1    631ms  7.82%   631ms   7.21MiB  3.06%  7.21MiB
   full signal          1    566ms  7.01%   566ms   26.2MiB  11.1%  26.2MiB
   window               1    219ms  2.71%   219ms   3.91MiB  1.66%  3.91MiB
     window lift        1    133ms  1.66%   133ms   28.1KiB  0.01%  28.1KiB
 load packages          1    707μs  0.01%   707μs   24.0KiB  0.01%  24.0KiB
 page call              1   47.0μs  0.00%  47.0μs   6.44KiB  0.00%  6.44KiB
 ──────────────────────────────────────────────────────────────────────────
```
```
──────────────────────────────────────────────────────────────────────────
                                   Time                   Allocations      
                           ──────────────────────   ───────────────────────
     Tot / % measured:           369s / 1.96%           8.58GiB / 2.27%    

```
with sysimage:
```
 ────────────────────────────────────────────────────────────────────────
                                 Time                   Allocations      
                         ──────────────────────   ───────────────────────
    Tot / % measured:          270s / 5.79%           8.90GiB / 3.95%    

```
"""

# ╔═╡ 68e63293-f723-4d18-93be-05ed8baa17c9
begin
	mem = Int64(1e9)
	mem_num = sizeof(1.0)
	N₂ = mem ÷ mem_num
	t₂ = range(0, 1, length = N₂+1)
	fc₂, freq₂ = 1000, 2
	y₂ = @. sin(2π * fc₂ * t₂) * cos(2π * freq₂ * t₂)
end;

# ╔═╡ 4cbcc77f-c197-47f6-9fb5-b5452cf7b3b8
inspect(y₂)

# ╔═╡ a095909c-1cd2-4266-968a-5b027ac95128
begin
	N_3 = mem ÷ mem_num
	t_3 = range(0, 1, length = N_3+1)
	fc_3, freq_3 = 1000, 2
	y_3 = @. sin(2π * fc_3 * t_3) * cos(2π * freq_3 * t_3)
end;

# ╔═╡ Cell order:
# ╟─b264768c-4d81-4d90-b179-e7567bfb3142
# ╟─4992f5d2-619c-4d7b-9725-155f64b75712
# ╟─6b9914b9-b652-4a1f-badf-69b124e93380
# ╠═ffa12350-4ea7-11ec-159f-6926d19c55af
# ╠═dc5512e1-17e4-432a-a1be-1924b922449c
# ╠═56b1a3e3-3f5d-4952-ab21-96c74e253595
# ╠═aab2cb9f-90e9-4d32-a920-68f632b9200d
# ╟─57914f0f-67a1-467e-ad75-226d151e363a
# ╟─66977069-a913-49ef-935c-d74864cb001d
# ╟─81319b09-e179-40b9-adb7-192266c677fe
# ╟─245a4d89-6e3d-4f4f-ab67-8f292c50320e
# ╠═31045c52-2145-4d47-a261-80c5b25765ed
# ╠═8dfdaa40-bc66-4acf-83a4-b5c7a689bc6a
# ╠═eb96b1f6-d277-4158-96f7-52c71f4a6be2
# ╟─f362433f-f002-400f-b230-642a00198b93
# ╟─cec616cd-04fb-442b-8780-bbf20d7bc1d3
# ╠═e2b83d08-4598-47ad-a2ff-faf959fd9f67
# ╠═77a6db6d-948a-4632-a54e-d17817549d68
# ╠═b5c8f85f-c3ad-4cfe-9fa4-dbca330be64b
# ╟─299b4af4-5279-455f-917a-0dad959684ca
# ╠═68e63293-f723-4d18-93be-05ed8baa17c9
# ╠═4cbcc77f-c197-47f6-9fb5-b5452cf7b3b8
# ╠═a095909c-1cd2-4266-968a-5b027ac95128
