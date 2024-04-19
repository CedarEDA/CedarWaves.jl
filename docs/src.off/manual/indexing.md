# Indexing

The values of the signal can be obtained for a particular index.

```@repl indexing
using CedarWaves
x = 0:3  # x-values: 0, 1, 2, 3 
y = [0, 1, -1, 0] # y-values
pwl = PWL(x, y)
pwl[begin]
pwl[2]
pwl[end]
```

Note that indexing in Julia by default starts with `1` but it can be changed.
It is good practice to use index `begin` as the first index and `end` as the last index.
For example, [`dft`](@ref) results start with `0` for DC and `1` for the first harmonic.

The valid indices can also be returned with the `index` property:

```@repl indexing
pwl.index
```
