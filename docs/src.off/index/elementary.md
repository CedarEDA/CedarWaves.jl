# Elementary functions

The following functions are documented in the main [Julia documentation](https://docs.julialang.org/) and are extended to support signals.

## Single argument functions

These functions are broadcasted to the y-values and return a
signal with the same x-axis value:

```@docs
sin
cos
sincos
tan
sind
cosd
tand
sinpi
cospi
sincospi
sinh
cosh
tanh
asin
acos
atan
asind
acosd
atand
sec
csc
cot
secd
cscd
cotd
asec
acsc
acot
asecd
acscd
acotd
sech
csch
coth
asinh
acosh
atanh
asech
acsch
acoth
sinc
cosc
deg2rad
rad2deg
log
log2
log10
log1p
frexp
exp
exp2
exp10
expm1
ceil
floor
trunc
abs
abs2
sign
signbit
sqrt
isqrt
cbrt
real
imag
conj
angle
cis
cispi
ispow2
div
```

These functions operate on the y-values and return a scalar:

```@docs
minimum
maximum
sum
#prod
#cumprod
#cumsum
```


## Multi-argument functions

These functions are broadcasted to the y-values and return a signal with the same x-axis:

```docs
round
```

