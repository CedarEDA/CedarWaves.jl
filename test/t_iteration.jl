using CedarWaves, Test

function test_iterate(s, x_ans, y_ans)
    x = collect(eachx(s))
    y = collect(eachy(s))
    @test length(x) == length(x_ans)
    @test length(y) == length(y_ans)
    @test x == x_ans
    @test y == y_ans
end


@testset "iteration" begin
    # Basic iteration:
    x1 = 0.0:3.0
    y1 = Float64[0, 1, -1, 0]
    s1 = PWL(x1, y1)
    test_iterate(s1, x1, y1)
    s1c = clip(s1, 1 .. 2) # exact clip
    test_iterate(s1c, x1[2:3], y1[2:3])
    s1ci = clip(s1, 0.5 .. 2.5) # interpolated clip
    test_iterate(s1ci, [0.5, 1, 2, 2.5], [0.5, 1, -1, -0.5])


    # Xshift:
    s2 = xshift(s1, 100)
    x2 = x1 .+ 100
    y2 = y1
    test_iterate(s2, x2, y2)
    s2c = clip(s2, 101 .. 102) # exact clip
    s2cx = 101:102
    s2cy = s2.(s2cx)
    test_iterate(s2c, s2cx, s2cy)
    s2ci = clip(s2, 100.5 .. 102.5) # interpolated clip
    s2cix = [100.5, 101, 102, 102.5]
    s2ciy = s2.(s2cix)
    test_iterate(s2ci, s2cix, s2ciy)

    # xscale:
    s3 = xscale(s2, 2)
    x3 = x2 .* 2
    y3 = y2
    test_iterate(s3, x3, y3)
    s3c = clip(s3, 202 .. 204) # exact clip
    s3cx = 202:2:204
    s3cy = s3.(s3cx)
    test_iterate(s3c, s3cx, s3cy)
    s3ci = clip(s3, 201 .. 205) # interpolated clip
    s3cix = [201, 202, 204, 205]
    s3ciy = s3.(s3cix)
    test_iterate(s3ci, s3cix, s3ciy)

    s1 = PWL(3:6, [0, 10, -10, -10])
    s3d = xscale(s1, -1)
    @test domain(s3d) == (-6.0 .. -3.0)
    @test s3d.((-6:-3)) == [-10, -10, 10, 0]

    s1 = PWL(3:6, [0, 10, -10, -10])
    s3e = xscale(s1, -20000)
    @test domain(s3e) == 20000 * (-6.0 .. -3.0)
    @test s3e.(20000*(-6:-3)) == [-10, -10, 10, 0]

    s = PWL(1:2, [0, 1])
    s2 = xflip(s)
    @test domain(s2) == 1..2
    @test s2.(1:2) == [1.0, 0.0]


    # transform back to x1:
    # Note: this (in general) could have floating point errors so we should use ≈ for equality
    s1tr = xshift(xscale(s3, 1/2), -100)
    x1tr = x1
    y1tr = y1
    test_iterate(s1tr, x1tr, y1tr)
    s1trc = clip(s1tr, 1 .. 2) # exact clip
    test_iterate(s1trc, x1tr[2:3], y1tr[2:3])
    s1trci = clip(s1tr, 0.5 .. 2.5) # interpolated clip
    test_iterate(s1trci, [0.5, 1, 2, 2.5], [0.5, 1, -1, -0.5])

    # Negative scale (flip about y-axis)
    s4b = xscale(s3, -1)
    x4b = -maximum(x3):step(x3):-minimum(x3)
    y4b = y3
    s4c = clip(s4b, -204.. -202) # exact clip
    s4cx = [-204, -202]
    s4cy = s4b.(s4cx)
    test_iterate(s4c, s4cx, s4cy)
    s4ci = clip(s4b, -205 .. -201) # interpolated clip
    s4cix = [-205, -204, -202, -201]
    s4ciy = s4b.(s4cix)
    test_iterate(s4ci, s4cix, s4ciy)
    s4b2 = s4b+s4b # merge decreasing
    test_iterate(s4b2, x4b, 2 .* reverse(y4b))

    # ymap operator:
    s5 = ymap_signal(y->2y, s3)
    x5 = x3
    y5 = 2 .* y3
    test_iterate(s5, x5, y5)
    s5c = clip(s5, 202 .. 204) # exact clip
    test_iterate(s5c, x5[2:3], y5[2:3])
    s5ci = clip(s5, 201 .. 205) # interpolated clip
    test_iterate(s5ci, 2 .* (100 .+ [0.5, 1, 2, 2.5]), 2 .* [0.5, 1, -1, -0.5])

    # Binary operator with same domain:
    s6 = s3 + s3
    x6 = x3
    y6 = y3 .+ y3
    test_iterate(s6, x6, y6)
    s6c = clip(s6, 202 .. 204) # exact clip
    test_iterate(s6c, x6[2:3], y6[2:3])
    s6ci = clip(s6, 201 .. 205) # interpolated clip
    test_iterate(s6ci, 2 .* (100 .+ [0.5, 1, 2, 2.5]), 2 .* [0.5, 1, -1, -0.5])

    # Binary operator with same domain (but different x_transforms)
    #= not sure why this would ever work if x-axis are different (after transform):
    x7 = x1
    y7 = [-30.0, -19, -11, 0]
    s7 = sample(s1, xvals(s1tr)) + s1tr
    test_iterate(s7, x7, y7)
    s7c = clip(s7, 1 .. 2) # exact clip
    s7cx = [1, 2]
    s7cy = s7.(s7cx)
    test_iterate(s7c, s7cx, s7cy)
    s7ci = clip(s7, 0.5 .. 2.5) # interpolated clip
    s7cix = [0.5, 1, 2, 2.5]
    s7ciy = s7.(s7cix)
    test_iterate(s7ci, s7cix, s7ciy)
    =#

    # Binary operator with same domain (but different x points)
    s7b = PWL(1.0:5.0, 1.0:5.0)
    s7c = PWL(1:0.5:5, 1:0.5:5)
    s7bc = CedarWaves.combine((+), s7b, s7c)
    test_iterate(s7bc, 1:0.5:5, 2 .* (1:0.5:5))

    # Binary operator with partially overlapping domains
    x8 = 0.0:3.0
    y8 = Float64[1, 2, -3, -4]
    s8 = PWL(x8, y8)
    s9 = xshift(s8, 1)
    x9 = x8 .+ 1
    y9 = y8
    s10 = CedarWaves.combine((+), s8, s9)  # should this warn?
    x10 = intersect(x8, x9)
    y10 = [s8(x) + s9(x) for x in x10]
    test_iterate(s10, x10, y10)
    s10c = clip(s10, 1 .. 2) # exact clip
    x10c = [1, 2]
    y10c = s10.(x10c)
    test_iterate(s10c, x10c, y10c)
    s10ci = clip(s10, 1.5 .. 2.5) # interpolated clip
    s10cix = [1.5, 2, 2.5]
    s10ciy = s10.(s10cix)
    test_iterate(s10ci, s10cix, s10ciy)

    # Binary operator with partially overlapping domains (interpolated)
    x8 = 0:3
    y8 = [1, -1, 1, 0]
    s8 = PWL(x8, y8)
    s9 = xshift(s8, 1.5)
    x9 = x8 .+ 1.5
    s10 = CedarWaves.combine((+), s8, s9)  # should this warn?
    x10 = 1.5:0.5:3
    y10 = [s8(x)+s9(x) for x in x10]
    test_iterate(s10, x10, y10)
    s10c = clip(s10, 2.0 .. 2.5) # exact and partial interp clip
    x10c = [2, 2.5]
    y10c = [s8(x)+s9(x) for x in x10c]
    test_iterate(s10c, x10c, y10c)
    s10ci = clip(s10, 1.75 .. 2.75) # interpolated clip
    x10ci = [1.75, 2, 2.5, 2.75]
    y10ci = [s8(x)+s9(x) for x in x10ci]
    test_iterate(s10ci, x10ci, y10ci)

    # Binary operator with non overlapping domains
    s11 = PWL(0:3, 1:4)
    s12 = xshift(s11, 10)
    @test_throws DomainError CedarWaves.combine((+), s11, s12)

    # mixing different signal types
    s18 = PWL(1.0:5.0, 1.0:5.0)
    s19 = Series(1.0:5.0, 1.0:5.0)
    s1819 = s18 + s19
    @test isdiscrete(s1819)
    test_iterate(s1819, 1:5, 2:2:10)

    # test nested x shift/scale/clipping
    s21 = PWL(1:5, 1:5)
    #       10 .. 26 8 .. 24  4 .. 12  2 .. 10
    s21ns = xshift(xscale(xshift(xscale(s21, 2), 2), 2), 2)
    s21c = clip(s21ns, 14 .. 22)
    @test domain(s21ns) == 10 .. 26
    test_iterate(s21ns, 10:4:26, 1:5)
    @test domain(s21c) == 14 .. 22
    test_iterate(s21c, 14:4:22, 2:4)

    # test sampling continuous functions
    @test yvals(s18) == 1:5
    @test yvals(sample(s18, step=0.5)) == 1:0.5:5
    @test yvals(s19) == 1:5
end

#   # Clips:
#   # Exact clips (no interpolation needed)
#   c1 = clip(s1)
#
#
#   # TODO: test negative scales
#
#   s2 = clip(s, 1 .. 2)
#   @test_throws DomainError s2(0)
#   @test s2(1) == 1
#   @test s2(1.5) == 0
#   @test s2(2) == 1
#   @test_throws DomainError s2(3)
#
#
#
#
#end