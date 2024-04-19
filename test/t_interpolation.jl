using CedarWaves
using Unitful: V, s, Hz, ustrip, k, ms, kHz, dBV, °, rad
using Test

@testset "Interpolation" begin
    for SigType in [PWL, PWC], clipit = [0, 1, 2]
        xs = 1:5
        ys = 5:-1:1
        if SigType == PWL
            ans_key = [2.5 => 3.5, 2.0 => 4]
        elseif SigType == PWC
            ans_key = [1 => 5, 1.1 => 5, 2 => 4, 2.0 => 4, 2.5 => 4, 1.0 => 5]
        end
        if clipit == 0
            s1 = SigType(xs, ys)
            name = "$SigType($xs, $ys)"
        elseif clipit == 1
            s1 = clip(SigType(xs, ys), 1 .. 5)
            name = "clip($SigType($xs, $ys), 1 .. 5)"
        else
            s1 = clip(clip(SigType(xs, ys), 2, 4), 1 .. 5)
            name = "clip(clip($SigType($xs, $ys), 2 .. 4), 1 .. 5)"
        end
        @testset "$name" begin
            for (x, y) in ans_key
                @test s1(x) == y
            end
            @test_throws DomainError s1(minimum(xs) - 1)
            @test_throws DomainError s1(maximum(xs) + 1)
        end
    end
    @testset "PWC" begin
        xs = 1:5
        ys = 5:-1:1
        s1 = PWC(xs, ys)
        @test s1(2.5) == 4
        @test s1(2.0) == 4
        for (x, y) in zip(xs, ys)
            @test s1(x) == y
        end
        for (x1, x2) in zip(xs, collect(s1.x))
            @test x1 == x2
        end
        for (y1, y2) in zip(ys, collect(s1.y))
            @test y1 == y2
        end
        @test_throws DomainError s1(minimum(xs) - 1)
        @test_throws DomainError s1(maximum(xs) + 1)
    end
    @testset "Series" begin
        xs = 1:5
        ys = 5:-1:1
        s1 = Series(xs, ys)
        for (x, y) in zip(xs, ys)
            @test s1(x) == y
        end
        for (x1, x2) in zip(xs, collect(s1.x))
            @test x1 == x2
        end
        for (y1, y2) in zip(ys, collect(s1.y))
            @test y1 == y2
        end
        @test_throws DomainError s1(minimum(xs) - 1)
        @test_throws ErrorException s1(2.5)
        @test_throws DomainError s1(maximum(xs) + 1)
    end
end

@testset "zeropad" begin
    s1 = PWL(0:4, [1,1,0.5,1,1])
    s2 = ZeroPad(s1, 1 .. 3)
end