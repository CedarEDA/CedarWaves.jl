### A Pluto.jl notebook ###
# v0.17.2

using Markdown
using InteractiveUtils

# ╔═╡ c0474120-5650-11ec-35a6-df66ce1a7495
begin
	# To run in REPL: import Pluto; Pluto.run() # and then load rms.jl in browser
    import Pkg
    Pkg.activate(temp=true)
    Pkg.develop(path="../..")
    Pkg.add(["Plots", "PlutoUI", "PyCall"])
	using Plots
	gr() # use GR backend for Plots
	using PlutoUI, CedarWaves
end

# ╔═╡ c2202edf-3a1b-46e4-add0-117380a67ed5
f(x) = 2x + 1

# ╔═╡ 053b5ce8-322e-406c-948e-f29f2a515db0
f(10)

# ╔═╡ 98f983e6-dcbf-4e6e-b8d7-18ec19b876a3


# ╔═╡ Cell order:
# ╟─c0474120-5650-11ec-35a6-df66ce1a7495
# ╠═c2202edf-3a1b-46e4-add0-117380a67ed5
# ╠═053b5ce8-322e-406c-948e-f29f2a515db0
# ╠═98f983e6-dcbf-4e6e-b8d7-18ec19b876a3
