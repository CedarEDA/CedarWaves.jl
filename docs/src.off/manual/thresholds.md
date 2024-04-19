# Thresholds

Thresholds are used by many functions to reprerent when a signal vertically crosses a value.
A signal must fully cross a threshold value to be considered a crossing.  If it merely
reaches the threshold value but doesn't cross then it is not considered a crossing.

A threshold value represents the y-value of the signal, like `0.5` (volts or amps, etc.)

The direction of the threshold can also be specified with:

  * `rising(yth)` for rising edge (see [`rising`](@ref))
  * `falling(yth)` for falling edge (see [`falling`](@ref))
  * `either(yth)` for either a rising falling edge (see [`either`](@ref))

For example `cross(sig, falling(0.8))` finds the first crossing when the y-value falls below 0.8.

See also [`cross`](@ref), [`crosses`](@ref), [`eachcross`](@ref), [`delay`](@ref).



