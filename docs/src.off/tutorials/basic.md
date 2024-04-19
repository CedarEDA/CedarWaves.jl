# Basic Signals

The purpose of this tutorial is to show how to create some basic signals and do some simple math.

## Setup

```@repl tut1
using CedarWaves, Plots
const M = 10^6  # multiplier for Mega
```

## Create a Signal

We will create a signal with a sampling rate of 8 MHz and a carrier signal of 1 MHz.
Note that Julia supports multiplication through juxtoposition.

```@repl tut1
Fs = 8M  # sampling freq
Fc = 1M  # carrier freq
```

Now create an x- and y-axis of data using the `sin` function.  The `.` after the `sin` applies the `sin` function to each
element of the vector (called broadcasting):

```@repl tut1
t = 0:1/Fs:1/Fc  # tstart:tstep:tstop
y = sin.(2pi*Fc*t)
```

Note that the values of `y` at the zero crossing points do not equal `0.0` because the value of `pi` is not an accurate number.  
To remedy this use a `sin` function that does not take `pi` as an input, like [`sinpi`](@ref) or [`sind`](@ref):


```@repl tut1
y = sinpi.(2*Fc*t)   # in units of pi
y = sind.(360*Fc*t)  # in degrees
```

For piece-wise-linear signals the [`PWL`](@ref) function is used.  

```@repl tut1
s1 = PWL(t, y)
plot(s1, title="Sinusoid", xlabel="time (s)", ylabel = "Volts (V)", label="out");
savefig("tut_s1.svg") # hide
nothing # hide
```

![](tut_s1.svg)

For piece-wise-constant signals the [`PWC`](@ref) is used:

```@repl tut1
s2 = PWC(t, y)
plot(s2, title="PWC Sinusoid", xlabel="time (s)", ylabel = "Volts (V)", label="out");
savefig("tut_s2.svg") # hide
nothing # hide
```

![](tut_s2.svg)

Discrete signals (with no interpolation) are created with [`Series`](@ref):

```@repl tut1
s3 = Series(t, y)
plot(s3, title="Series Sinusoid", xlabel="time (s)", ylabel = "Volts (V)", label="out");
savefig("tut_s3.svg") # hide
nothing # hide
```

![](tut_s3.svg)

