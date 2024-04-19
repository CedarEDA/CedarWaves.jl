# CedarWaves

[![Build status](https://badge.buildkite.com/86de0287723ad329091f4fe12877d83bf33736ccde1dd8d027.svg)](https://buildkite.com/julia-computing-1/cedarwaves-dot-jl)

## Overview

Analog CircuitSignals.jl is designed to provide the functionality typically found in an oscilloscope. At the core, a signal is represented with the `Signal` type. A `Signal` may represent sampled or continuous data, and perform operations such as interpolation and extrapolation efficiently. The most common used interpolation in analog signal analysis is a PWL, or Piece-Wise Linear signal. Since `CedarWaves` is backed by DataInterpolations.jl, it supports a full complement of interpolation mechanisms that can be used to aid further analysis.

Since long-running data collection may run into the gigabyte range of data, `CedarWaves` performs lazy transformations on the data. A `Signal` behaves like a function and may be composed with most common Julia functions:

```
s1 = PWL(1:5, rand(5))
s1(0.5)
s1 = -s1
s1(0.5)
```

The basic transformations for aligning and windowing/clipping data are:

- `clip`
- `xshift`
- `xscale`

Signals may also be composed together to return a new `Signal`. This includes both Signals derived from descrete data and continuous signals derived from functions.


## Building the documentation

```
cd docs
julia --project=.. -L serve.jl
```

Open http://localhost:8801/build
