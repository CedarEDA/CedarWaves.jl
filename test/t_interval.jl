using CedarWaves, Test

@testset "Interval" begin
    @test 0 in Interval(0, 1)
    @test (10 in Interval(0, 1)) == false
    @test first(Interval(0, 1)) === 0
    @test last(Interval(0, 1)) === 1
    @test first(Interval(0.0, 1)) === 0.0
    @test last(Interval(0.0, 1)) === 1.0
    @test first(0 .. 1) === 0
    @test last(0 .. 1) === 1
    @test first(0.0 .. 1) === 0.0
    @test last(0.0 .. 1) === 1.0
    @test maximum(Interval(0, 10)) == 10
    @test minimum(Interval(0, 10)) == 0
    @test (0 .. 10) + 5 == 5 .. 15
    @test -(0 .. 10) == -10 .. -0
    @test +(0 .. 10) == 0 .. 10
    @test (0 .. 10) * 2 == 0 .. 20
    @test 2 * (0 .. 10) * 2 == 0 .. 40
    @test 2 + (0 .. 10) + 2 == 4 .. 14
    @test first(float(0 .. 10)) === 0.0
    @test last(float(0 .. 10)) === 10.0
    @test CedarWaves.span(-10 .. 10) == 20
    @test CedarWaves.descending(-10 .. 10) == false
    @test CedarWaves.descending(10 .. -10) == true
    @test CedarWaves.overlaps(0 .. 10, 5 .. 15) == true
    @test CedarWaves.overlaps(0 .. 10, 10 .. 15) == true
    @test CedarWaves.overlaps(0 .. 10, 11 .. 15) == false
    @test intersect(0 .. 100.0, -10 .. 20) == 0.0 .. 20.0
    @test intersect(0 .. 100.0, -10 .. 200) == 0.0 .. 100.0
    @test intersect(0 .. 100.0, 10 .. 200) == 10.0 .. 100.0
    @test intersect(0 .. 100.0, 10 .. 20) == 10.0 .. 20.0
    @test intersect(0 .. 10, 11 .. 20) == 0 .. 0
    @test union(0 .. 10, 11 .. 20) == 0 .. 20
    @test union(0 .. 12, 11 .. 20) == 0 .. 20
    @test union(0 .. 12, 0 .. 11) == 0 .. 12
    @test issubset(0 .. 10, 0 .. 10) == true
    @test issubset(0 .. 10, 0 .. 11) == true
    @test issubset(0 .. 10, 0 .. 9) == false
    @test issubset(0 .. 10, 1 .. 10) == false
    @test isempty(0 .. 10) == false
    @test isempty(0 .. 0) == true
    @test isempty(0.0 .. 0.0)

end