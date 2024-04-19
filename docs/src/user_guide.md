```@meta
CurrentModule = CedarWaves
```


# User Guide

```@contents
Pages = ["all.md"]
Depth = 4
```

## Introduction

Analog verification has largely been a fairly manual process due to the difficulty in making analog measurements on waveforms.
This package allows for much better ease of use and flexibility than other tools and manages to do this with better performance.
The goal is for the user to easily automate analog measurements by providing many standard measurements but also supporting
custom measurements that run at full speed.
The main feature this package provides is support for continuous and discrete time signals, typically produced by analog
and mixed-signal simulators or lab equipment.
It is written in the [Julia](http://julialang.org) programming language which is designed for engineers that need
ease of use and high performance.

For a quick tour see the [Getting Started](@ref) manual.



## Understanding Signals

Signals should not be thought of a vector of values since they can be continuous and have infinite duration.
A much better analogy is to think of them as a mathematical function.
Doing math with signals is natural and follows the notation
common in most Electrical Engineering textbooks.

The following rules are held for mathematical operations:
- Signals work analogous to mathematical functions: `f(x) = g(x) + h(x)`.
  So if two signals **g** and **h** are added together the `x` values are
  evaluated for each signal and that forms the result `y = f(x)`
  of the new signal, **f**.
- The **domain** of the result is the **intersection** of the
  domains of the two signals.
  Therefore, the domain will shrink to the common
  domain and adding a discrete signal to a continuous will result
  in a discrete signal.
- Signal domains must be **monotonically increasing**.
  Any non-monitonic sample values will be removed.


## Types of Signals

There are many types of signals supported for various analog circuit waveform types.
A signal has the following characteristics:
* [continuous](@ref Continuous-Signals) vs [discrete](@ref Discrete-Signals)
* finite domain vs infinite domain
* [periodic](@ref Periodic-Signal) vs aperiodic

There are two broad types of signals: [continuous](@ref Continuous-Signals) and [discrete](@ref Discrete-Signals).
The difference is discrete signals have a domain that is discontinuous so getting the value between the datapoints is an error.
A signal cannot be both continuous and discrete so the above functions are always the [xor](https://docs.julialang.org/en/v1/base/math/#Base.xor) of each other.

Both types of signals can either have a finite domain (typically from a simulator) or an infinite domain (like a Fourier Series or `sin` function).
[Periodic signals](@ref Periodic-Signal) and [zero padded](@ref Zero-Padding) signals also have infinite domains.

### Continuous Signals

Continuous signals have a continuous domian (x-axis) and can either be created from [pure functions](@ref continuous-from-function) (like [`SIN`](@ref)) or from sampled data with interpolation between data points.


#### [From Sampled Data](@id continuous-from-samples)
For continuous signals from sampled data the following functions are availbe to create sampled signals:
- [`PWC`](@ref): a signal with piecewise-constant (PWC) interpolation between data points.
  This is typically used to represent digital signals.
- [`PWL`](@ref): a signal with piecewise-linear (PWL) interpolation between data points.
  This has traditionally been used to represent signals from analog simulators.
- [`PWAkima`](@ref): a signal with piecewise-akima spline interpolation over the x-values.
  This is well suited for analog signals and will not create artificial ringing like [`PWQuadratic`](@ref) or [`PWCubic`](@ref).
- [`PWQuadratic`](@ref): a signal with a piecewise quadradic spline interpolation between data points.
  The interpolation is smooth (with a continuous derivative) using a second order method.
- [`PWCubic`](@ref): a signal with a piecewise cubic spline interpolation between data points.
  The interpolation is smooth (with a continuous derivative) using a third order method.

See [Choosing an Interpolation Method](@ref) for examples and application info.

#### [From Pure Functions](@id continuous-from-function)

The purpose of signals that are pure functions is they are often useful for combinining
with signals from sampled data.
They can also have a limited domain unlike the functions they are built with.

For pure functions the following functions are availabe to create signals:
- `SIN`: to create a sinusoidal signal.  See [`SIN`](@ref) for more info.

It is also easy to create your own signals from pure functions with the constructor:
- `func_name = ContinuousFunction(func, interval)`: create a continuous function.
  See [`ContinuousFunction`](@ref) for more info.

### Discrete Signals

Discrete signals represent data that has no interpolation between data points.
This may come from lab equipment that samples signals with no guarantee for what is between the data points.
Another application is for functions like DFT that input uniformly sampled discrete signals.

Discrete signal will return `true` from [`isdiscrete`](@ref)`(signal)`.

#### [From Sampled Data](@id discrete-from-samples)

Discrete signals from sampled data are created with the [`Series`](@ref) function.

#### [From a Pure Function](@id discrete-from-function)

Discrete signals from a function are created with the `DiscreteFunction` function.

#### Choosing an Interpolation Method

This example demonstrates the different interpolation methods and dicusses when to use them.

To compare the interpolation methods, lets compare them by sampling the `sin`
function at 6 points on a period (`sin` is a regular Julia function).

First lets create a [ContinuousFunction](@ref continuous-from-function) for
the ideal waveform:

```@repl UG
using CedarWaves
ideal = ContinuousFunction(sin, domain = 0 .. 2pi)  # true waveform
```

Then lets use six equally spaced samples (that don't fit a sine wave that well):

```@repl UG
xs = range(0, 2pi, length=6) # sparse sampling
d0 = Series(xs, sin)  # discrete sample points
```

Note: the samples don't hit the peaks intentionally.
Now well will try the different interpolation methods
and calculate the [`rms`](@ref) error for each method.

First piece-wise constant interpolation:

```@repl UG
s0 = PWC(xs, ideal)
err0 = rms(s0 - ideal)
```

Note for `s0` above the y-values were sampled from the `ideal` signal or they
can be provided as a vector or use any Julia function (e.g. `sin`).

Now for piece-wise linear interpolation:
```@repl UG
s1 = PWL(xs, ideal)
err1 = rms(s1 - ideal)
```

For piece-wise quadratic interpolation:

```@repl UG
s2 = PWQuadratic(xs, sin)
err2 = rms(s2 - ideal)
```

And for piece-wise cubic interpolation:

```@repl UG
s3 = PWCubic(xs, sin)
err3 = rms(s3 - ideal)
```

And for piece-wise Akima interpolation:

```@repl UG
s4 = PWAkima(xs, sin)
err4 = rms(s3 - ideal)
```


And summarize the results:

```@repl UG
using UnicodePlots
names = ["PWC", "PWL", "PWQuadratic", "PWCubic", "PWAkima"];
errvals = [err0, err1, err2, err3, err4];
barplot(names, errvals, title="6-point sine wave interpolation errors")
```

As demonstrated in the above example using a higher order interpolation method does not
always lead to better accuarcy.
Some thought should be given to what the data is representing.

For example, a **digital like signal** with very few samples will probably be best
represpented with [`PWC`](@ref) or [`PWL`](@ref) interpolation because the signal is not meant to
be smooth so adding a higher order method may add ringing to the signal.

For **analog signals** that are smooth with denser sampling
[`PWAkima`](@ref) should give better results.
[`PWQuadratic`](@ref) and [`PWCubic`](@ref)) tend to have issues with points that
are close together producing large spikes and unwanted ringing.
However, this isn't always the case so test interpolation methods first before
assuming one will be better than another.

For **measurements** or data read in from lab equipment a discrete signal may be
the best choice (e.g. [`Series`](@ref)).


## Reading Waveform Data


To create a signal from a file typically an external reader is used
to bring the data in as vectors of x- and y-values (see [From Vectors]).
There is some extra support for some file types which we will cover here.
If a file type isn't supported please contact support with your request.

#### From CSV Files

The [CSV](https://github.com/JuliaData/CSV.jl) package provides a flexible, high-performance reader for CSV files.
Conveignient integration to CSV is provided to easily read signals from a CSV file.

For example:

```@repl
using CSV, CedarWaves
sigs = CSV.read(joinpath("..", "signal.csv"), PWL)
vout = sigs["v(out)"]
```

The first argument to `CSV.read` is the filename
The second argument to `CSV.read` is one of the signal constructors,
such as [`PWL`](@ref) above (see [Types of Signals](@ref) for more info).
Check the examples in the [CSV documentation](https://csv.juliadata.org/stable/examples.html) as many options are supported for reading
in CSV files.

#### From Tr0 files

The [SpiceData](https://github.com/ma-laforge/SpiceData.jl) pacakge can be used to read in `.tr0` files.
Install it the regular way (e.g. `import Pkg; Pkg.add("SpiceData)`).


```@repl SpiceData
using CedarWaves
import SpiceData
f = SpiceData._open(joinpath("..", "sample.tr0"))
signames = names(f)
f.sweepname
x = f.sweep
y = read(f, first(signames))
s = PWL(x, y)
```

For convenience a function like this could be used to read in all the signals
and return a dictionary of the results:

```@repl SpiceData
function readtr0(filename)
  f = SpiceData._open(filename)
  signames = names(f)
  x = f.sweep
  results = Dict{String,Any}()
  for name in signames
    y = read(f, name)
    sig = PWL(x, y)
    results[name] = sig
  end
  close(f)
  return results
end

signals = readtr0(joinpath("..", "sample.tr0"))

keys(signals)

signals["v(out"]
```

#### From PSF files

The [LibPSF](https://github.com/ma-laforge/LibPSF.jl) pacakge can be used to read in PSF files.
Install the package in the regular way (e.g. `import Pkg; Pkg.add("LibPSF)`).

Basic usage:

```@repl LibPSF
using CedarWaves
import LibPSF
f = LibPSF._open(joinpath("..", "tran.tran"));
signames = names(f)
x = LibPSF.readsweep(f)
y = read(f, last(signames))
s = PWL(x, y)
```

For convenience a function like this could be used to read in all the signals
and return a dictionary of the results:

```@repl LibPSF
function readpsf(filename)
  f = LibPSF._open(filename)
  signames = names(f)
  x = LibPSF.readsweep(f)
  results = Dict{String,Any}()
  for name in signames
    y = read(f, name)
    sig = PWL(x, y)
    results[name] = sig
  end
  return results
end

signals = readpsf(joinpath("..", "tran.tran"))
keys(signals)
outp1 = signals["OUTP<1>"]
outn1 = signals["OUTN<1>"]
out1 = clip(outp1 - outn1, 9e-9 .. 10e-9)
```

## Creating Signals

### From Functions

In addition to the basic [Types of Signals](@ref) provided to create signals there are some default example constructors provided for conveinience.
If other types of signals would be useful please contact customer support.

#### Impulse (`impulse`)

The [`impulse`](@ref) function creates an trangular impulse with area 1.
The argument is the (average) width of the pulse (at half the height of the triange):

```@repl UG
imp = impulse(1e-15)
integral(imp) ≈ 1
```

To make the impulse a longer duration it may be helpful to use [Zero-Padding](@ref):

```@repl UG
impz = clip(ZeroPad(imp), 0 .. 1e-12)
```


#### Sinusoidal (`SIN`)

The [`SIN`](@ref) function provides a conveinient way to create a sinusoid with various attributes:

```@repl UG
s = SIN(amp=2, freq=2, offset=2, cycles=4)
```

#### Bit Sequence (`bitpattern`)

The [`bitpattern`](@ref) function provides a simple way to create a PWL signal with
a defined bit sequence, risetime and falltime, as well as other attributes to shape the pulses:

```@repl UG
bit_sequence = Bool[1, 0, 0, 1, 0, 1]
s = bitpattern(bit_sequence, tbit=10e-9, trise=1e-9, tfall=3e-9, tdelay=1e-9, vss=0, vdd=1.2)
```

### From Vectors

The most basic way to create a signal is from vectors.
The vectors could come from any process (such as calculations or data read from disk).

For example:

```@repl UG
times = 0:0.05:1
voltages = @. sin(2pi*2*times)
Series(times, voltages)
```

See [Signal Types] for differet types that can be contructed with sampled data.

### From Other Signals

#### Uniformly Sampled Signals

Uniformly sampled signals with x-values of the same step size can be best expressed as a Julia
[range](https://docs.julialang.org/en/v1/base/math/#Base.range), like so:

```@repl UG
dig = PWC(0:4, [true, false, false, true, false])
```

Julia supports a few different ways to define ranges:
- `start:stop`: step size of `1` from `start` to `stop`.
  The `stop` value may not be hit exactly if the step doesn't land on it (e.g. `0:10.5`).
- `start:step:stop`: a range with a step size other than `1` (eg `0:0.001:1`)
- `range(start, stop, length=N)`: a range that will hit the end points exactly and have `N` points.


#### Resampling Signals

A signal or function can be easily be resampled by using one of the [signal types](@ref Types-of-Signals).
For example:

```@repl UG
step_decay = PWC(0:0.1:1, x -> exp(-3x))
```

In the above example the `x -> exp(-3x)` is a quick way to create a function without a
name (see [anonymous functions](https://docs.julialang.org/en/v1/manual/functions/#man-anonymous-functions)).
The exponential decay function is sampled from `0` to `1` with steps of size `0.1`.

Now let's resample the `step_decay` signal at the same points to make it a [`PWL`](@ref) signal:

```@repl UG
lin_decay = PWL(0:0.1:1, step_decay)
```

With the resampling the `step_decay` signal with steps of `0.1` and linear interpolation the steps are gone as expected.
Note how resampling ignored the signal data between the x-values and returned a new signal with linear interpolation.

#### Signal as X-axis

A conveignient way to create signals is to use a PWL signal as the x-axis like so:

```@repl UG
t = PWL([0, 1e-6], [0, 1e-6])
```

Now the x and y axes are the same.
A shorthand for this is to use Intervals:

```@repl UG
t = PWL(0 .. 1e-6, 0 .. 1e-6)
```

Now this `t` signal can be used for creating signals:

```@repl UG
vout = sin(2pi*1e6*t) + sin(2pi*5e6*t)
```

## Signal Evaluation

Signals are similar to mathematical functions where to
get the value of a function it is evaluated at `x`, as in
`f(x)`.  For example,

```@repl math
using CedarWaves
f = PWL(0:2, [0,1,0])
f(0)
f(0.5)
f(1)
```

In addition, Julia supports a syntax to evalate a function
over a set of values, called [Broadcasting](https://docs.julialang.org/en/v1/manual/arrays/#Broadcasting).

For example, the last three evaluations above could fused
together like so:


```@repl math
xs = [0, 0.5, 1]
f.(xs)
```

So by adding a `.` after the function name and passing a vector
of x-values array operations can be easily performed.

## Basic Math Operators (`+`, `-`, `*`, `/`, `^`)

The mathematical operators are best explained with some examples.
For the examples we will use two triangular signals:

```@repl math
tr1 = PWL([0, 0.4, 0.7, 1], [0, 0, 1, 0])
tr2 = PWL([0, 0.3, 0.6, 0.9], [0.5, 1.5, 0.5, 0.5])
```

Note that the x-values (samples) do not line up and the signals have different domains.

Let's do a few mathematical operations:

### `+` addition

```@repl math
tr1 + 10  # shift up
tr1 + tr2
```

Note that the new domain of `tr1 + tr2` is the intersection, `0 .. 0.9`, of the two signal domains.

### `-` subtraction

```@repl math
tr2 - 0.5  # shift down back to zero
tr1 - tr2
```

### `*` multiplication

```@repl math
2 * tr2
tr1 * tr2
```

### `/` division

```@repl math
tr1 / 100
tr1 / tr2
```

### `^` exponentiation

```@repl math
3^tr2
tr1 ^ tr2
```

## Basic Math Functions

Signals support functions provided in base Julia.
If a function isn't supported then contact support and we can quickly add it.
Also see [Adding Custom Functions](@ref) to see how to add it yourself but
please contact support so other users can benefit too.

Here's a list of only the most popular supported functions:

- Trigonometric Functoins (scales the y-values):
  - In radians:
    [`sin`](https://docs.julialang.org/en/v1/base/math/#Base.sin-Tuple{Number}),
    [`cos`](https://docs.julialang.org/en/v1/base/math/#Base.cos-Tuple{Number}),
    [`tan`](https://docs.julialang.org/en/v1/base/math/#Base.tan-Tuple{Number}).
  - Inverse with output in radians:
    [`asin`](https://docs.julialang.org/en/v1/base/math/#Base.asin-Tuple{Number}),
    [`acos`](https://docs.julialang.org/en/v1/base/math/#Base.acos-Tuple{Number}),
    [`atan`](https://docs.julialang.org/en/v1/base/math/#Base.atan-Tuple{Number}).
  - Inverse with output in degrees:
    [`asind`](https://docs.julialang.org/en/v1/base/math/#Base.Math.asind),
    [`acosd`](https://docs.julialang.org/en/v1/base/math/#Base.Math.acosd),
    [`atand`](https://docs.julialang.org/en/v1/base/math/#Base.Math.atand).
  - Input in degrees:
    [`sind`](https://docs.julialang.org/en/v1/base/math/#Base.Math.sind),
    [`cosd`](https://docs.julialang.org/en/v1/base/math/#Base.Math.cosd),
    [`tand`](https://docs.julialang.org/en/v1/base/math/#Base.Math.tand).
  - Input in `pi` radians:
    [`sinpi`](https://docs.julialang.org/en/v1/base/math/#Base.Math.sinpi),
    [`cospi`](https://docs.julialang.org/en/v1/base/math/#Base.Math.cospi),
    [`sinc`](https://docs.julialang.org/en/v1/base/math/#Base.Math.sinc).
    [`cosc`](https://docs.julialang.org/en/v1/base/math/#Base.Math.cosc).
  - Hyperbolics:
    [`sinh`](https://docs.julialang.org/en/v1/base/math/#Base.sinh-Tuple{Number}),
    [`cosh`](https://docs.julialang.org/en/v1/base/math/#Base.cosh-Tuple{Number}),
    [`tanh`](https://docs.julialang.org/en/v1/base/math/#Base.tanh-Tuple{Number}).
  - Versions of above for:
    [`sec`](https://docs.julialang.org/en/v1/base/math/#Base.Math.sec-Tuple{Number}),
    [`csc`](https://docs.julialang.org/en/v1/base/math/#Base.Math.csc-Tuple{Number}),
    [`cot`](https://docs.julialang.org/en/v1/base/math/#Base.Math.cot-Tuple{Number}),
- Complex numbers:
  [`real`](https://docs.julialang.org/en/v1/base/math/#Base.real-Tuple{Complex}),
  [`imag`](https://docs.julialang.org/en/v1/base/math/#Base.imag),
  [`conj`](https://docs.julialang.org/en/v1/base/math/#Base.conj),
  [`deg2rad`](https://docs.julialang.org/en/v1/base/math/#Base.Math.deg2rad),
  [`rad2deg`](https://docs.julialang.org/en/v1/base/math/#Base.Math.rad2deg),
  [`angle`](https://docs.julialang.org/en/v1/base/math/#Base.angle),
  - In addition the following functions (not from base Julia) have been added:
    [`phase`](@ref),
    [`phased`](@ref).
- Log and exponent functions:
  [`log`](https://docs.julialang.org/en/v1/base/math/#Base.log-Tuple{Number}),
  [`log2`](https://docs.julialang.org/en/v1/base/math/#Base.log2),
  [`log10`](https://docs.julialang.org/en/v1/base/math/#Base.log10),
  [`exp`](https://docs.julialang.org/en/v1/base/math/#Base.exp-Tuple{Float64}),
  [`exp2`](https://docs.julialang.org/en/v1/base/math/#Base.exp2),
  [`exp10`](https://docs.julialang.org/en/v1/base/math/#Base.exp10),
  [`sqrt`](https://docs.julialang.org/en/v1/base/math/#Base.sqrt-Tuple{Real}).
  - In addition the following functions (not from base Julia) have been added:
    - [`dB10`](@ref),
      [`dB20`](@ref),
      [`dBm`](@ref).
    - [`logspace`](@ref): to create a logarithmicly spaced range.
- Rounding functions:
  [`ceil`](https://docs.julialang.org/en/v1/base/math/#Base.ceil),
  [`floor`](https://docs.julialang.org/en/v1/base/math/#Base.floor),
  [`trunc`](https://docs.julialang.org/en/v1/base/math/#Base.trunc),
  [`abs`](https://docs.julialang.org/en/v1/base/math/#Base.abs),
  [`abs2`](https://docs.julialang.org/en/v1/base/math/#Base.abs2).

## Domain Functions

Domain functions operate on the x-axis of an signal to create a new signal.

### [Intervals (`from .. to`)](@id Interval)

An `Interval` is used for continuous domains.
It represents a continuous range from the start to the end value.
See documentaiton for [clip](@ref Clip) or [`ContinuousFunction`](@ref).

For example:

```@repl domain
using CedarWaves

decay = ContinuousFunction(x->exp(-4e6*x), domain = 0 .. 10e-6)

clipped_decay = clip(decay, 0 .. 1e-6)
```

### [Domain (`domain`)](@id Domain)

The domain is the set of valid values for the x-axis.
It can be obtained with the [`domain`](@ref) function:

```@repl domain
domain(clipped_decay)
```

It is an [Interval](@ref) for continuous signals and
a list of values for discrete signals.

### [Exclusion (`clip`)](@id Clip)

Resticting or growing the domain of a signal is useful for zooming in
or out on the area of interest.
The [`clip`](@ref) function is high performance and handles changing the domain of the signal.
[`clip`](@ref) can be used as a sliding window over a signal to do calculations period by period, for example.

#### Reducing the Domain

For example:

```@repl domain
decay = ContinuousFunction(x->exp(-4e6*x))
```

The above `decay` signal has an infinite domain.
Use [`clip`](@ref) to restrict the domain:

```@repl domain
clipped_decay = clip(decay, 0 .. 1e-6)
```

#### Growing the Domain

Note in the previous example the output of `clipped_decay` outputs:
`Clipped signal with parent domain of [-Inf .. Inf]`.
Even though `clipped_decay` has a domain of `0 .. 1e-6`
it remebers the **parent** signal (`decay`) has a domain of `[-Inf .. Inf]`.
Therefore a `clip` can also grow the domain of a signal
as long as it is within the parent's domain:

```@repl domain
clipped_decay_zoom_out = clip(clipped_decay, 0 .. 5e-6)
```

To revert back to the domain of the parent call `clip` without any arguments:

```@repl domain
decay2 = clip(clipped_decay_zoom_out)
```

Even though a signal with infinite domain cannot be shown,
math can still be performed on it:

```@repl domain
d4 = 3*decay + decay2
clip(d4, 0 .. 2e-6)
```

### [Infinite to finite (`extrapolate`)](@id extrapolate)

To convert a signal with an infinite domain (such as [`Periodic`](@ref) or [`ZeroPad`](@ref)))
use the `extrapolate` function instead of [`clip`](@ref) as `clip` will not give intended
results as it clips the base domain instead of the periodic result of the signal.

```@repl domain
s = Periodic(PWL(0:0.1:2pi, sin))
extrapolate(s, 2pi .. 6pi)
```

Note, if `clip` is used instead the results are not correct:

```@repl domain
clip(s, 2pi .. 6pi)
```


### [Shifting (`xshift`)](@id XShift)

A shift in the domain of a signal is equivalent to
the function notation of `f(x) = g(x-shift)`.
Shifting signals is useful for aligning multiple signals.
The [`xshift`](@ref) function shifts the domain
returning a new signal:

```@repl domain
s = PWL(-3:0.05:3, sinc)
s2 = xshift(s, 3)
```


### [Scaling (`xscale`)](@id XScale)

A scale of the domain of a signal is equivalent to
the function notation of `f(x) = g(x/scale)`.
The [`xscale`](@ref) function scales the domain
returning a new signal:

```@repl domain
s = PWL(1e-9 .* (-3:0.05:3), t -> sinc(t*1e9))
s2 = xscale(s, 1e9)
s3 = xshift(s2, 3)
```
Signal `s2` is scaled to be in nanoseconds and then shifted right by `3`.

### [Flipping (`xflip`)](@id Flip)

To flip a signal along the x-axis, so a signal whose domain is `a .. b` is
transformed to return the original signal's values along `b .. a`.
The [`xflip`](@ref) function flips the domain
returning a new signal:

```@repl domain
s = PWL([0, 1, 5, 6], [0, 1, 4, -1])
s2 = xflip(s)
```

### [Zero Padding (`ZeroPad`)](@id Zero-Padding)

Zero padding adds zeros outside of an interval.
Therefore it is used on another signal to extend its domain.
It is often followed by a [`clip`](@ref) to restict to the domain
of interest.

```@repl UG
pulse = ZeroPad(PWL([-0.5, 0.5], [1, 1]), 0 .. 0.5)
clip(pulse, -5 .. 5)
```

### [Periodic (`Periodic`)](@id Periodic-Signal)

Periodic signals have a fundamental period over which they repeat and have an infinite domain.

The built-in [`SIN`](@ref) is periodic:

```@repl UG
s = SIN(amp=1, freq=1/5)
```

By default Periodic signals only display one period because an infinite domain signal cannot be
displayed in finite time.

#### Creating periodic signals

To create a periodic signal from an existing signal use the [`Periodic`](@ref) function:

```@repl UG
s = PWL([0,1,2], [0, 1, 0])
sp = Periodic(s)
```

#### Combining two periodic signals

If a periodic signal is combined with another periodic signal then the fundamental period grows
to the lowest common multiple of the fundamental period of the two signals:

```@repl UG
s2 = SIN(amp=1, freq=1/5) + SIN(amp=1, freq=1/8)
```

#### Combining a periodic signal with an aperiodic signal

If a periodic signal is combined with an aperiodic signal then the new signal is an
aperiodic signal:

```@repl UG
s3 = PWL([0, 25, 50], [0, 5, 0])
s4 = s2 + s3
```

Note the periodic signal, `s2`, has a period of `40` while the aperiodic signal has a period of `50`.
The resultant period is `50`.

## Range Functions

The follow functions operate on the range of the signal, returning a new signal (not a scalar).

### [Clamping y-values (`clamp`)](@id Clamp)

The [`clamp`](@ref) function takes a signal and restricts the y-values to be within the specified interval.

For example:

```@repl range
using CedarWaves
s = SIN(amp=1, freq=1)
clamp(s, -0.3 .. 0.8)
```

## Calculus Functions

### Integral

The [`integral`](@ref) function is only for continuous signals (for discontinuous use [`sum`](@ref)).
It takes a signal (or function) and the interval to integrate it over.
If no interval is given then it takes the whole domain of the signal.
For example:

```@repl UG
s = PWL(0:2, [0, 1, 0])
area = integral(s)
half_area = integral(s, 0..1)
integral(sin, 0 .. pi)
```

### Derivative

The [`derivative`](@ref) function is for getting a derivative along a continuous waveform.
For example:

```@repl UG
t = PWL(0 .. 2pi, 0 .. 2pi)
s = sin(t)
d = derivative(s)
d(pi/2) == cos(pi/2)
```

### [Convolution (`convolution`)](@id Convolution)

The [`convolution`](@ref) function can be used in the frequency or time domain and
takes two signals and convolves them with each other.

```@repl UG
triangle = PWL(-1:1, [0, 1, 0])
convolution(triangle, triangle)
```


## Frequency Domain

The Fourier transform is used to convert time domain to the frequency domain and back.
Many types of Fourier transforms are supported depending on the type of input signal:

| Transform (and inverse) | Time Domain Properties | Frequency Domain Properties|
|:--------- |:------------ |:------------- |
| Fourier Transform ([`FT`](@ref), [`iFT`](@ref)) | Continuous, Infinite, Aperiodic | Continuous, Infinite, Aperiodic |
| Discrete Time Fourier Transform ([`DTFT`](@ref), [`iDTFT`](@ref)) | Discrete, Infinite, Aperiodic | Discrete, Infinite, Aperiodic |
| Fourier Series ([`FS`](@ref), [`iFS`](@ref)) | Continuous, Periodic | Discrete, Infinite, Aperiodic |
| Discrete Fourier Transform ([`DFT`](@ref), [`iDFT`](@ref), [`FFT`](@ref), [`iFFT`](@ref)) | Discrete, Periodic | Discrete, Periodic |

For functions that take a periodic input if the input is not periodic it will be converted to periodic
using the domain of the signal as the fundamental period.

For functions that require an infinite domain (that are not periodic) the input signal will be zero padded
outside of its domain.

The following examples use a pulse (train) to demonstate the different Fourier transforms.



### [Fourier Transform (`FT`)](@id Fourier-Transform)

The Forier Transform function [`FT`](@ref) is for decomposing a continuous, aperiodic signal into the frequency domain.
The output is a continuous signal with inifinite domain but it is clipped to `±10*Fmin.

The input signal will be assumed to be zero outside of it's domain.

For example,

```@repl freq
using CedarWaves
pulse = clip(ZeroPad(PWL(-0.5:0.5, [1, 1])), -1 .. 1)  # unit pulse
```
Take the Fourier Transform:

```@repl freq
ft = FT(pulse)
```

The theoretical answer for the Fourier Transform of a pulse of width `T` and height `A` is:

```@repl freq
freq_pulse(freq; A=1, T=1) = A*T*sinc(freq*T) + im*0
```

```@jldoctest freq
julia> ft(0) ≈ freq_pulse(0)    # component at DC
true

julia> ft(0.5) ≈ freq_pulse(0.5)    # component at 0.5 Hz
true
```

To see only real components of positive frequencies up to 10 Hz:


```@repl freq
ft2 = clip(real(ft), 0 .. 10)
```

### [Fourier Series (`FS`)](@id Fourier-Series)

The Fourier Series function, [`FS`](@ref), takes a continuous-time signal with finite duration, `T`,
and assumes it is `T`-periodic.

The pulse from the Fourier Transform example above can be thought of as a Fourier Series but with
the periodic interval of infinity.  Lets use a pulse with a 50% duty cycle and make it smaller
and smaller to approximate the Fourier Transform.

```@repl freq
T = 2
pulse2 = clip(pulse, -T/2 .. T/2)
```

The Fourier Series assumes the input signal is Periodic (if it has a finite domain).
Taking the Fourier Series:


```@repl freq
fs2 = clip(FS(clip(pulse2, -1 .. 1)), 0 .. 10)
```

The Fourier Series is basically a Fourier Trasform but the results scaled by `1/T` and the
result is discrete in steps of `1/T`.  For example:

```@jldoctest freq
julia> fs2(1/T) ≈ ft2(1/T)/T
true

julia> fs2(2/T) ≈ ft2(2/T)/T
true

julia> fs2(3/T) ≈ ft2(3/T)/T
true
```

Expanding the space between pulses the Fourier Series is a closer approximation of the Fourier Transform:

```@repl freq
T = 20
fs20 = clip(FS(clip(pulse2, -T/2 .. T/2)), 0 .. 10)
```

Now the step size of the Fourier Series is `1/T = 0.05` Hz which is closer to the continuous Fourier Transfrorm.

Checking a few points:

```@jldoctest freq
julia> fs20(1/T) ≈ ft2(1/T)/T
true

julia> fs20(2/T) ≈ ft2(2/T)/T
true

julia> fs20(3/T) ≈ ft2(3/T)/T
true
```


### [Discrete Fourier Transform (`DFT`)](@id Discrete-Fourier-Transform)

The Discrete Fourier Transform the input signal is uniformly sampled and assumed to be periodic.
For example a pulse with a 50% duty cycle:

```@repl freq
T = 2
pulse3 = clip(pulse2, -T/2 .. T/2)
dft = extrapolate(DFT(pulse3, N=101), -10 .. 10)
```

Note in the plot above that the result of the DFT is periodic about N frequency points.

Let's check that the result gives similar results to the other tranforms:


```@repl freq
abs(dft(1/T))
abs(fs2(1/T))
abs(ft2(1/T)/T)
```

Samping the continuous signal to create the DFT will change the result slightly.





## Measurements

### Measurement Overview

Measurements are scalar metrics from waveforms and have a few common features:
1. Measurements are displayed as a bold underlined number
2. The annotated waveform of the measurement can be plotted with [`inspect`](@ref) to make debugging easy.
3. Measurements have properties to make it easy to access attributes related to the measurement.
4. Measurements can be given a `name` (the default is the name of the function).

As an example, many statistical functions return a Measurement.  For example:

```@repl UG
s = PWL(0:3, [0, 1, -1, 0]);
m1 = ymin(s, name="min_out")
```

Note that measurements are numbers that are shown in bold with an underline.

### Inspecting Measurements

Often a user wishes to see the waveform the measurements were taken from to understand
the measurement.  To plot the measurement use [`inspect`](@ref):

```@repl UG
inspect(m1)
```

An ASCII plot of the measurement is shown with the measurement highlighted
in orange while other annotations are shown in blue.

Measurements can also be graphically plotted with `using Plots` followed by `plot(m1)`.

### Measurement Properties

Associated data can be obtained by a measurement such as the corresponding `x` value, `name` and `signal`.
To view the properties in the Julia REPL type `.<tab>`:

```
julia> m1.
name    options  signal   slope    value    x        y
```

For example often the corresponding `x` value for `ymin` is desired.
Instead of calling a different function it can be obtained through the measurement:

```@repl UG
m1.x
m1.name
m1.signal
```

### Measurement Expressions

A measurement can be used as a number in mathematical expressions, automatically converting
to a float:

```@repl UG
m1
m1 + 5
10 * m1 / 5
```

A measurement can be converted to float if it isn't supported
in a function:

```@repl UG
round(float(m1), sigdigits=3)
```

### Measurement Performance

A measurement keeps track of the waveform and other properties
which can slow down code that needs to be high performance.
To skip creating a measurement and just return a floating point number with
no debugging capability pass `trace=false` to the measurement function:

```@repl UG
m2 = ymin(s, trace=false)
```

## Statistical Functions

### Minimum x-value

To get the first value of the domain use [`xmin`](@ref):

```@repl UG
xmin(PWL([2, 3], [4, 5]))
```

### Maximum x-value

To get the last value of the domain use [`xmax`](@ref):

```@repl UG
xmax(PWL([2, 3], [4, 5]))
```

### Span of x-values

To get the span of the domain use [`xspan`](@ref):

```@repl UG
xspan(PWL([2, 3], [4, 5]))
```

### Minimum y-value

To get the minimum y-value use [`minimum`](@ref) or [`ymin`](@ref):


```@repl UG
s = SIN(amp=1, freq=1/3) + SIN(amp=1, freq=1/6)
ymin(s)
```

### Maximum y-value

To get the maximum y-value use [`maximum`](@ref) or [`ymax`](@ref):


```@repl UG
s = SIN(amp=1, freq=1/3) + SIN(amp=1, freq=1/6)
ymax(s)
```

### Extrema values

To get both the minimum and maximum y-value use [`extrema`](@ref):


```@repl UG
s = SIN(amp=1, freq=1/3) + SIN(amp=1, freq=1/6)
extrema(s)
```

### Peak to Peak value

To get the difference of the maximum and minimum y-value use [`peak2peak`](@ref):

```@repl UG
s = SIN(amp=1, freq=1/3) + SIN(amp=1, freq=1/6)
peak2peak(s)
```

### Mean value

To get the statistical mean of a signal use the [`mean`](@ref) function:

```@repl UG
s = SIN(amp=1, freq=1/3) + SIN(amp=1, freq=1/6)
mean(s)
```

### Sum value

To add up all the y-values of a discrete signal use the [`sum`](@ref) function:

```@repl UG
sum(Series(0:4, 1:5))
```

For continuous signals use [`integral`](@ref) instead.

### Standard deviation

To get the standard deviation of a signal use the [`std`](@ref) function:

```@repl UG
std(Series(0:4, 1:5))
std(PWL(0:4, 1:5))
```

### Root-mean-squared (rms) value

To get the rms value of a signal use the [`rms`](@ref) function:

```@repl UG
rms(Series(0:4, 1:5))
rms(PWL(0:4, 1:5))
```


## Crossing Functions

To find the x-value when a signal crosses a y-threshold use:
- [`eachcross`](@ref): an iterator return each crossing's x-value.
- [`cross`](@ref): returns the Nth cross.
- [`crosses`](@ref): returns all the crossings.

For example:

```@repl UG
s = PWL(0:3, [0, 1, -1, 0])
```

```@repl UG
crosses(s, 0.5)

crosses(s, either(0.5))
```

The above example finds the crossings at either the rising of falling edge.
To limit the cross to only the rising or falling edge use:
- [`rising`](@ref): to find rising edges only.
- [`falling`](@ref): to find falling edeges only.
- [`either`](@ref): to find both rising and falling edges (the default).

For example:

```@repl UG
crosses(s, rising(0.5))

crosses(s, falling(0.5))
```

Measurements by default only show the value (number) of the measurement (in bold with an underline)
but can be plotted with `inspect` for debugging:

```@repl UG
inspect(cross(s, falling(0.5)))
```

To build a custom example lets create a function to find an edge:

```@repl UG
function findedge(s::Signal, yth1, yth2)
    x1 = cross(s, yth1)  # First crossing
    s2 = clip(s, x1 .. xmax(s)) # clip to remaining part of signal
    x2 = cross(s2, rising(yth2)) # Second crossing
    edge = clip(s2, x1 .. x2)
end
```

Let's test it:

```@repl UG
pulse = PWL([0,0.5,1,2,3,4], [1, 1, 0, 0, 1, 1])
```

```@repl UG
# TODO: fixme:
# rising_edge = findedge(pulse, rising(0.25), rising(0.75))
```

```@jldoctest UG
julia> # trise = xspan(rising_edge)
```

In the following sections there are more advanced functions for measuring different
types of edges.

### Risetime and Falltime

The risetime and falltime can be measured with the [`risetime`](@ref) and [`falltime`](@ref) functions.
For example:

```@repl UG
t = 0:0.005:1
freq = 2
y = @. 0.5*(1 + sin(2pi*freq*t) + 1/3*sin(2pi*freq*3t) + 1/5*sin(2pi*freq*5t));
s1 = PWL(t, y)
rt = risetime(s1, yths=[0.2, 0.8])
ft = falltime(s1, yths=[0.8, 0.2])
```

They also act as a regular number when using the measure in a mathematical expression:

```@jldoctest UG
julia> avg_rft = (rt + ft)/2
0.03518388968977358
```

### Slewrate

The slewrate can be measured with the [`slewrate`](@ref) function.
For example:

```@repl UG
sr = slewrate(s1, rising(0.2), rising(0.8))
```

Like other measures the slewrate acts as a regular number when using the measure in a mathematical expression:

```@jldoctest UG
julia> 15 < sr < 20
true
```

### Delay

The delay between two signals can be measured with the [`delay`](@ref) function.
For example:

```@repl UG
s1
s2 = 1 - s1
d1 = delay(signal1=s1, signal2=s2, yth1=falling(0.75), yth2=rising(0.1), N2=3)
```

As with other measures, math can be performed on the measurement:

```@jldoctest UG
julia> half_delay = d1/2
0.2439159335721318
```



## Plotting Waveforms

### Plotting Packages

Plotting waveforms can be done with various packages.
The function [`toplot`](@ref) is provided to integrate with any plotting library by
returning the x- and y-values to plot.

#### Natively Supported Packages

[Plots](https://github.com/JuliaPlots/Plots.jl): this is the most popular Julia plotting package.
It has multiple backends and supports interacting with the plots.
Simply call `plot(signal)` to produce a plot.

#### Other Packages

Any plotting package that takes a vector for x- and y-values can be used.
The [`toplot`](@ref) function takes a signal and returns the x- and y-vector for plotting.
For example:

```@repl UG
using Plots
t = PWL(0 .. 2pi, 0 .. 2pi);
s = sin(t);
x, y = toplot(s);
plot(x, y);
```

Some suggested plotting packages:

1. [UnicodePlots](https://github.com/JuliaPlots/UnicodePlots.jl): this is the default plotting packages and outputs to the terminal for a quick, low resolution plot.
1. [Makie](https://github.com/JuliaPlots/Makie.jl): this is a new plotting package that is high performance and based on OpenGL with advanced interactivity.  One downside is it takes a long time to load the first time.
1. [PyPlot](https://github.com/JuliaPy/PyPlot.jl): this is a wrapper of the Matplotlib Python plotting package.

## Online analysis

This package can be used in two ways. So far we have looked at offline post-processing, where you run a simulation, load the data, and run analysis on it.
However, Cedar Waves also supports online analysis, where samples from the simulator are analysed on the fly.
This allows detecting errors early, and allows working with datasets that are larger than memory.

Online analysis is based on Julia's [asynchronous programming](https://docs.julialang.org/en/v1/manual/asynchronous-programming/) facilities, allowing multiple measurements to run in parallel and receive new data via `Channels`.

There are several components to online analysis. First of all there is the simulator interface that can produce streaming data. This functionality is offered by TODO.
The simulator interface then pushes the samples onto the `Channel` of an [`OnlineSignalFactory`](@ref), which is used to make [`new_online`](@ref) signals backed by a shared `CircularBuffer`.

Measurements on an online signal block until samples are pushed into the factory's `Channel` and can then access the samples in the `CircularBuffer`.
Care must be taken that each online signal is fully consumed exactly once, so as to drain its `Channel` correctly.
Online analysis works best with iterative measurements. But if desired, it's possible to use [`postprocess`](@ref) once the simulation is stopped to analyse all the samples in the buffer.

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

## Advanced Usage

### Writing Scripts

Cedar Waves is designed to be extendable by the end users by writing custom functions.
Custom functions can be written and are as fast as the built-in functions since both built-in
functions and custom functions are written in Julia.
Custom function can be put in a file and then loaded with `include` or added as a separate package.

#### Revise

When developing functions it is convenient to use the [Revise](https://github.com/timholy/Revise.jl)
package to speed up development.
This package allows the custom function to be modified and then immediately re-run in the Julia REPL
without having to restart Julia.

### Adding Custom Functions

#### Y-value Functions

For custom functions that operate on the y-values the [`ymap_signal`](@ref) function
can be used like so:

```@repl UG
function my_double(signal)
    ymap_signal(y->2*y, signal)
end
```

The [`ymap_signal`](@ref) function takes a single argument function to modify the y-values
as the first argument and the signal as the second argument.

Then the custom function can be used as follows:

```@repl UG
s = PWL(0:2, [1, -1, 2])
my_double(s)
```

In the second plot all the y-values have been doubled.

### Signal Iteration

For more advanced custom functions the signal may need to be iterated over and sampled.
A custom iteration scheme can be used by utilizing the `domain` of the signal
and evaluating at any point of the signal.
For continuous signals they have an infinite number of points so some algorithm
must be used to efficiently sample the points of interest of the signal.

The following built-ins are provided to help with this:
- [`domain`](@ref): returns the domain of the signal as an [`Interval`](@ref).
- [`eachx`](@ref): returns an iterator of each x-value if discrete; for continuous signals it returns each sample or if the `dx` parameter is set then the step size of `dx` is used.
- [`eachy`](@ref): similar to [`eachx`](@ref) but returns y-values.
- [`eachxy`](@ref): similar to [`eachx`](@ref) but returns a tuple of `(x_value, y_value)` for each iteration.
- [`xvals`](@ref): returns a vector of the x-values.
- [`yvals`](@ref): returns a vector of the y-values.

As an example let's create a custom function that takes a signal and plots a histogram of
the time steps.

First let's take helper function to return all the time steps of the signal, called `xdiff`:

```@repl UG
function xdiff(signal)
    vec = Float64[] # initialize empty vector for results
    x1, rest = Iterators.peel(eachx(signal)) # take first value and return iterator of rest of values
    for x2 in rest
        xdiff = x2 - x1
        push!(vec, xdiff)
        x2 = x1
    end
    return vec
end
```

Then we will create another function that plots a histogram of the time steps given a signal.

```@repl UG
function timestep_histogram(signal)
    timesteps = xdiff(signal)
    UnicodePlots.histogram(timesteps)
end
```

Now let's test it out:
```@repl UG
xs = sort!(abs.(randn(1000)))  # random time points (guassian)
ys = @. sin.(2*pi*3*xs) # doesn't matter what y-values are
signal = PWL(xs, ys)
timestep_histogram(signal)
```

For a real signal from a simulator the results are more interesting.
From `xdiff` it is easy to chain it together with other statistical
functions to find other values:

```@repl UG
mean(xdiff(signal))
maximum(xdiff(signal))
```


### Signal Type Attrubutes

When writing a custom function it is sometimes necessary to check the type of the input signal
to determine the correct algorithm to use.  For example, if the signal is discrete then the
`mean` value uses `sum` while a continuous signal it uses `integral`.

The following functions can be used to query the type of the signal.

#### Continuous vs Discrete

To check if the type of signal is continuous use
[`iscontinuous`](@ref)`(signal)` which returns `true` if signal is [continuous](@ref Continuous-Signals).

To check if the type of signal is discrete use
[`isdiscrete`](@ref)`(signal)` which returns `true` if signal is discrete.

For example:

```@jldoctest UG
julia> s = PWL(0:3, [0,1,-1,0]);

julia> iscontinuous(s)
true

julia> s2 = Series(xvals(s), s);

julia> isdiscrete(s2)
true
```

#### Finite vs Infinite

Signals with a finite extent will return `true` from [`isfinite`](@ref).
Periodic and other signals with an infinite duration will return `true`.

For example:

```@jldoctest UG
julia> s = PWL(0:3, [0,1,-1,0]);

julia> isfinite(s)
true

julia> s2 = Periodic(s)

julia> isfinite(s2)
false
```

#### Sampled vs Pure Function

Sampled signals (continuous or discrete) will return `true` for [`issampled`](@ref)`(signal)`.
Continuous signals will return `true` for [`iscontinuous`](@ref)`(signal)` functions.
Therefore a pure function is `!isampled(s) && iscontinuous(s)`, for example:

```@jldoctest UG
julia> s = SIN(amp=1, freq=1);  # a pure function

julia> issampled(s)
false

julia> iscontinuous(s)
true
```
