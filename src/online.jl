using DataStructures: CircularBuffer, capacity

struct OnlineSignalFactory{XT, YT, DI}
    di::DI
    ch::Channel{Tuple{XT, YT}}
    consumers::Vector{Channel{XT}}
end

"""
    OnlineSignalFactory([buffersize])
    OnlineSignalFactory{XT, YT, DI}([buffersize])

Create a factory for online signals with an optional buffer size argument.
It also accepts type parameters for the data types and interpolation type.
These default to `Float64` and `LinearInterpolation` respectively.

An online signal is one that is backed by a `Channel` and `CircularBuffer` for samples.
A simulator or parser can push `(x, y)` samples onto the channel which get added to the buffer.
(The buffer is shared between signals made in this factory)
Iterative measures can then run `@async` to analyse the data as it comes in.

!!! warning
    Not all functions are compatible with online analysis.
    Online analysis works best with functions that return iterators.
    Functions based on integrals are not suitable.

!!! warning
    An online signal must consume all its samples exactly once.
    Online signals that are not consumed will block the channel when it becomes full.
    Online signals that are consumed more than once will return incorrect results.

Example:

```julia
sf = OnlineSignalFactory(50)

@sync begin
    @async for (x, y) in eachxy(new_online(sf))
        if y > 0.8 || y < -0.8
            println("signal exceeded limits at ", x)
        end
    end
    for t in 0:0.1:10
        put!(sf.ch, (t, sinpi(t^1.5)))
    end
    close(sf.ch)
end

pp = postprocess(sf)
println("rms: ", rms(pp))
```

A complete demo can be found in `/demos/online/online.jl`.

See also
[`new_online`](@ref),
[`postprocess`](@ref),
"""
function OnlineSignalFactory{XT, YT, DI}(n::Int64=10000) where {XT, YT, DI}
    xbuf = CircularBuffer{XT}(n)
    ybuf = CircularBuffer{YT}(n)
    consumers = Channel{XT}[]
    di = DI(ybuf, xbuf)
    ch = Channel{Tuple{XT, YT}}(n) do ch
        for (x, y) in ch
            push!(di, y, x)
            for c in consumers
                put!(c, x)
            end
        end
        for c in consumers
            close(c)
        end
    end
    OnlineSignalFactory(di, ch, consumers)
end

OnlineSignalFactory(n::Int64=10000) = OnlineSignalFactory{Float64, Float64, LinearInterpolation}(n)

"""
    new_online(sf::OnlineSignalFactory)

Create a new online signal from an [`OnlineSignalFactory`](@ref).
Functions on this signal block until samples are pushed to the factory.

See [`OnlineSignalFactory`](@ref) for more about online signals.
See [`postprocess`](@ref) for making a non-blocking signal from an [`OnlineSignalFactory`](@ref).
"""
function new_online(sf::OnlineSignalFactory{XT, YT, DI}) where {XT, YT, DI}
    isopen(sf.ch) || error("Simulation has finished! Use `postprocess`.")
    callable(x) = try
        sf.di(x)
    catch e
        # if the interpolation doesn't have enough samples, just return the closest sample
        # this basically assumes the signal is constant
        e isa BoundsError || rethrow(e)
        idx = max(searchsortedlast(sf.di.t, x), 1)
        sf.di.u[idx]
    end
    base_x_interval = Ref(empty_interval(XT))
    extrapolated_x_interval = clipped_x_interval = -Inf..Inf
    ch = Channel{XT}(capacity(sf.di.t))
    push!(sf.consumers, ch)
    clippedx(interval) = Iterators.filter(ch) do v
        base_x_interval[] = first(sf.di.t)..last(sf.di.t)
        v ∈ interval
    end
    full_transform = SampledFunction(callable, clippedx)
    # Check for discrete signals:
    kind = DI <: NoInterpolation ? DiscreteSignal : ContinuousSignal
    Signal(; full_transform, base_x_interval, extrapolated_x_interval, clipped_x_interval, kind)
end

"""
    postprocess(sf::OnlineSignalFactory)

Create a plain old signal from an [`OnlineSignalFactory`](@ref).
This signal can be used with any function, but only contains the samples currently in the buffer.

See [`OnlineSignalFactory`](@ref) for more about online signals.
See [`new_online`](@ref) for making an online signal from an [`OnlineSignalFactory`](@ref).
"""
function postprocess(sf::OnlineSignalFactory{XT, YT, DI}) where {XT, YT, DI}
    isopen(sf.ch) && error("Simulation is still running! Use `new_online`.")
    callable = sf.di
    extrapolated_x_interval = clipped_x_interval = base_x_interval = first(sf.di.t)..last(sf.di.t)
    clippedx(interval) = Iterators.filter(v->v ∈ interval, sf.di.t)
    full_transform = SampledFunction(callable, clippedx)
    # Check for discrete signals:
    kind = DI <: NoInterpolation ? DiscreteSignal : ContinuousSignal
    Signal(; full_transform, base_x_interval, extrapolated_x_interval, clipped_x_interval, kind)
end