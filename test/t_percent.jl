using CedarWaves
using Unitful: V, s, Hz, ustrip, k, ms, kHz, dBV, °, rad
using Test 

@test 1 == 100pct
@test 0.5 == 50pct
@test 0.667 == 66.7pct
@test pct(25) == 0.25

@test 10pct + 2pct == 12pct
@test 10pct + 2pct == 0.12
@test 10pct + 2 == 2.1
@test 10pct - 2pct == 8pct
@test 10pct - 2pct == 0.08
@test 10pct - 2 == -1.9
@test 10pct - 2 == -190pct
@test (5pct) / (10pct) == 50pct
@test 5pct / 10pct == 50pct
@test (100pct) ^ (0pct) == 100pct
@test (100pct) ^ (10pct) == 100pct
@test (2pct) ^ (200pct) == 0.04pct
@test 2^(400pct) == 1600pct
@test 2^(400pct) == 16
