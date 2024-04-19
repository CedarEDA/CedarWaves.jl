using CedarWaves
using Test

#SimEnv = CedarWaves
#
#s1 = PWL(0.0:3, [0.0, 10, 0, 20])
#SimEnv._resolve_thresh(s1, either(0.5))
#@test SimEnv.resolve_thresh(s1, either(0.5)) == either(0.5)
#@test SimEnv.resolve_thresh(s1, rising(0.5)) == rising(0.5)
#@test SimEnv.resolve_thresh(s1, falling(0.5)) == falling(0.5)
#@test SimEnv.resolve_thresh(s1, 0.5) == either(0.5)
#@test SimEnv.resolve_thresh(s1, 50pct) == either(10.0)
#@test SimEnv.resolve_thresh(s1, falling(50pct)) == falling(10.0)
#@test SimEnv.resolve_thresh(s1, rising(50pct)) == rising(10.0)
#@test SimEnv.resolve_thresh(s1, either(50pct)) == either(10.0)

@testset "thresholds" begin
#    @test either(0.8)/2 == either(0.4)
#    @test 2*falling(0.8) == 1.6
#    @test falling(0.2) + rising(0.2) == 0.4
#    @test falling(0.2) > 0.1
#    @test rising(0.1) <= 0.2
#    @test falling(0.1) <= 0.2
#    @test either(0.1) <= 0.2
#    @test rising(0.1) < falling(0.2)
#    @test rising(0.1) < either(0.2)
#    @test falling(0.1) < either(0.2)
#    @test 0.2 >= rising(0.1)
#    @test 0.2 >= falling(0.1)
#    @test 0.2 >= either(0.1)
end