<a name="logo"/>
<div align="center">
<img src="docs/img/cedar_waves.svg" alt="CedarWaves Logo"></img>
</div>
</a>

<a href="https://help.juliahub.com/cedarwaves/dev/"><img src='https://img.shields.io/badge/docs-dev-blue.svg'/></a>

> [!WARNING]
> The public release of Cedar is ongoing. You are welcome to look around, but things will be unstable and various pieces may be missing. If you are not feeling adventurous, please check back in a few weeks.

## Overview

CedarWaves.jl is designed to provide the functionality typically found in an oscilloscope. At the core, a signal is represented with the `Signal` type. A `Signal` may represent sampled or continuous data, and perform operations such as interpolation and extrapolation efficiently. The most common used interpolation in analog signal analysis is a PWL, or Piece-Wise Linear signal. Since `CedarWaves` is backed by DataInterpolations.jl, it supports a full complement of interpolation mechanisms that can be used to aid further analysis.

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

# License / Contributing

The Cedar EDA platform is dual-licensed under a commercial license and CERN-OHL-S v2. In addition, some packages (including this one) are also available under the MIT license. Please see the LICENSE file for more
information and the LICENSE.FAQ.md file for more information on how to
use Cedar under the CERN-OHL-S v2 license.

We are accepting PRs on all Cedar repositories, although you must sign the Cedar Contributor License Agreement (CLA) for us to be able to incorporate your changes into the upstream repository. Additionally, if you would like to make major or architectural changes, please discuss this with us *before* doing the work. Cedar is a complicated piece of software, with many moving pieces, not all of which are publicly available. Because of this, we may not be able to take your changes, even if they are correct and useful (so again, please talk to us first).

## Building the documentation

```
cd docs
julia --project=.. -L serve.jl
```

Open http://localhost:8801/build
