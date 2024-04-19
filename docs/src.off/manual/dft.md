# Frequency Domain Analysis

This example shows how to create a signal of 3 frequency components and get the values of each
harmonic that match the time domain components.

Create a time vector from 0 to 1 at the sample rate `Fₛ`:

```@setup dft
using CedarWaves
using Plots
```

```@repl dft
Fₛ = 50  # sample frequency
t = 0:1/Fₛ:1
```

Create a y-vector with the following compontents:
  * DC offset with amplitude=1
  * 2 Hz component with amplitude=2 
  * 4 Hz component with amplitude=3

```@repl dft
y = @. 1 + 2*sind(360*2*t) + 3*cosd(360*4*t);
```

`sind` (in degrees) is used instead of `sin` since `pi` is an inaccurate number. 
The `@.` macro broadcasts all functions for each element of `t`.

Create a piecewise-linear signal:

```@repl dft
vsin = PWL(t, y);
```

Plot the signal:

```@repl dft
plot(vsin, title="Time Domain");
savefig("vsin.svg") # hide
nothing # hide
```

![](vsin.svg)

Now take the discrete fourier transform:

```@repl dft
H = dft(vsin, endpoint=false);
```

Note that we don't want to use the last point of `vsin` for the dft since it 
is the same as the first point (start of period) so we use `endpoint=false` 
(which is the default so it isn't needed here but used for demonstration).  

```@repl dft
plot(H, title="Discrete Fourier Transform of a signal");
savefig("H.svg") # hide
nothing # hide
```

![](H.svg)

Now check that the fourier components at each index is the same as the input signal.
The starting index of a fourier transform starts at `0` to represent DC:

```@jldoctest dft
julia> abs(H.y[0]) ≈ 1  # magnitude
true
julia> H.x[0] ≈ 0       # frequency
true
```

For the second harmonic at index `2`:

```@jldoctest dft
julia> abs(H.y[2]) ≈ 2  # magnitude
true
julia> abs(H.x[2]) ≈ 2  # frequency
true
```

For the fourth harmonic at index `4`: 

```@jldoctest dft
julia> abs(H.y[4]) ≈ 3  # forth harmonic magnitude
true
julia> abs(H.y[4]) ≈ 4  # forth harmonic frequency
true
```

Or use a function call to get the corresponding amplitude at a particular frequency:

```@jldoctest dft
julia> abs(H(0)) ≈ 0  # at 0 Hz
true
julia> abs(H(2)) ≈ 1  # at 2 Hz
true
julia> abs(H(4)) ≈ 3  # at 4 Hz
true
```

Note that the output is a `Series` which is discrete so interpolating will cause an error:

```@repl dft
H(1.5)
```

To allow interpolation convert it to a `PWL` signal:

```@repl dft
H2 = PWL(H);
abs(H2(1.5))
```

The input signal has no frequency component at 1.5 Hz so make sure
it is understood when to do this.


For comparison take the discrete fourier transform of the y-vector and plot:

```@repl dft
Hy = dft(vsin.y[begin:end-1]);  # remove last point
plot(Hy, title="Discrete Fourier Transform of a vector");
savefig("Hy.svg") # hide
nothing # hide
```

![](Hy.svg)

Note that this is similar to an FFT in Matlab where the amplitude is `N` times larger
and from index `26` to `49` it is a mirror image of the lower frequency components. 