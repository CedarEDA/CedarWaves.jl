# Deconstruction

To get the x- and y-values back from a signal use the `x` and `y` properties of the signal:

```@repl deconstruction
using CedarWaves
x = 0:3  # x-values: 0, 1, 2, 3 
y = [0, 1, -1, 0] # y-values
pwl = PWL(x, y)
pwl.x
pwl.y
```

Or a Signal can be converted to an `Array` like so:

```@repl deconstruction
Array(pwl)
```
