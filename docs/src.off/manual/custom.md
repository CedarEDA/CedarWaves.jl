# Writing Custom Functions

## Signal Types

To write custom functions sometimes it is useful to specialize a function to a type of signal.
For this it is useful to understand the type of a signal.

The type of the signal can be obtained with `typeof`:

```@repl s1
typeof(pwl)
typeof(pwc)
typeof(series)
```

The signal type consists has a primary type of `PWL`, `PWC` or `Series` with 5 type parameters representing the type of the signal:

- the primary type of the signal (e.g. `PWL`, `PWC`, `Series`)
- **kind** of signal (e.g. `PWLKind`, `PWCKind`, `SeriesKind`)
- x-element type
- y-element type
- x-vector type
- y-vector type

each of these can be retrieved through the following functions:

```@repl s1
typeof(series)
signal_type(series)
signal_kind(series)
eltype(series.x)
eltype(series.y)
typeof(series.x)
typeof(series.y)
```