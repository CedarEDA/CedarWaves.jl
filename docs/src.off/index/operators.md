# Operators

Basic mathematical operations are supported for signals.

## Unary operators

```@setup ops
append!(LOAD_PATH, ["..", "../..", "../../.."])
using CedarWaves, Plots
```

The following signal is used to demonstrate unary operators:

```@repl ops
s1 = PWL(0.0:2.0, [2.0, 1, 0]);
plot(s1, label="s1 with $(length(s1)) points");
savefig("s1.svg") # hide
```

![](s1.svg)

### `+` (unary addition)

```@repl ops
plus_s1 = +s1;
plot(s1, label="s1");
plot!(plus_s1, label="+s1");
savefig("plus_s1.svg") # hide
```
![](plus_s1.svg)

### `-` (unary subtraction)

```@repl ops
sub_s1 = -s1;
plot(s1, label="s1");
plot!(sub_s1, label="-s1");
savefig("sub_s1.svg") # hide
```
![](sub_s1.svg)

### `!` (unary negation)

Negation is only valid for boolean values:

```@repl ops
sbool = PWC(0.0:2.0, [false, true, false]);
neg_sbool = !sbool;
plot(sbool, label="sbool");
plot!(neg_sbool, label="!sbool");
savefig("neg_sbool.svg") # hide
```
![](neg_sbool.svg)


## Binary operators

For demonstration two signals are created below with the second signal, `s2`, having three extra points:

```@repl ops
s1 = PWL(0.0:2.0, [2.0, 1, 0]);
s2 = PWL([0.0, 0.25, 0.5, 0.75, 1, 2], [0.0, 0.25, 0.5, 0.75, 1, 0]);
plot(s1, label="s1 with $(length(s1)) points");
plot!(s2, label="s2 with $(length(s2)) points");
savefig("s2.svg") # hide
```

![](s2.svg)

!!! note

	For most operations the [`xspan`](@ref) must be the 
	same but the x vector can be different and the
	points will be interpolated to include all of the 
	points from both signals.

### `+` (addition)

#### `signal1 + signal2`

```@repl ops
splus = s1 + s2;
plot(s1, label="s1");
plot!(s2, label="s2");
plot!(splus, label="s1 + s2");
savefig("splus.svg") # hide
```
![](splus.svg)

#### `signal + scalar` (or `scalar + signal`)

```@repl ops
splus2 = s1 + 2;
plot(s1, label="s1");
plot!(splus2, label="s1 + 2");
savefig("splus2.svg") # hide
```
![](splus2.svg)

### `-` (subtraction)

#### `signal1 - signal2`

```@repl ops
sminus = s1 - s2;
plot(s1, label="s1");
plot!(s2, label="s2");
plot!(sminus, label="s1 - s2");
savefig("sminus.svg") # hide
```
![](sminus.svg)

#### `signal - scalar` (or `scalar - signal`)

```@repl ops
sminus2 = s1 - 2;
plot(s1, label="s1");
plot!(sminus2, label="s1 - 2");
savefig("sminus2.svg") # hide
```
![](sminus2.svg)

### `*` (multiplication)

#### `signal1 * signal2`

```@repl ops
smult = s1 * s2;
plot(s1, label="s1");
plot!(s2, label="s2");
plot!(smult, label="s1 * s2");
savefig("smult.svg") # hide
```

![](smult.svg)

#### `signal * scalar` (or `scalar * signal`)

```@repl ops
smult2 = s1 * 2;
plot(s1, label="s1");
plot!(smult2, label="s1 * 2");
savefig("smult2.svg") # hide
```

![](smult2.svg)

### `/` (division)

#### `signal1 / signal2`

```@repl ops
sdiv = s1 / s2
plot(s1, label="s1");
plot!(s2, label="s2");
plot!(sdiv, label="s1 / s2");
savefig("sdiv.svg") # hide
```

![](sdiv.svg)

#### `signal / scalar` (or `scalar / signal`)

```@repl ops
sdiv2 = s1 / 2
plot(s1, label="s1");
plot!(sdiv2, label="s1 / 2");
savefig("sdiv2.svg") # hide
```

![](sdiv2.svg)

### `÷` (truncated division) 

The `÷` operator is for integer truncated division (e.g. `3÷2==1`). 
The character `÷` can be typed `\div<tab>` or use the alias `div(a, b)` for the same operation.

#### `signal1 ÷ signal2`

```@repl ops
sdivide = s1 ÷ s2
plot(s1, label="s1");
plot!(s2, label="s2");
plot!(sdivide, label="s1 ÷ s2");
savefig("sdivide.svg") # hide
```
![](sdivide.svg)


#### `signal ÷ scalar` (or `scalar ÷ signal`)

```@repl ops
sdivide2 = s1 ÷ 2;
plot(s1, label="s1");
plot!(sdivide2, label="s1 ÷ 2");
savefig("sdivide2.svg") # hide
```
![](sdivide2.svg)

### `^` (exponentiation)

#### `signal1 ^ signal2`

```@repl ops
spow = s1 ^ s2;
plot(s1, label="s1");
plot!(s2, label="s2");
plot!(spow, label="s1 ^ s2");
savefig("spow.svg") # hide
```
![](spow.svg)

#### `signal ^ scalar` (or `scalar ^ signal`)

```@repl ops
spow2 = s1 ^ 2;
plot(s1, label="s1");
plot!(spow2, label="s1 ^ 2");
savefig("spow2.svg") # hide
```
![](spow2.svg)
