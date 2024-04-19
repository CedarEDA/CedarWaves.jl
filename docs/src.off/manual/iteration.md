# Iteration

To iterate over the values of an array at each index simple reference put the signal in a `for` loop:

```@repl iteration
using CedarWaves, Plots
x = 0:3  # x-values: 0, 1, 2, 3 
y = [0, 1, -1, 0] # y-values
pwl = PWL(x, y);

for (x, y) in pwl
    @show x, y
end
```

Or to iterate over each index:

```@repl iteration
for idx in eachindex(pwl)
    @show idx, pwl[idx]
end
```

The above is useful for when indices start with numbers other than `1` (see [`clip`](@ref))
