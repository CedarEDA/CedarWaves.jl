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

# ╔═╡ 3e97a23a-4ed4-11ec-387d-8d32c9b6eea7
begin
	using Pkg
    Pkg.activate(Base.current_project())
	using CedarWaves, Plots, NgSpice, JLD, PlutoUI
end

# ╔═╡ 486489b2-8e0d-411a-b799-fbcf1b48d021
# run the simulation
begin
	# NgSpice.init()
	# NgSpice.source("upconvert_tb.spice")
	# NgSpice.run()
	# _, _, out_p = NgSpice.getvec("out_p")
	# _, _, out_n = NgSpice.getvec("out_n")
	# _, _, t = NgSpice.getvec("TIME")
	# save("simdata.jld", "t", t, "out_p", out_p, "out_n", out_n)
	md"**1. Run the simulation:**"
end

# ╔═╡ a16cc97a-c509-42de-84fc-62010729f908
begin
	d = load(joinpath(@__DIR__, "simdata.jld"))
	t = d["t"]
	out_p = d["out_p"]
	out_n = d["out_n"]
	md"**2. Load the transient results:**"
end

# ╔═╡ ea505e1a-8ffe-40ca-b836-cc75ae1e511d
# make signal
p = PWL(t, out_p);

# ╔═╡ 5aa085bf-1445-467a-a6db-462363c2b166
n = PWL(t, out_n);

# ╔═╡ e0ef3ad3-499f-433a-a3df-46b1a4816570
md"**3. Calculate the difference of the differential signals:**"

# ╔═╡ ae4deee9-6b7b-478b-b92a-cfd50662b49a
diff = p-n

# ╔═╡ f299e984-cc11-429f-a417-f0f84cc3c771
md"**4. Cut away the initial startup to get to steady state:**"

# ╔═╡ d102e48d-5ba0-4e51-8f70-a3b5ff544ec0
# cut away the startup part
clipped = clip(diff, cross(diff, 0.3)..xmax(diff))

# ╔═╡ 8a3fd938-fdbb-433b-8e7c-7265479fbb48
md"**5. Zoom in on the signal using `clip` with range slider:**"

# ╔═╡ 923945b5-1a7c-41dd-a503-d52bfcfd40c3
@bind cliprange RangeSlider(0.9:0.001:1; default=0.94:0.001:0.95)

# ╔═╡ a18c30f6-93ed-4c38-bc02-8ec0890c0d97
x1 = xmin(clipped) + xspan(clipped)*first(cliprange)

# ╔═╡ b2fcd2a7-3770-40e0-ad68-f2df3182e9e5
x2 = xmin(clipped) + xspan(clipped)*last(cliprange)

# ╔═╡ 1db61f19-0a1d-4131-8d40-cce220cffee7
rawsection = clip(clipped, x1..x2)

# ╔═╡ 686666d6-161c-4f47-b320-bc71984f3108
md"**6. Perform a periodic clip to get a nice frequency spectrum:**"

# ╔═╡ 2968dc7f-6432-4cd8-8824-dd27821caefd
section = clipcrosses(rawsection, rising(0.0))

# ╔═╡ ac32e83d-6b44-4feb-9061-9da60d79f195
md"**7. Take the Fourier Series to see frequency domain:**"

# ╔═╡ 9f23a77c-bfdc-4e5b-a84f-f88b795619fe
fs = FS(section; clip=0..2e10)

# ╔═╡ 5ccb95ca-ae5f-41da-944a-291d8dc36c9f
wsection = window(section)

# ╔═╡ 229e820a-4f95-4763-9367-2a67adc7a5c6
md"**8. Take the Fourier Transform:**"

# ╔═╡ 86665dfa-0776-4f48-85bb-707ed9c39d3c
ft = FT(wsection; clip=0..2e10)

# ╔═╡ ba11c61d-865f-4d92-b71e-a62fbe401ed7
freq, ampl = xymax(abs(fs))

# ╔═╡ fd8e6685-9e3a-49bd-bcbc-70bc941f064f
md"**9. Demodulate the signal**"

# ╔═╡ 169bc712-f52f-401f-8e4c-5abf27c85051
begin
	# demodulate
	sn = SIN(amp=1, freq=freq);
	plot(clip(sn, basedomain(sn)))
end

# ╔═╡ 7ec638c8-4e76-4d0e-a5f2-80d6e9ac6f34
dm = clipped*sn

# ╔═╡ d1ce89e8-0db6-473e-99d0-0520beb6de0d
md"**10. View the frequency domain of the demodulated signal:**"

# ╔═╡ 8a2a6d44-4df1-4add-9cdf-b71beeecf7e8
# in this case DFT is a lot faster because it doesn't integrate the whole RF signal
dmft = DFT(dm; N=1000)

# ╔═╡ d2db3582-cffd-4b7c-87bb-e5528a1654bd
# fir filter
flt = firfilter(Lowpass(freq/100), 1e-7)

# ╔═╡ cea6efb1-d0aa-4f21-be79-41d43fd613f1
# this is really slow, don't display
baseband = clip(convolution(dm, flt), domain(dm));

# ╔═╡ 6a61b572-fa4f-4eec-bcfb-9476e0257d44
@bind order PlutoUI.Slider(1:5)

# ╔═╡ 607d2da5-3576-4b78-b257-d6d1748f6981
# iir filter
iirflt = CedarWaves.iirfilter(Lowpass(freq/100), Butterworth(order))

# ╔═╡ cb668118-47fa-42ae-865f-79097aa095eb
@time sol = CedarWaves.filt(iirflt, dm)

# ╔═╡ 3e2cce1e-4e22-4ccd-8cb3-90302b36a2d8
md"Check to save results: $(@bind do_save CheckBox(default=false))"

# ╔═╡ 327f601e-7539-4db2-a818-bacdfbafe1b4
if do_save
	JLD.save("demodulated.jld", "dmx", xvals(dm), "dmy", yvals(dm))
end

# ╔═╡ Cell order:
# ╟─3e97a23a-4ed4-11ec-387d-8d32c9b6eea7
# ╟─486489b2-8e0d-411a-b799-fbcf1b48d021
# ╟─a16cc97a-c509-42de-84fc-62010729f908
# ╠═ea505e1a-8ffe-40ca-b836-cc75ae1e511d
# ╠═5aa085bf-1445-467a-a6db-462363c2b166
# ╟─e0ef3ad3-499f-433a-a3df-46b1a4816570
# ╠═ae4deee9-6b7b-478b-b92a-cfd50662b49a
# ╟─f299e984-cc11-429f-a417-f0f84cc3c771
# ╠═d102e48d-5ba0-4e51-8f70-a3b5ff544ec0
# ╟─8a3fd938-fdbb-433b-8e7c-7265479fbb48
# ╠═923945b5-1a7c-41dd-a503-d52bfcfd40c3
# ╠═a18c30f6-93ed-4c38-bc02-8ec0890c0d97
# ╠═b2fcd2a7-3770-40e0-ad68-f2df3182e9e5
# ╠═1db61f19-0a1d-4131-8d40-cce220cffee7
# ╟─686666d6-161c-4f47-b320-bc71984f3108
# ╠═2968dc7f-6432-4cd8-8824-dd27821caefd
# ╟─ac32e83d-6b44-4feb-9061-9da60d79f195
# ╠═9f23a77c-bfdc-4e5b-a84f-f88b795619fe
# ╠═5ccb95ca-ae5f-41da-944a-291d8dc36c9f
# ╟─229e820a-4f95-4763-9367-2a67adc7a5c6
# ╠═86665dfa-0776-4f48-85bb-707ed9c39d3c
# ╠═ba11c61d-865f-4d92-b71e-a62fbe401ed7
# ╟─fd8e6685-9e3a-49bd-bcbc-70bc941f064f
# ╠═169bc712-f52f-401f-8e4c-5abf27c85051
# ╠═7ec638c8-4e76-4d0e-a5f2-80d6e9ac6f34
# ╟─d1ce89e8-0db6-473e-99d0-0520beb6de0d
# ╠═8a2a6d44-4df1-4add-9cdf-b71beeecf7e8
# ╠═d2db3582-cffd-4b7c-87bb-e5528a1654bd
# ╠═cea6efb1-d0aa-4f21-be79-41d43fd613f1
# ╠═6a61b572-fa4f-4eec-bcfb-9476e0257d44
# ╠═607d2da5-3576-4b78-b257-d6d1748f6981
# ╠═cb668118-47fa-42ae-865f-79097aa095eb
# ╟─3e2cce1e-4e22-4ccd-8cb3-90302b36a2d8
# ╠═327f601e-7539-4db2-a818-bacdfbafe1b4
