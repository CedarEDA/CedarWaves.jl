using Memoization

function cache(s::SampledSignalType)
    XT = xtype(s)
    YT = ytype(s)
    @memoize Dict{Tuple{Tuple{XT}, NamedTuple{(), Tuple{}}}, YT} f(x) = s.full_transform.callable(x)
    new_signal(s, full_transform=SampledFunction(f,
        s.full_transform.clippediterable))
end
function cache(s::Signal)
    XT = xtype(s)
    YT = ytype(s)
    @memoize Dict{Tuple{Tuple{XT}, NamedTuple{(), Tuple{}}}, YT} f(x) = s.full_transform(x)
    new_signal(s, full_transform=f)
end