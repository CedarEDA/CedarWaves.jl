using Optim
using Roots: find_zeros, find_zero
using IterTools: cache, partition

# There are 4 types of problems and 4 types of signals
#
# Problems can be an exact condition or an optimum
# Optimum problems can be global(one), or local(many)
# Exact condition can be many, but maybe first/last/any is desired
# For example max/min is a global optimum,
# but a peak finding function would be a local optimum.
# Crossings is an exact condition,
# and finding the first crossing is a common operation.
#
# For signal we have sampled/function and interpolated/discrete.
# The most common type is sampled interpolated (simulation data)
# Here we want to check every sample, and then optimize.
# On sampled disrete, checking every sample is sufficient.
# On functions we can only run optimizers.
# An optimizer does not work on discrete functions.
#
# So for optimization we can use Optim
# and for exact conditions Roots.
# This is the best we can do for continuous functions.
# It is possible that Roots/Optim does not find the full solution.
# For discrete sampled signals, you treat it as an array
# Optim -> findmin
# Roots -> filter
# For discrete functions, nothing can be done?
# Can't iterate over the samples, can't use optimizers.
# You need to sample them
#
# For sampled interpolated signals, something special can be done.
# Consider
#   _   _
# _/  *  \_ = _n_
# All of the 4 sample points are 0, and the POI is interpolated
# Sampled methods will not provide ANY information here. Conversely:
# ________________________________/\_______________________________
# Most points are 0 except for 1
# Continuous methods have no information to locate the POI.
#
# The slow but correct method is as follows.
# For roots, find roots on every sample interval, discard failures.
# For optim, optimize every interval, and select the best interval.
#
# The faster method, for realistic simulatoion data:
# Find the interval where the goal function changes sign, find root in inverval.
# Find the optimum point, optimize in interval of adjacent points.
#
# Distincton of global/local optimum is not covered yet.


"""
    find_min_itr(xy_pair_iterator, func=+)
Returns the `(miny, minx)` tuple of the mimium of func(y) over the xy pair iterator.
`func` is used to apply a transformation to the y values.
For example `func=-` will find the maximum while `+` (default) finds the minimum.

Note: this function only iterates over samples (does not do interpolation like
`optimize_min_point`).

# Examples

```@jldoctest
julia> s = PWL(0:2, [0.5, 1, 0.0]);

julia> CedarWaves.find_min_itr(eachxy(s), +)
(0.0, 2.0)

julia> CedarWaves.find_min_itr(eachxy(s), -)
(1.0, 1.0)
```

See also
[`optimize_min_point`](@ref).
"""
function find_min_itr(xy_pair_itr, func=+)
    itr = iterate(xy_pair_itr)
    if itr === nothing
        throw(ArgumentError("collection must be non-empty"))
    end
    (x, y), state = itr
    fy = func(y)
    minx, miny, minfy = x, y, fy
    while true
        itr = iterate(xy_pair_itr, state)
        itr === nothing && break
        minfy != minfy && break # is this a NaN check?
        (x, y), state = itr
        fy = func(y)
        if fy != fy || isless(fy, minfy)
            minx, miny, minfy = x, y, fy
        end
    end
    return (miny, minx)
end
