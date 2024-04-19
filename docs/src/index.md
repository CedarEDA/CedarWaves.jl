```@meta
CurrentModule = CedarWaves
```

!!! info
    The CedarWaves software is available for preview only. Please contact us for
    access, by emailing info@juliahub.com, if you are interested in
    evaluating CedarWaves.


# Getting Started

## Intoduction to Cedar Waves

Cedar Waves is a high performance tool for post-processing continuous time data like from analog circuit simulators.  The simulation data is usually piece-wise-linear from a simulation with non-uniform sampling.

### High Level Features

* **Easy to use**
* **High performance**: process Gigabytes of data in milliseconds.
* **High capacity**: algorithms are very memory efficient allowing users to process very large wavefiles.
* Supports various signal types:
  * **Continuous signals**:
    * Various interpolation methods between samples: constant, piecewise-linear, Akima, quadratic splines, or qubic splines.
    * Continuous functions like `sin`
  * **Discrete signals**: no interpolation between data points.
  * **Uniform** and **non-uniform** sampled signals
  * **Finite** and **infinite** domains
  * **Periodic** and **ZeroPad** signals
* Fast and flexible clipping of the signal's domain to zoom-in and zoom-out along x-axis.
* **Accurate**: math performed on continuous signals is also performed between sample points (not just at the data points)
* **Easy to extend**: add custom functions that run at full speed to build automated flows/measurements.

## License

```
(C) JuliaHub 2022. All rights reserved.
A contract must be obtained through JuliaHub to use this software.
```

## Interactive Interpreter

The most basic way to use Cedar Waves is from the interactive interpreter (REPL).
Typically users will experiment with the interactive interpreter and keep changes in a text file that runs the complete script.
The REPL is a good place to experiment for new users.

To use the software start the `julia` REPL and then in the run `using CedarWaves` to load the package:

```@repl
using CedarWaves
```

Now all the functions are imported for use.

## Creating a Signal

The following examples use a very basic signal to showcase a few features.

A common signal type is a continuous sampled signal with piecewise-linear (PWL) interpolation
between samples.  Let's create two vectors with the `x` and `y` values and make a two point
wave:


```@repl myrms
using CedarWaves # once at top of session/file
xs = [0, 1]
ys = [-1, 1]
s = PWL(xs, ys)
```

The REPL will quickly print out a low-resolution ASCII plot to provide instant visual feedback of the signal.
The ASCII plots are rumored to use technology from 1970s **phosphorous display oscilloscopes** so don't feel bad if you want to bump it to get it to work.
High resolution plots are also available.

Continuing on, let's take the absolute value of the signal:

```@repl myrms
s2 = abs(s)
```

While it looks quite simple the correct behavior of interpolating between points is overlooked in most other tools.

## Signal Values

Let's verify the `abs(s)` by checking the y-values at a few different x-values.
Signals act like functions so just like `y = f(x)`, the signal is the `f` and pass it an `x` value to get the corresponding `y` value:

```@jldoctest myrms
julia> s2(0)
1.0

julia> s2(0.25)
0.5

julia> s2(0.5)
0.0

julia> s2(1)
1.0
```

It looks correct.

## Custom Measurements

Often users will create a common sequence of steps that they would like to re-use over and over.
Users can easily add new functions that operate on signals.

There are many built-in functions but lets see if we can re-create the provided [`rms`](@ref) function.

The rms value is calculated with the following steps:

First square the signal:

```@repl myrms
sq = s^2
```

Then integrate it:

```@repl myrms
s3 = integral(s^2)
```

Divide by the duration:

```@repl myrms
s4 = integral(s^2)/xspan(s)
```

And take the square root:

```@repl myrms
rmsval = sqrt(integral(s^2)/xspan(s))
```

The initial signal `s` is equivalent to a triangular wave with amplitude `A=1` and
the analytical rms value of a triangle wave is `A/sqrt(3)`.  Lets check:


```@repl myrms
theoretical = 1/sqrt(3)
```

It looks really close.  Julia has an "approximately equal to" operator (or `isapprox(a, b)` function).
In the REPL `≈` can by typed with `\approx<tab>`.

```@jldoctest myrms
julia> theoretical ≈ rmsval
true
```

It agrees!

Now to make the rms re-usable we will create a new function named `myrms` like so:

```@repl myrms
myrms(a_signal) = sqrt(integral(a_signal^2)/xspan(a_signal))
```

Note the familiar math-like syntax to define a one-line function.
(Julia also supports multi-line function definitions.)

Let's check it:

```@repl myrms
myrms(s)
```

And we get the same answer but now we can re-use `myrms` instead of typing out the steps each time.

## High Performance

To demonstrate performance let's create 1GB of data to do some operations on:

!!! warning
	If 1GB is too much data for your computer reduce the size appropriately.

Note: Use `div(a, b)` or `a \div<tab> b` (`÷`) for integer division

```@repl myrms
mem = 10^9 # 1 GB
mem_num = sizeof(1.0) # 8 bytes per number (64 bits)
N = mem ÷ mem_num
```

So 125 million points is needed for 1 GB of data.  Let's create the x-axis values:

```@repl myrms
@time t = range(0, 1, length = N+1)  # time points
```

!!! note
	When commands start with `@` that means a macro is running which can
	read in the rest of the line and insert extra statements like to measure
	the time it takes for the function to run.

This returns very quickly and just contains the start, stop and step size.
One extra point was added since there is both a start and end point so now the step size is a nice number.

Now to create the corresponding y-values let's create a modulated sinusoidal signal:

```@repl myrms
fc = 1000 # 1000 Hz carrier
f = 2  # 2 Hz signal
@time y = @. sin(2pi*fc*t)*cos(2pi*f*t)
```

Note it takes 2 or 3 seconds (depending on the computer) to generate the y-values and takes 1GB of memory.

Now create a piecewise-linear signal with the values:

```@repl myrms
@time modulated = PWL(t, y)
```

Notice that the plot happens almost instantly even though there are 125 million points.
Let's zoom in to see a few cycles of the carrier:

```@repl myrms
clip(modulated, 0 .. 4/fc) # ".." means interval
```


Now use the custom `myrms` function created above to calculate the rms value of the signal.
This is a complex function that takes the continuous integral of the squared signal (see [Custom Measurements](@ref)):

```@repl myrms
@time myrms(modulated)
```

It was fast but the first time Julia runs code it compiles it and that took about 98% of the time.
So let's run it again to get the true speed:

```@repl myrms
@time myrms(modulated)
```

Don't blink, because you may miss it.  But is it correct?

According to [Wolfram Alpha](https://www.wolframalpha.com/input/?i=integrate+%28sin%282*pi*2*x%29+*+cos%282*pi*1000*x%29%29%5E2+from+0+to+1) the integral of the y-values squared is ``1/4``. So then we have:

```@jldoctest myrms
julia> integral_squared = 1/4;

julia> ans = sqrt(integral_squared/xspan(modulated))
0.5

julia> ans ≈ myrms(modulated)
true
```

So it is correct.
