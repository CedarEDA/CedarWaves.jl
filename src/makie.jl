using WGLMakie
using WGLMakie.Makie.Observables
using Printf
import StatsBase

# Default to dark theme
#WGLMakie.set_theme!(theme_light())


# Makie doesn't allow Cycled(id) to RBGA conversion inside recipe so need to do it here:
const color_cycle = [ i => rgba for (i, rgba) in pairs(
                            [   RGBAf(0.0f0,0.44705883f0,0.69803923f0,1.0f0)
                                RGBAf(0.9019608f0,0.62352943f0,0.0f0,1.0f0)
                                RGBAf(0.0f0,0.61960787f0,0.4509804f0,1.0f0)
                                RGBAf(0.8f0,0.4745098f0,0.654902f0,1.0f0)
                                RGBAf(0.3372549f0,0.7058824f0,0.9137255f0,1.0f0)
                                RGBAf(0.8352941f0,0.36862746f0,0.0f0,1.0f0)
                                RGBAf(0.9411765f0,0.89411765f0,0.25882354f0,1.0f0)
                                RGBAf(0.0f0,0.44705883f0,0.69803923f0,1.0f0)
                                RGBAf(0.9019608f0,0.62352943f0,0.0f0,1.0f0)
                                RGBAf(0.0f0,0.61960787f0,0.4509804f0,1.0f0)
                                RGBAf(0.8f0,0.4745098f0,0.654902f0,1.0f0)
                                RGBAf(0.3372549f0,0.7058824f0,0.9137255f0,1.0f0)
                                RGBAf(0.8352941f0,0.36862746f0,0.0f0,1.0f0)
                                RGBAf(0.9411765f0,0.89411765f0,0.25882354f0,1.0f0)
                            ])
                        ]
@recipe(SignalPlot) do scene
    # errorcolor default based on background lightness
    errc = lift(theme(scene, :backgroundcolor, default=nothing), theme(scene, :errorcolor, default=nothing)) do bgc, errc
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
        markersize = 20,
        errorcolor = errc,
        cycle = [:color],
        linewidth = 2,
        # Min points to plot (2x horiz resolution to get sharp vertical edges)
        min_pts = lift(xy -> 2*xy[2], theme(scene, :size)),
        max_scatter_points = 200,
        label = "signal",
        highlight_color = :orange,
        show_index = true,
        sigdigits=9,
        color_id=1,
    )
end

# A recepie for plotting the values of a measure (no signal)
@recipe(MeasureValues) do scene
    # errorcolor default based on background lightness
    errc = lift(theme(scene, :backgroundcolor, default=nothing), theme(scene, :errorcolor, default=nothing)) do bgc, errc
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
        markersize = 20,
        errorcolor = errc,
        cycle = [:color],
        linewidth = 2,
        max_scatter_points = 200,
        label = "signal",
        highlight_color = :orange,
        show_index = true,
        xscale = identity,
        yscale = identity,
        sigdigits=9,
        color_id=1,
    )
end


@recipe(MeasureDensity) do scene
    # errorcolor default based on background lightness
    errc = lift(theme(scene, :backgroundcolor, default=nothing), theme(scene, :errorcolor, default=nothing)) do bgc, errc
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
        markersize = 20,
        errorcolor = errc,
        cycle = [:color],
        linewidth = 2,
        max_scatter_points = 200,
        label = "signal",
        highlight_color = :orange,
        xscale = identity,
        yscale = identity,
        show_index = true,
        sigdigits=9,
        color_id=1,
    )
end

# For supporting db10 and dB20 x and y scales:
Makie.inverse_transform(::typeof(dB20)) = db -> exp10(db/20)
Makie.inverse_transform(::typeof(dB10)) = db -> exp10(db/10)
Makie.inverse_transform(::typeof(dBm)) = db -> exp10((db-30)/10)
Makie.defaultlimits(scale::typeof(dB20)) = let inv_scale = inverse_transform(scale)
    (inv_scale(0.0), inv_scale(3.0))
end
Makie.defaultlimits(scale::typeof(dB10)) = let inv_scale = inverse_transform(scale)
    (inv_scale(0.0), inv_scale(3.0))
end
Makie.defaultlimits(scale::typeof(dBm)) = let inv_scale = inverse_transform(scale)
    (inv_scale(0.0), inv_scale(3.0))
end
Makie.defined_interval(::typeof(dB20)) = Makie.IntervalSets.OpenInterval(0.0, Inf)
Makie.defined_interval(::typeof(dB10)) = Makie.IntervalSets.OpenInterval(0.0, Inf)
Makie.defined_interval(::typeof(dBm)) = Makie.IntervalSets.OpenInterval(0.0, Inf)

function Makie.plot!(plt::SignalPlot{<:Tuple{T}}) where {T <: AbstractSignal}
    s = plt[1]
    label = get(plt, :label, "signal")
    s = @lift default_transform($s)($s)
    x = @lift xvals($s)
    y = @lift yvals($s)
    inspectable = get(plt, :inspectable, false)
    if T <: AbstractContinuousSignal
        if ispwc(s[]) # ispwc is unreliable so this may not always work
            return stairs!(plt, x, y; step = :post, plt.color, plt.colormap, plt.colorrange, plt.linewidth, label, inspectable)
        end
        max_scatter_points = plt.max_scatter_points
        N = @lift length($s)
        dom = @lift domain($s)
        if N[] < max_scatter_points[]
            #plotting sparse sampled continuous
            scatter!(plt, x, y; plt.color, plt.colormap, plt.colorrange, plt.linewidth, label, inspectable)
            lines!(plt, x, y; plt.color, plt.colormap, plt.colorrange, plt.linewidth, label, inspectable=false)
            #f = current_figure()
            #Legend(f[1,1], [[sc, li]], ["signal"], tellwidth=false, tellheight=false)
        else
            # Densely sampled continuous signal
            lines!(plt, x, y; plt.color, plt.colormap, plt.colorrange, plt.linewidth, label, inspectable)
        end
    elseif T <: AbstractSignal
        # discete signal
        scatter!(plt, x, y; plt.color, plt.colormap, plt.colorrange, label, inspectable)
        lines!(plt, x, y; plt.color, plt.colormap, plt.colorrange, plt.linewidth, label, inspectable=false)
    end
    return plt
end

idx2str(midx::Int) = "[$(midx)]"
idx2str(midx::CartesianIndex) = "[" * join(Tuple(midx), ",") * "]"

default_title(m::AbstractMeasure) = string(m.name, " = ", display_value(m))
function default_title(s::AbstractSignal)
    io = IOBuffer()
    show(io, MIME"text/plain"(), s)
    title = String(take!(io))
end
function default_title(signals::AbstractArray{<:AbstractSignal, D}) where D
    N = length(signals)
    Ns = N != 1 ? "s" : ""
    title = "$N signal$Ns"
    if D > 1
        title *= " ($(D)D of size " * join(size(signals), " x ") * ")"
    end
    return title
end

"""
    allsame(predicate, vals, default)
If all `vals` are equal for each `predicate(val)` then
return the same value, otherwise return `default`.
"""
function allsame(predicate, vals, default)
    if length(vals) == 0
        return default
    end
    if allequal(predicate.(vals))
        return predicate(first(vals))
    else
        return default
    end
end

function is_freq_signal(signal::AbstractSignal)
    ytype(signal) <: Complex && xmin(signal) > 0 && xmax(signal) > 100
end


function default_transform(signal::AbstractSignal)
    s = signal
    if is_freq_signal(signal)
        dB10
    elseif ytype(signal) <: Complex
        abs
    else
        identity
    end
end
function default_transform(measure::AbstractMeasure)
    default_transform(get_signals(measure))
end
function default_transform2(signal::AbstractSignal)
    s = signal
    if ytype(signal) <: Complex
        phased
    else
        identity
    end
end
function default_transform(signals)
    allsame(default_transform, signals, identity)
end

function default_transform2(measure::AbstractMeasure)
    default_transform2(get_signals(measure))
end
function default_transform2(signals)
    allsame(default_transform2, signals, identity)
end

function default_xscale(signal::AbstractSignal)
    if is_freq_signal(signal)
        return log10
    else
        return identity
    end
end
function default_xscale(measure::AbstractMeasure)
    default_xscale(get_signals(measure))
end
function default_xscale(signals)
    allsame(default_xscale, signals, identity)
end

function default_yscale(signal::AbstractSignal)
    if is_freq_signal(signal)
        return identity
    else
        return identity
    end
end
function default_yscale(measure::AbstractMeasure)
    default_yscale(get_signals(measure))
end
function default_yscale(signals)
    allsame(default_yscale, signals, identity)
end

function default_yscale2(signal::AbstractSignal)
    if is_freq_signal(signal)
        return identity
    else
        return identity
    end
end
function default_yscale2(measure::AbstractMeasure)
    default_yscale2(get_signals(measure))
end
function default_yscale2(signals)
    allsame(default_yscale2, signals, identity)
end

function default_ylabel(signal::AbstractSignal)
    if is_freq_signal(signal)
        return "Magnitude (dB10)"
    elseif ytype(signal) <: Complex
        return "Magnitude"
    else
        return "Amplitude"
    end
end
function default_ylabel(measure::AbstractMeasure)
    default_ylabel(get_signals(measure))
end
function default_ylabel(signals)
    allsame(default_ylabel, signals, "")
end

function default_ylabel2(signal::AbstractSignal)
    if ytype(signal) <: Complex
        return "Phase (°)"
    else
        return ""
    end
end
function default_ylabel2(measure::AbstractMeasure)
    default_ylabel2(get_signals(measure))
end
function default_ylabel2(signals)
    allsame(default_ylabel2, signals, "")
end

function default_xlabel(signal::AbstractSignal)
    is_freq_signal(signal) ? "Frequency (Hz)" : ""
end
function default_xlabel(measure::AbstractMeasure)
    default_xlabel(get_signals(measure))
end
function default_xlabel(signal_or_array)
    allsame(default_xlabel, signal_or_array, "")
end

function default_xtickformat(; sigdigits=7)
    values -> display_value.(values; sigdigits)
end
function default_ytickformat(; sigdigits=7)
    values -> display_value.(values; sigdigits)
end

function inspect(signal::AbstractSignal;
                                    sigdigits=9,
                                    xlabel=default_xlabel(signal),
                                    ylabel=default_ylabel(signal),
                                    ylabel2=default_ylabel2(signal),
                                    title=default_title(signal),
                                    xscale=default_xscale(signal),
                                    yscale=default_yscale(signal),
                                    yscale2=default_yscale2(signal),
                                    transform=default_transform(signal),
                                    transform2=default_transform2(signal),
                                    xtickformat=default_xtickformat(),
                                    ytickformat=default_ytickformat())
    fig = Figure(; fontsize=18)
    if ytype(signal) <: Complex
        ax1 = Axis(fig[1,1]; xlabel, ylabel, title, xscale, yscale, xtickformat, ytickformat)
        signalplot!(ax1, transform(signal), color=Makie.wong_colors()[1])
        ax2 = Axis(fig[1,1]; xlabel, ylabel=ylabel2, xscale, yscale=yscale2, xtickformat, ytickformat)
        ax2.yaxisposition = :right
        linkxaxes!(ax1, ax2)
        signalplot!(ax2, transform2(signal), color=Makie.wong_colors()[2])
    elseif ytype(signal) <: Real
        ax1 = Axis(fig[1,1]; xlabel, ylabel, title, xscale, yscale, xtickformat, ytickformat)
        signalplot!(ax1, transform(signal), color=Makie.wong_colors()[1])
    else
        error("Don't know how to plot signals with ytype $(ytype(signal))")
    end
    return fig
end

function Base.show(io::IO, mime::MIME"text/plain", s::T) where {T<:AbstractSignal}
    t = string(T)
    t = replace(t, r"{.*" => "")
    compact = get(io, :compact, false)
    if compact
        printstyled(io, t, bold=true, underline=true)
    else
        t = "$(length(s))-point $t"
        printstyled(io, t, bold=true, underline=true)
    end
end
function Base.show(io::IO, s::T) where {T<:AbstractSignal}
    show(io, MIME"text/plain"(), s)
end

function default_axis_kwargs(; sigdigits=9, xlabel="", ylabel="", title="",
                               xscale=identity, yscale=identity,
                               xtickformat = default_xtickformat(),
                               ytickformat = default_ytickformat(),
                               kwargs...
                               )
    (; xlabel, ylabel, ytickformat, xtickformat, title, xscale, yscale, kwargs...)
end

function default_plot_kwargs(; linewidth=2, color=nothing, kwargs...)
    kwargs2 = (; linewidth)
    if !isnothing(color)
        kwargs2 = merge(kwargs2, (; color))
    end
    kwargs2 = merge(kwargs2, kwargs)
    return kwargs2
end

# matches kwargs that have same size of signals
function default_plot_kwargs(signal_size::Tuple, idx::CartesianIndex; linewidth=2, color=nothing, kw...)
    if !isnothing(color) && (color isa AbstractArray && size(color) == signal_size)
        c = color[idx]
    else
        c = color
    end
    if linewidth isa AbstractArray && size(linewidth) == signal_size
        lw = linewidth[idx]
    else
        lw = linewidth
    end
    kwargs = (; linewidth=lw)
    if !isnothing(color)
        kwargs = merge(kwargs, (; color=c))
    end
    kwargs = merge(kwargs, kw)
    return kwargs
end

function inspect(signals_array::AbstractArray{<:AbstractSignal, D}; sigdigits=9,
                                                                    title=default_title(signals_array),
                                                                    xlabel=default_xlabel(signals_array),
                                                                    ylabel=default_ylabel(signals_array),
                                                                    xscale=default_xscale(signals_array),
                                                                    yscale=default_yscale(signals_array),
                                                                    xtickformat=default_xtickformat(),
                                                                    ytickformat=default_ytickformat(),
                                                                    linewidth=2, color=nothing) where D
    N = length(signals_array)
    signals = vec(signals_array)
    colors_for_signals = calculate_colors(signals) # [signal1 => color1, signal2 => color2, ...]
    f = Figure()
    ax = Axis(f[1,1]; default_axis_kwargs(; sigdigits, xlabel, ylabel, title, xscale, yscale, xtickformat, ytickformat)...)
    for i in CartesianIndices(signals_array)
        color = getcolor(colors_for_signals, signals_array[i])
        t = Tuple(i)
        inds = collect(t)
        label = "signal[" * join(inds, ",") * "]"
        signalplot!(ax, signals_array[i]; color, label)
    end
    if N <= 30
        Legend(f[1,2], ax; merge=true, unique=false, tellheight=false, tellwidth=true)
    end
    DataInspector(ax)
    return f
end
# Vector of Vector of signals is a vertical stack plot of length of outer vector, each subplot has the vector of signals within it
function inspect(signals::Vector{<:AbstractVector{<:AbstractSignal}}; sigdigits=9, title="", xlabel="", ylabel="",
                                                                      linewidth=2, color=nothing,
                                                                      linkxaxes=true, linkyaxes=false,
                                                                      xscale=nothing, yscale=nothing)
    f = Figure()
    # Verticle stack of axes per outer vector
    axs = [Axis(f[i,1]; default_axis_kwargs(; sigdigits,
                            xlabel=default_xlabel(signals[i]),
                            ylabel=default_ylabel(signals[i]),
                            title=default_title(signals[i]),
                            xscale=something(xscale, default_xscale(signals[i])),
                            yscale=something(yscale, default_yscale(signals[i])))...) for i in 1:size(signals, 1)]
    if linkxaxes
        linkxaxes!(axs...)
    end
    if linkyaxes
        linkyaxes!(axs...)
    end
    num = 0
    for i in 1:size(signals, 1)
        ax = axs[i, 1]
        N = size(signals[i], 1)
        for j in 1:N
            num += 1
            if isnothing(color)
                c = Cycled(num)
            else
                c = color
            end
            label = "signal[$i][$j]"
            signalplot!(ax, signals[i][j]; label, linewidth, color=c,
                                default_plot_kwargs(size(signals), CartesianIndex(i))...)

            # Legend appearance is buggy:
            #if N <= 30
            #    Legend(f[i,2], ax; merge=true, unique=false, tellheight=false, tellwidth=true)
            #end
            #DataInspector(ax)
        end
    end
    return f
end

## Measures
function Base.show(io::IO, ::MIME"text/plain", m::AbstractMeasure)
    compact = get(io, :compact, false)
    if compact
        printstyled(io, display_value(m; sigdigits=3), bold=true, underline=true)
    else
        printstyled(io, display_value(m), bold=true, underline=true)
    end
end
function Base.show(io::IO, m::AbstractMeasure)
    show(io, MIME"text/plain"(), m)
end
function Base.show(io::IO, mime::MIME"text/plain", m::Threshold)
    println(display_value(m))
end
function Base.show(io::IO, m::Threshold)
    show(io, MIME"text/plain"(), m)
end
function marker(m::CrossMeasure)
    marker(m.yth)
end
function marker(m::OnePointMeasure)
    marker(m.y)
end
function marker(m::XMeasure)
    :vline
end
function marker(m::Float64)
    :circle
end
function marker(m::YMeasure)
    :hline
end
function marker(m::YLevelMeasure)
    :hline
end
function marker(m::Threshold)
    if m isa rising
        return :utriangle
    elseif m isa falling
        return :dtriangle
    end
    return :diamond
end


function set_alpha(c::Makie.ColorTypes.RGBA, alpha_pct::Real)
    Makie.RGBAf(c.r, c.g, c.b, alpha_pct)
end
function set_alpha(c::Tuple{Symbol, <:Real}, alpha_pct::Real)
    (first(c), alpha_pct)
end
function set_alpha(c::Symbol, alpha_pct::Real)
    (c, alpha_pct)
end

function inspect(th::Threshold; xlabel="", ylabel="", title=display_value(th),
                                xtickformat=default_xtickformat(),
                                ytickformat=default_ytickformat())
    f = Figure()
    ax = Axis(f[1,1]; default_axis_kwargs(; sigdigits, xlabel, ylabel, title, xtickformat, ytickformat)...)
    signalplot!(ax, th)
    return f
end

function linecolor(plt, th::Threshold)
    set_alpha(plt.color[], 0.5)
end
function linecolor(plt, m::XMeasure)
    set_alpha(plt.color[], 0.5)
end

"""
    PlotArgs(inspector_args, signal, marker, x, y)

PlotArgs represents the information for each maker to be plotted per measurement.
Each marker is expected to have a signal, marker, x, and y value.  If a measure has
multiple markers then multiple PlotArgs should be passed in the functions
`plot_measure_signals` (for markers on the signal) and `plot_measure_valuse` for
markers on the measure value plot.  The `inspector_args` is a named tuple of the
arguments to the `plot_inspector_label` function.
"""
struct PlotArgs
    "Named tuple for passing args to Makie inspector_label function (such as measure object)"
    inspector_args
    signal::AbstractSignal
    marker::Symbol
    x::Float64
    y::Float64
    function PlotArgs(inspector_args, signal, marker, x, y)
        new(inspector_args, signal, marker, float(x), float(y))
    end
end
"""
    plot_measure_signals(m::AbstractMeasure)
Defines an array of `PlotArgs` for each marker to be plotted on the signal plot.
"""
function plot_measure_signals end
"""
    plot_measure_values(m::AbstractMeasure)
Defines an array of `PlotArgs` for each marker to be plotted on the measure value plot.
"""
function plot_measure_values end
"""
    plot_inspector_label(m::AbstractMeasure; midx, show_index::Bool, sigdigits::Int=9)
Defines the inspector label for each marker.  The `midx` is the index of the measure.
`show_index` is a boolean to show the index of the measure in the array of measures.
`sigdigits` is the number of significant digits to show in the inspector label.
"""
function plot_inspector_label end

### YLevelMeasure
function plot_measure_signals(m::YLevelMeasure)
    PlotArgs[
        PlotArgs((m, ), m.signal, marker(m), xmin(m.signal), m.y),
        PlotArgs((m, ), m.signal, marker(m), xmax(m.signal), m.y),
    ]
end
function plot_measure_values(m::YLevelMeasure)
    PlotArgs[
        PlotArgs((m, ), m.signal, marker(m), xmin(m.signal), m.value),
        PlotArgs((m, ), m.signal, marker(m), xmax(m.signal), m.value),
    ]
end
function plot_inspector_label(m::YLevelMeasure; midx, show_index::Bool, sigdigits::Int=9)
    idxstr = show_index ? idx2str(midx) : ""
    """
    $(typeof(m))$(idxstr)
    name: $(m.name)
    y: $(display_value(m.y; sigdigits))
    """
end

### OnePointMeasure
function plot_measure_signals(m::OnePointMeasure)
    PlotArgs[
        PlotArgs((m, ), m.signal, marker(m), m.x, m.y),
    ]
end
function plot_measure_values(m::OnePointMeasure)
    PlotArgs[
        PlotArgs((m, ), m.signal, marker(m), m.x, m.value),
    ]
end
function plot_inspector_label(m::OnePointMeasure; midx, show_index::Bool, sigdigits::Int=9)
    idxstr = show_index ? "$(idx2str(midx))" : ""
    """
    $(typeof(m))$(idxstr)
    name: $(m.name)
    x: $(display_value(m.x; sigdigits))
    y: $(display_value(m.y))
    yth: $(display_value(m.yth))
    slope: $(display_value(m.slope))
    """
end
function plot_measure_signals(m::CrossMeasure)
    PlotArgs[
        PlotArgs((m, ), m.signal, marker(m.yth), m.x, m.y),
    ]
end
function plot_measure_values(m::CrossMeasure)
    PlotArgs[
        PlotArgs((m, ), m.signal, marker(m.yth), m.x, m.value),
    ]
end

### TwoPointMeasure:
function plot_measure_signals(m::T) where {T<:TwoPointMeasure}
    PlotArgs[
        PlotArgs((m, :pt1), m.pt1.signal, marker(m.pt1), m.pt1.x, m.pt1.y),
        PlotArgs((m, :pt2), m.pt2.signal, marker(m.pt2), m.pt2.x, m.pt2.y),
    ]
end
function plot_measure_values(m::T) where {T<:TwoPointMeasure}
    PlotArgs[
        PlotArgs((m, :pt2), m.pt2.signal, marker(m.pt2), m.pt2.x, m.value),
    ]
end
function plot_inspector_label(m::T, prop::Symbol; midx, show_index::Bool, sigdigits::Int=9) where {T<:TwoPointMeasure}
    idxstr = show_index ? idx2str(midx) : ""
    """
    $(typeof(m))$(idxstr) at $prop
    name: $(m.name)
    dx: $(display_value(m.dx; sigdigits))
    dy: $(display_value(m.dy))
    slope: $(display_value(m.slope))
    pt1.x: $(display_value(m.pt1.x; sigdigits))
    pt1.yth: $(display_value(m.pt1.yth))
    pt2.x: $(display_value(m.pt2.x; sigdigits))
    pt2.yth: $(display_value(m.pt2.yth))
    """
end

### TransitionMeasure:
function plot_measure_signals(m::TransitionMeasure)
    [PlotArgs((m, i), m.signal, marker(m.crosses[i].yth), m.crosses[i].x, m.crosses[i].y) for i in eachindex(m.crosses)]
end
function plot_measure_values(m::TransitionMeasure)
    n = length(m.crosses)
    [PlotArgs((m, n), m.signal, marker(m.crosses[n].yth), m.crosses[n].x, m.value)]
end
function plot_inspector_label(m::TransitionMeasure, cross_index::Int; midx, show_index::Bool, sigdigits::Int=9)
        idxstr = show_index[] ? idx2str(midx) : ""
        """
        $(typeof(m))$(idxstr) at crosses[$(cross_index)]
        name: $(m.name)
        value: $(display_value(m.value; sigdigits))
        dir: $(m.dir)
        monotonicity: $(m.monotonicity)
        crosses[$(cross_index)].x: $(display_value(m.crosses[cross_index].x; sigdigits))
        crosses[$(cross_index)].yth: $(display_value(m.crosses[cross_index].yth))
        """
end

## Derived measures will be expanded into their component measures
#function plot_measure_signals(m::T) where {T<:DerivedMeasure}
#    collect(Iterators.flatmap(plot_measure_signals, m.measures))
#end
#function plot_measure_values(m::T) where {T<:DerivedMeasure}
#    PlotArgs[
#        PlotArgs((m, length(m.measures)), get_signals(m)[end], marker(m.measures[end]), m.measures[end].x, m.value),
#    ]
#end
#function plot_inspector_label(m::DerivedMeasure, idx::Int; midx, show_index::Bool, sigdigits::Int=9)
#    idxstr = show_index ? idx2str(midx) : ""
#    """
#    $(typeof(m))$(idxstr) at measures[idx]
#    name: $(m.name)
#    value: $(display_value(m.value; sigdigits))
#    x: $(display_value(m.measures[idx].x))
#    y: $(display_value(m.measures[idx].y))
#    """
#end

# Derived measures will be expanded into their component measures
function expand_measures(m::AbstractMeasure, midx)
    return ([m], [midx])
end
function expand_measures(m::DerivedMeasure, midx)
    m2 = [mi for mi in m.measures]
    midxs2 = fill(midx, length(m2))
    return (m2, midxs2)
end
function expand_measures(ms::AbstractArray{<:T, D}, midxs::AbstractArray{I, D}) where {T<:AbstractMeasure,D,I}
    ms_all = AbstractMeasure[]
    midxs_all = I[]
    for (m, midx) in zip(ms, midxs)
        m2s, midxs2s = expand_measures(m, midx)
        append!(ms_all, m2s)
        append!(midxs_all, midxs2s)
    end
    return (ms_all, midxs_all)
end
# Convert Array of structs to structs of array (plot routines neeed xs and ys vecs)
function plot_properties(ms::AbstractVector{<:AbstractMeasure}, midxs::AbstractVector{IDX}; onsignal::AbstractSignal, func::Function) where IDX
    ms, midxs = expand_measures(ms, midxs)
    inspector_args = []
    markers = Symbol[]
    xs = Float64[]
    ys = Float64[]
    midxs2 = IDX[]
    @assert length(ms) == length(midxs)
    for (m, midx) in zip(ms, midxs)
        vector_plotargs = func(m)
        for plotargs in vector_plotargs
            if plotargs.signal === onsignal
                push!(inspector_args, plotargs.inspector_args)
                push!(markers, plotargs.marker)
                push!(xs, plotargs.x)
                push!(ys, plotargs.y)
                push!(midxs2, midx)
            end
        end
    end
    @assert length(inspector_args) == length(markers)
    @assert length(inspector_args) == length(xs)
    @assert length(inspector_args) == length(ys)
    @assert length(inspector_args) == length(midxs2)
    return (; inspector_args, markers, xs, ys, midxs=midxs2)
end
function plot_measure_values_arrays(ms::AbstractVector{<:AbstractMeasure}, midxs::AbstractVector; onsignal::AbstractSignal)
    plot_properties(ms, midxs; onsignal, func=plot_measure_values)
end
function plot_measure_signals_arrays(ms::AbstractVector{<:AbstractMeasure}, midxs::AbstractVector; onsignal::AbstractSignal)
    plot_properties(ms, midxs; onsignal, func=plot_measure_signals)
end


# Given an array of OnePointMeasure objects, plot them all according to the
# styles defined in my kwargs (e.g. `plt.colors_for_sig`, etc...)
function Makie.plot!(plt::MeasureValues{Tuple{Vector{T}}}) where {T<:AbstractMeasure}
    # Only delay markers of second crossing point
    ms = plt[1]
    midxs = plt.measure_idxs
    ms_midxs = @lift expand_measures($ms, $midxs)
    ms = @lift $ms_midxs[1]
    midxs = @lift $ms_midxs[2]
    # Plot second point to show delay
    show_index = get(plt, :show_index, Observable(true))
    sigdigits = get(plt, :sigdigits, Observable(9))
    nplots = 0
    for (onsignal, color) in plt.colors_for_signals[]
        props = @lift plot_measure_values_arrays($ms, $midxs; onsignal)
        if length(props[].xs) == 0
            continue
        end
        inspector_label = (plt2, idx, pos) ->
            begin
                args = props[].inspector_args[idx]
                midx = props[].midxs[idx]
                plot_inspector_label(args...; midx, show_index=show_index[], sigdigits=sigdigits[])
            end
        nplots += 1
        xs = props[].xs
        ys = props[].ys
        marker = props[].markers
        @assert length(xs) == length(ys)
        @assert length(marker) == 1 || length(marker) == length(xs)
        lines!(plt, xs, ys; color, plt.linewidth)
        scatter!(plt, xs, ys; inspectable=false, color=:black, markersize=lift(m -> m + 2, plt.markersize), marker)
        scatter!(plt, xs, ys; inspector_label, color, plt.markersize, marker)
    end
    if nplots == 0
        # If there are no measures to plot then Makie recipe doesn't like returning nothing
        scatter!(plt, [0.0], [NaN])
    end
    return plt
end
## Draw measure density
function Makie.plot!(plt::MeasureDensity{Tuple{Vector{T}}}) where {T<:AbstractMeasure}
    ms = plt[1]
    midxs = plt.measure_idxs
    ms_midxs = @lift expand_measures($ms, $midxs)
    ms = @lift $ms_midxs[1]
    midxs = @lift $ms_midxs[2]
    nplots=0
    overall_vals = @lift [float(m) for m in $ms]
    nbins = ceil(Int, log2(max(1, length(overall_vals[])))) + 1
    no_nans = @lift [v for v in $overall_vals if !isnan(v)]
    overall_hist = @lift StatsBase.fit(StatsBase.Histogram, $no_nans; nbins)
    binedges = @lift $overall_hist.edges[1]

    all_bincounts = Int[]
    all_bingroups = Int[]
    all_binedges = Float64[]
    all_colors = RGBAf[]
    for (grp, (onsignal, color)) in pairs(plt.colors_for_signals[])
        ms_on_sig = @lift T[m for m in $ms if any(plotargs -> plotargs.signal === onsignal, plot_measure_values(m))]
        if length(ms_on_sig[]) > 0
            vals = @lift [float(m.value) for m in $ms_on_sig if !isnan(m.value)]
            if length(vals[]) == 0
                continue
            end
            counts = @lift StatsBase.fit(StatsBase.Histogram, $vals, $binedges).weights
            nplots += 1
            append!(all_bincounts, counts[])
            append!(all_binedges, binedges[][1:end-1])
            append!(all_bingroups, fill(grp, length(counts[])))
            append!(all_colors, fill(color, length(counts[])))
        end
    end
    if nplots > 0
        barplot!(plt, all_binedges .+ step(binedges[])/2, all_bincounts; gap=0, direction=:x, stack=all_bingroups, color=all_colors, strokewidth=2)
    else
        # If there are no measures to plot then Makie recipe doesn't like returning nothing
        scatter!(plt, [0.0], [NaN])
    end
    return plt
end

# Plot markers for delay measure (don't plot the signal)
function Makie.plot!(plt::SignalPlot{Tuple{Vector{T}}}) where {T<:AbstractMeasure}
    ms = plt[1]
    midxs = plt.measure_idxs
    @assert length(ms[]) == length(midxs[])
    ms_midxs = @lift expand_measures($ms, $midxs)
    ms = @lift $ms_midxs[1]
    midxs = @lift $ms_midxs[2]
    show_index = get(plt, :show_index, Observable(true))
    sigdigits = get(plt, :sigdigits, Observable(9))
    nplots=0
    orig_label = plt.label # workround once scatter supports passing labels (https://github.com/MakieOrg/Makie.jl/issues/3263)
    plt.label = nothing
    for (onsignal, color) in plt.colors_for_signals[]
        props = @lift plot_measure_signals_arrays($ms, $midxs; onsignal)
        if length(props[].xs) == 0
            continue
        end
        inspector_label = (plt2, idx, pos) ->
            begin
                args = props[].inspector_args[idx]
                midx = props[].midxs[idx]
                plot_inspector_label(args...; midx, show_index=show_index[], sigdigits=sigdigits[])
            end
        nplots += 1
        xs = props[].xs
        ys = props[].ys
        marker = props[].markers
        @assert length(xs) == length(ys)
        @assert length(marker) == 1 || length(marker) == length(xs)
        scatter!(plt, xs, ys; inspectable=false, color=:black, markersize=plt.markersize[] + 2, marker)
        scatter!(plt, xs, ys; inspector_label, color, plt.markersize, plt.show_index, marker)
    end
    if nplots == 0
        # If there are no measures to plot then Makie recipe doesn't like returning nothing
        scatter!(plt, [0.0], [NaN])
    end
    plt.label = orig_label
    return plt
end

function get_signals(s::AbstractSignal)
    return AbstractSignal[s]
end
function get_signals(m::AbstractMeasure)
    plotargs = plot_measure_signals(m)
    signals = [pa.signal for pa in plotargs]
    return signals
end
function get_signals(m::DerivedMeasure)
    return AbstractSignal[s for meas in m.measures for signals in get_signals(meas) for s in signals]
end
function get_signals(signals::AbstractVector{S}) where S<:AbstractSignal
    AbstractSignal[s2 for s1 in signals for s2 in get_signals(s1) ]
end
function get_signals(signals::AbstractVector{<:AbstractVector{S}}) where S<:AbstractSignal
    S[s2 for v1 in signals for s2 in v1 ]
end
function is_on_signal(m::AbstractMeasure, on_signal::AbstractSignal)
    any(get_signals(m) .=== on_signal)
end
function unique_signals(signals_or_measures::AbstractArray)
    usigs = AbstractSignal[]
    for m in signals_or_measures
        for sig in get_signals(m)
            if !any(sig === usig for usig in usigs)
                push!(usigs, sig)
            end
        end
    end
    return usigs
end

function calculate_colors(ms::AbstractArray)
    usigs = unique_signals(ms)
    colors_for_signals = [sig => last(color_cycle[mod1(idx, length(color_cycle))]) for (idx, sig) in pairs(usigs)]
end
function getcolor(colors_for_signals, signal::AbstractSignal)
    color = :black # default
    for (s, c) in colors_for_signals
        if s === signal
            color = c
            break
        end
    end
    return color
end

function inspect(m::AbstractMeasure; kwargs...)
    inspect([m]; kwargs...)
end
function inspect(ms::AbstractArray{<:AbstractMeasure, D}; xlabel="", ylabel="",
                                                    title="$(length(ms)) measurement$(length(ms) != 1 ? "s" : "")",
                                                    verbose = length(ms) <= 30,
                                                    xscale = default_xscale(ms),
                                                    yscale = default_yscale(ms),
                                                    xtickformat = default_xtickformat(),
                                                    ytickformat = default_ytickformat(),
                                                    show_index = true,
                                                    sigdigits=9,
                                                    markersize=20,
                            ) where D

    colors_for_signals = calculate_colors(ms) # [signal1 => color1, signal2 => color2, ...]
    unique_sigs = collect(first.(colors_for_signals))
    meas_with_idx = collect(pairs(ms))
    types = sort(collect(Set(typeof(m) for m in ms)), by=string)
    measures_by_type = Dict(T => T[m for m in ms if m isa T] for T in types)
    midxs_by_type = Dict(T => [midx for (midx, m) in meas_with_idx if m isa T] for T in types)

    f = Figure()
    ax_values = []
    ax_densities = []
    for (row, T) in pairs(types)
        mst = measures_by_type[T]
        measure_idxs = midxs_by_type[T]
        N = length(mst)
        Ns = N != 1 ? "s" : ""
        M = length(unique_signals(collect(Iterators.flatmap(get_signals, mst))))
        Ms = M != 1 ? "s" : ""
        title="""$N $T value$Ns on $M signal$Ms"""
        hist_title="$(T) histogram"
        ax_measurevalues = Axis(f[row,1:3]; default_axis_kwargs(; sigdigits, xlabel, ylabel, title, xscale, yscale, xtickformat, ytickformat)...)
        ax_measuredensity = Axis(f[row,4]; default_axis_kwargs(; sigdigits, xlabel, ylabel, xticks=LinearTicks(2), title=hist_title, xscale, yscale, xtickformat, ytickformat)...)
        linkyaxes!(ax_measurevalues, ax_measuredensity)
        measurevalues!(ax_measurevalues, mst; colors_for_signals, title, measure_idxs, markersize=markersize÷2, linewidth=1) # measure values as lines
        measuredensity!(ax_measuredensity, mst; colors_for_signals, measure_idxs, yscale) # histogram
        DataInspector(ax_measurevalues)
        push!(ax_values, ax_measurevalues)
        push!(ax_densities, ax_measuredensity)
    end
    M = length(unique_sigs)
    Ms = M != 1 ? "s" : ""
    N = length(ms)
    Ns = N != 1 ? "s" : ""
    detailed_title = """$M signal$Ms with $N measurement$Ns"""
    ax_signalplot = Axis(f[length(ax_values)+1,1:3]; default_axis_kwargs(; sigdigits, xlabel, ylabel, title=detailed_title, xtickformat, ytickformat)...)
    linkxaxes!(ax_signalplot, ax_values...)
    # Limit of 1 label per recipe call so loop through here instead of in recipe:
    for (i, (onsignal, color)) in pairs(colors_for_signals)
        inspectable = false
        label = "signal$i"
        signalplot!(ax_signalplot, onsignal; color, linewidth=2, inspectable, label) # signal lines
    end
    for T in types
        mst = measures_by_type[T]
        measure_idxs = midxs_by_type[T]
        signalplot!(ax_signalplot, mst; colors_for_signals, measure_idxs) # signal meas markers
    end
    if length(colors_for_signals) <= 10
        Legend(f[length(ax_values)+1,4], ax_signalplot; merge=true, unique=false, tellheight=false, tellwidth=false)
    end
    DataInspector(ax_signalplot)
    return f
end

function inspect(ms::AbstractVector{<:AbstractVector{<:AbstractMeasure}}; kwargs...)
    ms = vcat(ms...) # this is bad as the index will be wrong when plotted
    inspect(ms; kwargs...)
end




function Makie.plot!(plt::SignalPlot{<:Tuple{DxCheckResult}})
    m = plt[1]
    xmin = @lift [$m.meas.pt1.x + minimum($m.domain)]
    xmax = @lift [$m.meas.pt1.x + maximum($m.domain)]
    yval = @lift [Float64($m.meas.pt2.y)]
    xval = @lift [Float64($m.meas.pt2.x)]
    violation = @lift !($m.meas.pt1.x + minimum($m.domain) <= $m.meas.pt2.x <=
                            $m.meas.pt1.x + maximum($m.domain))

    @lift measureplot(plt, $m.meas.pt1)
    @lift measureplot(plt, $m.meas.pt2, violation)
    rangebars!(plt, yval, xmin, xmax,
        color = plt.color,
        whiskerwidth = plt.markersize,
        direction = :x,
    )

    # Add `!` over our marker if we're in a violation
    @lift text!(plt, xval, yval, text="!",
        visible=violation,
        color=:white,
        align=(:center, :center),
        font = :bold,
        fontsize = $plt.markersize * 0.6,
    )

    vspan!(plt, xmax, xval;
        visible=violation,
        color=RGBAf(1,0,0,0.2),
        # Work around annoying bug where this causes zooming problems
        #ymin=0.1,
        #ymax=.9,
    )
    plt
end

function Makie.plot!(plt::SignalPlot{<:Tuple{DyCheckResult}})
    m = plt[1]
    violation = @lift !satisfied($m)
    max = @lift maximum($m.meas.signal)

    ymin = @lift [$m.meas.pt1.yth.value+minimum($m.domain)]
    ymax = @lift [$m.meas.pt1.yth.value+maximum($m.domain)]
    xval = @lift [$max.x]
    yval = @lift [$max.y]

    #measureplot(plt, lift(m->m.meas, m))
    measureplot(plt, max, violation)

    rangebars!(plt, xval, ymin, ymax,
    color = plt.color,
    whiskerwidth = plt.markersize,
    direction = :y)
    text!(plt, xval, yval, text="!",
        visible=violation,
        color=:white,
        align=(:center, :center),
        font = :bold,
        fontsize = @lift($plt.markersize*0.6),
    )
    hspan!(plt, ymax, yval; visible=violation, color=RGBAf(1,0,0,0.2))
end

function Makie.plot!(plt::SignalPlot{<:Tuple{YCheckResult}})
    m = plt[1]
    violation = @lift !satisfied($m)
    max  = @lift maximum($m.meas.signal)

    ymin = @lift [minimum($m.domain)]
    ymax = @lift [maximum($m.domain)]
    xval = @lift [$max.x]
    yval = @lift [$max.y]

    measureplot(plt, max, violation)

    rangebars!(plt, xval, ymin, ymax,
    color = plt.color,
    whiskerwidth = plt.markersize,
    direction = :y)
    text!(plt, xval, yval, text="!",
        visible=violation,
        color=:white,
        align=(:center, :center),
        font = :bold,
        fontsize = @lift($plt.markersize*0.6),
    )
    hspan!(plt, ymax, yval; visible=violation, color=RGBAf(1,0,0,0.2))
end

function Makie.legendelements(plot::SignalPlot{<:Tuple{DxCheckResult}}, legend)
    m = plot[1]
    violation = @lift !satisfied($m)
    glowwidth = @lift $violation ? 3 : 0
    exclcolor = @lift $violation ? RGBAf(1,1,1,1) : RGBAf(1,1,1,0)
    LegendElement[
        MarkerElement(
            color = Makie.scalar_lift(plot, plot.color, legend.markercolor),
            marker = @lift($m.meas.pt2.yth isa rising ? :utriangle : :dtriangle),
            markersize = Makie.scalar_lift(plot, plot.markersize, legend.markersize),
            strokewidth = glowwidth, # glow doesn't seem to work
            strokecolor = plot.errorcolor,
        ),
        MarkerElement(
            color = exclcolor,
            marker = '!',
            markersize = lift(s->s*0.6, Makie.scalar_lift(plot, plot.markersize, legend.markersize)),
            font = :bold, # this doesn't seem to work
        )
    ]
end

function Makie.legendelements(plot::SignalPlot{<:Tuple{DyCheckResult}}, legend)
    m = plot[1]
    violation = @lift $m.meas.height ∉ $m.domain
    glowwidth = @lift $violation ? 3 : 0
    exclcolor = @lift $violation ? RGBAf(1,1,1,1) : RGBAf(1,1,1,0)
    LegendElement[
        MarkerElement(
            color = Makie.scalar_lift(plot, plot.color, legend.markercolor),
            marker = :diamond,
            markersize = Makie.scalar_lift(plot, plot.markersize, legend.markersize),
            strokewidth = glowwidth, # glow doesn't seem to work
            strokecolor = plot.errorcolor,
        ),
        MarkerElement(
            color = exclcolor,
            marker = '!',
            markersize = lift(s->s*0.6, Makie.scalar_lift(plot, plot.markersize, legend.markersize)),
            font = :bold, # this doesn't seem to work
        )
    ]
end
