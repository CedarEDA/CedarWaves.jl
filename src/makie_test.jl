using WGLMakie
struct MySignal
    x::Vector{Float64}
    y::Vector{Float64}
    function MySignal(xs, ys)
        @assert length(xs) == length(ys) "x and y must be same length"
        new(xs, ys)
    end
end
function MySignal(ys::Vector)
    MySignal(0:length(ys)-1, ys)
end


# Default to dark theme
WGLMakie.set_theme!(theme_light())

# https://github.com/MakieOrg/Makie.jl/pull/3043
Makie.theme(::Nothing) = Makie.CURRENT_DEFAULT_THEME

@recipe(TestPlot) do scene
    # errorcolor default based on background lightness
    errc = lift(theme(scene, :backgroundcolor), theme(scene, :errorcolor)) do bgc, errc
        bgc = Makie.Colors.parse(Makie.Colors.Colorant, bgc)
        l = convert(Makie.Colors.HSL, bgc).l
        default = if l > .5
            Makie.RGBAf(1, 0, 0, .2)
        else
            Makie.RGBAf(1, 0, 0, .8)
        end
        something(errc, default)
    end

    Attributes(
        color = theme(scene, :linecolor),
        colormap = theme(scene, :colormap),
        # https://github.com/MakieOrg/Makie.jl/pull/3046
        xgridcolor = get(something(theme(scene, :Axis), Attributes()), :xgridcolor, RGBAf(0, 0, 0, 0.12)),
        colorrange = Makie.automatic,
        markersize = 25,
        errorcolor = errc,
        cycle = [:color],
        linewidth = 2,
        # Min points to plot (2x horiz resolution to get sharp vertical edges)
        min_pts = lift(xy -> 2*xy[2], theme(scene, :resolution)),
        highlight_color = :orange,
        #lowlight_color = Makie.RGBAf(0.0f0,0.44705883f0,0.69803923f0, 1f0),
    )
end

function Makie.plot!(plt::TestPlot{<:Tuple{MySignal}})
    if true
        lines!(plt, 0..15, sin, label = "sin", color = :blue)
        lines!(plt, 0..15, cos, label = "cos", color = :red)
        lines!(plt, 0..15, x -> -cos(x), label = "-cos", color = :green)
        vlines!(plt, 5, color = :orange, linewidth = 2, label = "vline")
    else
        s = plt[1]
        x = @lift $s.x
        y = @lift $s.y
        sc = scatter!(plt, x, y; plt.color, plt.colormap, plt.colorrange, plt.linewidth, plt.label)
        li = lines!(plt, x, y; plt.color, plt.colormap, plt.colorrange, plt.linewidth, plt.label)
        xvline = @lift $s.x[end÷2]
        vl = vlines!(plt, xvline; color=(:orange, 0.7), linewidth=2, label="vline")
    end
end

function Base.show(io::IO, m::MIME"juliavscode/html", s::MySignal)
    f = Figure()
    ax = Axis(f[1,1])
    if true
        testplot!(s)
    else
        lines!(0..15, sin, label = "sin", color = :blue)
        lines!(0..15, cos, label = "cos", color = :red)
        lines!(0..15, x -> -cos(x), label = "-cos", color = :green)
        vlines!(5, color = :orange, linewidth = 2, label = "vline")
    end
    f[1, 2] = Legend(f, ax, "Trig Functions", framevisible = false)
    Base.show(io, m, f)
end


s = MySignal(rand(20))