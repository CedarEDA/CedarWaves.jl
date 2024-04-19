using Test, CedarWaves

@testset "flip" begin
    x = [2, 4, 5] # uneven samples
    y = [0, 1, 4]
    s = PWL(x, y)
    s2 = xflip(s)
    x_ans = [2, 3, 5]
    y_ans = reverse(y)
    @test xvals(s2) == x_ans
    @test yvals(s2) == y_ans
end