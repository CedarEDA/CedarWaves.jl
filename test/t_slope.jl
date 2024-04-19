using Test
using CedarWaves

@testset "slope" begin
    ys = [0,1,0,2,2]
    s1 = PWL(eachindex(ys), ys)
    @test clip(clip(s1, 2 .. 4), 3 .. 5)[end].x == 4
    for SigType in [PWL, PWC], clipit = [0, 1, 2]
        xs = 0:4
        ys = [0,1,0,2,2]
        if clipit == 0
            s1 = SigType(xs, ys)
            name = "$SigType($xs, $ys)"
            if SigType == PWL
                ans_key = [0 => 1, 0.5 => 1, 1 => 0, 1.5 => -1, 3 => 1, 3.5 => 0.0]
            elseif SigType == PWC
                ans_key = [0 => 0, 1 => Inf, 3.5 => 0, 4 => 0]
            end
        elseif clipit == 1
            s1 = clip(SigType(xs, ys), 1 .. 3)
            name = "clip($SigType($xs, $ys), 1 .. 3)"
            if SigType == PWL
                ans_key = [1 => -1]  # Hmm should this use the unclipped data to get the correct answer?
            elseif SigType == PWC
                ans_key = [1 => 0, 2 => -Inf, 2.1 => 0]
            end

        else
            s1 = clip(clip(SigType(xs, ys), 1 .. 3))
            @test xmax(s1) == 3
            name = "clip(clip($SigType($xs, $ys), 1 .. 3))"
            if SigType == PWL
                # FIXME?: should a clipped signal use the parent so the slope is the same at the ends as the unclipped signal?
                #ans_key = [0 => 1, 0.5 => 1, 1 => 0, 2 => 0.5, 3 => 1]
                ans_key = [0 => 1, 0.5 => 1, 1 => 0, 2 => 0.5, 3 => 2]
            elseif SigType == PWC
                ans_key = [0 => 0, 0.5 => 0, 1 => Inf, 2 => -Inf, 3 => Inf]
            end
        end
        @testset "$name" begin
            for (x, ans) in ans_key
                @test slope(s1, x) == ans
            end
        end
    end
end