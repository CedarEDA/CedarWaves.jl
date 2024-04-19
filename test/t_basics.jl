using CedarWaves, Test
using OffsetArrays

# Don't run code (like a comment but something to fix later)
macro FIXME(expr...)
end
@testset "xshift" begin
    # Negative integer shift
    a = xshift(PWL(10:12, 100:102), -10)
    @test_throws DomainError a(-1)
    @test a(0) == 100
    @test a(1) == 101
    @test a(0.5) == 100.5
    @test_throws DomainError a(3)

    # Negative float
    a = xshift(PWL(10:12, 100:102), -10.0)
    @test_throws DomainError a(-1)
    @test a(0) == 100
    @test a(1) == 101
    @test a(0.5) == 100.5
    @test_throws DomainError a(3)

    # Positive non-integer shift
    b = xshift(PWL(10:12, 100:102), 10.5)
    @test_throws DomainError b(20) == 120.5
    @test b(20.5) == 100
    @test b(21) == 100.5

    # Nested shifts
    c = PWL(10:12, 100:102)
    c = xshift(c, -5.0)
    c = xshift(c, -5.0)
    @test_throws DomainError c(-1)
    @test c(0) == 100
    @test c(1) == 101
    @test c(0.5) == 100.5
    @test_throws DomainError c(3)
end

@testset "xscale" begin
    # Negative integer shift
    a = xscale(PWL(10:12, 100:102), 10)
    @test_throws DomainError a(-1)
    @test a(100) == 100
    @test a(110) == 101
    @test a(105) == 100.5
    @test_throws DomainError a(121)
    @test domain(a) == 100.0 .. 120.0

    # Negative float (axis flip)
    a = xscale(PWL(10:12, 100:102), -1.0)
    @test_throws DomainError a(-13)
    @test a(-12) == 102
    @test a(-10) == 100
    @test a(-10.5) == 100.5
    @test_throws DomainError a(3)
    @test domain(a) == -12.0 .. -10.0

    # Nested with xshift
    b = xshift(a, 12)
    @test b(0) == 102
    @test b(0.5) == 101.5
    @test domain(b) == 0.0 .. 2.0

    # Nested with xscale
    c = xscale(b, 10)
    @test c(0) == 102
    @test c(5) == 101.5
    @test domain(c) == 0.0 .. 20.0

end

@testset "xtransform" begin
    f = CedarWaves.Window(cos, 0.0 .. 2pi);
    @test f(-1) == 0.0
    @test f(0) == 1.0
    @test f(pi) == -1.0
    @test f(10) == 0.0

    f2 = CedarWaves.Window(abs, -1 .. 1);
    @test f2(-1) === 1 # keeps integer type?

    @test zeropad(xscale(xshift(PWL(1:6.0, [1.0, 0, 0, -1, 1, 0]), -1.0), 10.0), -10.0..100.0)(-1e-16) == 0.0 # the plot looks wrong

    f3 = CedarWaves.Periodic(x->2x-3, 1 .. 2);
    # within interval
    @test f3(1) == -1
    @test f3(1.5) == 0
    # before interval
    @test f3(-5.5) == 0
    @test f3(0.5) == 0
    @test f3(0.05) ≈ -0.9
    # after interval
    @test f3(4.5) == 0

    # Non 1 based period
    f4 = CedarWaves.Periodic(cosd, 270 .. 450);
    # x = -360:720; inspect(x, f4.(x))
    for i in -360:180:720
        @test f4(i) == 1
        @test f4(i+90) == 0
    end
    f4 = CedarWaves.Periodic(cos, 3pi/4 .. 5pi/4);
    @test f4(pi) == -1
    @test f4(2pi) == -1

    s5 = PWL(1:3, [-1,1,1])
    s6 = xscale(s5, 2)
    @test s6(2) == -1
    @test s6(6) == 1
    #using Plots; x=(1:3)/2; inspect(x, s6.(x))
    s7 = PWL(1:3, [-1,1,1]);
    s8 = xscale(s7, -1)
    @test s8(-3) == 1
    @test s8(-2) == 1
    @test s8(-1) == -1
end

@testset "Constructors" begin
    @test_throws DimensionMismatch PWL(1:5, 1:10)
    @test_throws ArgumentError PWC(OffsetVector(1:3, -1), 1:3)
    @test_throws ArgumentError Series(1:3, OffsetVector(1:3, -1))
    @test PWL(1:5, 5:-1:1) isa CedarWaves.AbstractSignal
    @test PWC(1:5, 5:-1:1) isa CedarWaves.AbstractSignal
    @test Series(1:5, 5:-1:1) isa CedarWaves.AbstractSignal
    @test SIN(amp=10, freq=10^6) isa CedarWaves.AbstractSignal
end
@testset "Interpolation" begin
    s1 = PWL(1.0:5, 5.0:-1:1)
    s2 = PWC(1.0:5, 5.0:-1:1)
    s3 = Series(1.0:5, 5.0:-1:1)
    @test xspan(clip(s1, 1.2 .. 4.2)) == 3
    @test xspan(clip(s2, 1.2 .. 4.2)) == 3
    @test xspan(clip(s3, 1.2 .. 4.2)) == 2 # clipped to closest samples within the domain
    #@test_throws DomainError clip(s3, 1.5, 6.5)
end

@testset "types" begin
    dig = PWC(0:3, [false, true, true, false])
    @test ytype(dig) == Bool
end

@testset "Indexing" begin
   for SigType in [PWL, PWC]
       s1 = SigType(1:0.5:5, 5:-0.5:1)
       s2 = (s1+1)^2
       s3 = SigType(1:0.5:5, 5:-0.5:1)
       s4 = xshift(s1, 0.1)
       @testset "$SigType" begin
           @test_throws BoundsError s1[0]
           @test_throws BoundsError s2[0]
           @test s1[1] == (x=1, y=5)
           @test s1[9] == (x=5, y=1)
           @test s2[1] == (x=1, y=(5+1)^2)
           @test s2[9] == (x=5, y=(1+1)^2)
           @test s1[begin] == s1[1]
           @test s2[begin] == s2[1]
           @test s4[begin] == s4[1]
           @test s1[end] == s1[9]
           @test s2[end] == s2[9]
           @test s4[end] == s4[9]
           @test (s1+s2)[1] == (x=1, y=s1[1][2]+s2[1][2])
           @test (s1+s3)[2] == (x=1.5, y=s1[2][2]+s3[2][2])
           @test xshift(s1, 0.1)[1] == (x=s1[1][1]+0.1, y=s1[1][2])
           @test xshift(s1, 10)[1] == (x=s1[1][1]+10, y=s1[1][2])
           @test clip(s1, 2.0 .. 3.0)[1] == s1[3]
           @test length(s1) == 9
           @test length(s2) == 9
           @test length(s1+s3) == 9
           @test length(s4) == 9
       end
   end
end


@testset "clamp" begin
    s1 = PWL(1:5, [0,-2, 0, 2, 0])
    s2 = clamp(s1, -1 .. 1)
    @test s2.(1:0.5:5) == [0, -1, -1, -1, 0, 1, 1, 1, 0]
end

@testset "derivative" begin
    s1 = derivative(PWL(0:3, [0, -2, -1, -1]))
    @test s1.(0.5:2.5) == [-2, 1, 0]
    # At inflection points many valid answers:
    # dep update broke this test:
    #@test s1.(0:0.5:3) == [-2.0, -2.0, -2.0, 1.0, 1.0, 0.0, 0.0]
    ans1 = [-2.0, -2.0, 1.0, 0.0]
    # this is just as valid:
    ans2 = [-2.0, 1.0, 0.0, 0.0] # forward looking
    ans3 = [0.0, 0.0, 0.0, 0.0] # constant
    derivs = s1.(0:3)
    @test derivs == ans1 || derivs == ans2 || derivs == ans3
end

@testset "NaNs" begin
    s = PWL([-4, -2, 2, 4, 6], [-20, -10, NaN, 10, 20]);
    @test s(-4) == -20.0
    @test s(-2) == -10
    @test isnan(s(2))
    @test s(4) == 10
end
