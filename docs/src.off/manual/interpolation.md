# Interpolation

Signals can be thought of a function where the value of the function at an x-value returns the corresponding y-value.
To interpolate into a signal call it as a function like so:

```@setup interp
using CedarWaves, Plots
x = 0:3  # x-values: 0, 1, 2, 3 
y = [0, 1, -1, 0] # y-values
pwl = PWL(x, y);
pwc = PWC(x, y);
series = Series(x, y);
```

```@repl interp
pwl(0.5)
```

and it will return the corrresponding y-value at the given x-value for signal `sig1`.

The alternate [`interpolate`](@ref) function can also be used to perform the same function:

```@repl interp
interpolate(pwl, 0.5)
```

For some examples, we will use the following signals:

```@repl interp
using CedarWaves, Plots
x = 0:3  # x-values: 0, 1, 2, 3 
y = [0, 1, -1, 0] # y-values
pwl = PWL(x, y);
pwc = PWC(x, y);
series = Series(x, y);
plot(pwl, label="pwl");
plot!(pwc, label="pwc");
plot!(series, label="series", title="Example Signals");
savefig("pwl_interp_signal.svg") # hide
nothing #hide
```

![](pwl_interp_signal.svg)

For continuous signals the y-value will be interpolated like so:

```@repl interp
xval = 0.5
yval = pwl(xval)
plot(pwl, shape=:circle, label="PWL signal", title="PWL Interpolation");
plot!([xval], [yval], shape=:circle, markercolor=:red, label="interpolated at $xval");
savefig("pwl_interp.svg") # hide
nothing #hide
```

![](pwl_interp.svg)

Like-wise `PWC` signals can be interpoltated:

```@repl interp
xval = 0.5
yval = pwc(xval)
plot(pwc, shape=:circle, label="PWC signal", title="PWC Interpolation");
plot!([xval], [yval], shape=:circle, markercolor=:red, label="interpolated at $xval");
savefig("pwc_interp.svg") # hide
nothing #hide
```

![](pwc_interp.svg)

`Series` signals are discrete so they cannot be interpolated.  For example:


```@repl interp
xval = 0.5
yval = series(xval)
```

If the x-value is contained in the signal and no interpolation is needed and it will work:

```@repl interp
xval = 2
yval = series(xval)
plot(series, shape=:circle, label="Series signal", title="Series Interpolation");
plot!([xval], [yval], shape=:circle, markercolor=:red, label="interpolated at $xval");
savefig("series_interp.svg") # hide
nothing #hide
```

![](series_interp.svg)

Interpolating the signals is an error if the x-value is out of bounds:

```@repl interp
pwl(-1)
pwc(10)
series(100)
```
