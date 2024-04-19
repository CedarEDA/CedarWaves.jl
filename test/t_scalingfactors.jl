using CedarWaves.SIFactors: Y, Z, E, P, T, G, M, K, k, m, u, μ, n, p, f, a, z, y, snapnearest
using Test


@test 1Y == 1e24
@test 1Z == 1e21
@test 1E == 1e18
@test 1P == 1e15
@test 1T == 1e12
@test 1G == 1e9
@test 1M == 1e6
@test 1K == 1e3
@test 1k == 1e3
@test 1m == 1e-3
@test 1u == 1e-6
@test 1μ == 1e-6
@test 1n == 1e-9
@test 1p == 1e-12
@test 1f == 1e-15
@test 1a == 1e-18
@test 1z == 1e-21
@test 1y == 1e-24

@test 5.5Y == 5.5e24
@test 5.5Z == 5.5e21
@test 5.5E == 5.5e18
@test 5.5P == 5.5e15
@test 5.5T == 5.5e12
@test 5.5G == 5.5e9
@test 5.5M == 5.5e6
@test 5.5K == 5.5e3
@test 5.5k == 5.5e3
@test 5.5m == 5.5e-3
@test 5.5u == 5.5e-6
@test 5.5μ == 5.5e-6
@test 5.5n == 5.5e-9
@test 5.5p == 5.5e-12
@test 5.5f == 5.5e-15
@test 5.5a == 5.5e-18
@test 5.5z == 5.5e-21
@test 5.5y == 5.5e-24

@test 9.9Y == 9.9e24
@test 9.9Z == 9.9e21
@test 9.9E == 9.9e18
@test 9.9P == 9.9e15
@test 9.9T == 9.9e12
@test 9.9G == 9.9e9
@test 9.9M == 9.9e6
@test 9.9K == 9.9e3
@test 9.9k == 9.9e3
@test 9.9m == 9.9e-3
@test 9.9u == 9.9e-6
@test 9.9μ == 9.9e-6
@test 9.9n == 9.9e-9
@test 9.9p == 9.9e-12
@test 9.9f == 9.9e-15
@test 9.9a == 9.9e-18
@test 9.9z == 9.9e-21
@test 9.9y == 9.9e-24

@test 0.001Y == 1e21
@test 0.001Z == 1e18
@test 0.001E == 1e15
@test 0.001P == 1e12
@test 0.001T == 1e9
@test 0.001G == 1e6
@test 0.001M == 1e3
@test 0.001K == 1.0
@test 0.001k == 1.0
@test 0.001m == 1e-6
@test 0.001u == 1e-9
@test 0.001μ == 1e-9
@test 0.001n == 1e-12
@test 0.001p == 1e-15
@test 0.001f == 1e-18
@test 0.001a == 1e-21
@test 0.001z == 1e-24
@test 0.001y == 1e-27

@test snapnearest(1/(1k*1n)) == 1.0e6
@test snapnearest(prevfloat(1.0)) == 1.0
@test snapnearest(prevfloat(1.0e-6, 2)) == 9.999999999999995e-7
@test snapnearest(prevfloat(1.0e-6, 2), 2) == 1e-6
@test snapnearest(nextfloat(1.0e-6, 2)) == 1.0000000000000004e-6
@test snapnearest(nextfloat(1.0e-6, 2), 2) == 1e-6
@test snapnearest(1/9801, 1) == 0.0001020304050607081
@test snapnearest(1/9801, 2) == 0.0001020304050607081
@test snapnearest(1/9801, 3) == 0.0001020304050607081
@test snapnearest(1/9801, 4) == 0.0001020304050607081
@test snapnearest(1/9801, 5) == 0.0001020304050607081
@test snapnearest(1/9801, 6) == 0.0001020304050607081
@test snapnearest(1/9801, 7) == 0.000102030405060708
