# Construction 

To create a signal provide the x- and corresponding y-values to one of the constructors (`PWL`, `PWC` or `Series`):

## PWL 

```@repl s1
using CedarWaves, Plots
x = 0:3  # x-values: 0, 1, 2, 3 
y = [0, 1, -1, 0] # y-values
pwl = PWL(x, y)
plot(pwl, shape=:circle, label="PWL signal");
savefig("pwl.svg") # hide
nothing # hide
```

![](pwl.svg)

## PWC 

```@repl s1
pwc = PWC(x, y)
```
```@repl s1
plot(pwc, shape=:circle, label="PWC signal");
savefig("pwc.svg") # hide
nothing # hide
```

![](pwc.svg)

## Series

```@repl s1
series = Series(x, y)
plot(series, label="Series signal");
savefig("series.svg") # hide
nothing #hide
```

![](series.svg)

For a valid signal:
- The length of the x and y vectors must be equal
- The x-values must be monotonically increasing

Note the constructors do not copy the data so many signals may share the same x-axis vector.
