# Overview

The signals functions are loaded with `using CedarWaves`.  
This provides an easy to use abstraction for dealing with waveform data from 
simulators and making measurements.

There are two different kinds of signals:

- Continuous
- Discrete

Analog simulators normally produce waveform data as values vs time and they represent continuous signals.

There are two different types of Continuous signals:

- Piecewise-Linear (`PWL`): standard for analog simulations which uses linear interpolation
- Piecewise-Constant (`PWC`): standard for digital simulations (value instantaneously changes and stays constant until next point)

`PWL` siganls are normal for analog simulations while `PWC` are for digital simulations.

For Discrete kind of signals there is one type:

- `Series`: used in situations where there is no interpolation.
