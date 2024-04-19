using Test
using CedarWaves

@testset "clip_exact" begin
    @testset "two unit ranges" begin
        sr1 = PWL(1:5, 11:15)
        @test UniformlySampledStyle(sr1) == IsUniformlySampled()
        sr2 = clip(sr1, 2 .. 4)
        @test UniformlySampledStyle(sr2) == IsUniformlySampled()   # main point of clip exact
        # length shrunk:
        @test length(sr2) == 3
        @test length(sr2.x) == 3
        @test length(sr2.y) == 3
        # Indicies should remain unchanged
        #@test sr2[1].x == 2
        #@test sr2.x[2] == 2
        #@test sr2[2].y == 12
        #@test sr2.y[2] == 12
        #@test sr2.x == 2:4
        #@test sr2.y == 12:14
        @test collect(sr2.y) == collect(12:14)
    end
    @testset "two unit ranges x=0:4" begin
        sr1 = PWL(0:4, 11:15)
        @test UniformlySampledStyle(sr1) == IsUniformlySampled()
        sr2 = clip(sr1, 1 .. 3)
        @test UniformlySampledStyle(sr2) == IsUniformlySampled()   # main point of clip exact
        # length shrunk:
        @test length(sr2) == 3
        @test length(sr2.x) == 3
        @test length(sr2.y) == 3
        # Indicies should remain unchanged
        #@test firstindex(sr2) == 2
        #@test sr2[2].x == 1
        #@test sr2.x[2] == 1
        #@test sr2[2].y == 12
        #@test sr2.y[2] == 12
        #@test sr2.x == 1:3
        #@test sr2.y == 12:14
        @test collect(sr2.y) == collect(12:14)
    end

    @testset "x as non-unit range" begin
        # non-unit range:
        s0 = PWL(collect(0.1:0.1:0.5), 5:-1:1)
        s1 = sample(s0, 0.1:0.1:0.5)
        @test UniformlySampledStyle(s1) == IsUniformlySampled()
        s2 = clip(s1, 0.2 .. 0.4)
        @test UniformlySampledStyle(s2) == IsUniformlySampled()   # main point of clip exact
        # length shrunk:
        @test length(s2) == 3
        @test length(s2.x) == 3
        @test length(s2.y) == 3
        # Indicies should remain unchanged
        #@test s2[2].x == 2
        #@test s2.x[2] == 2
        #@test s2[2].y == 4
        #@test s2.y[2] == 4
        #@test s2.x == 2:4
        #@test collect(s2.y) == collect(4:-1:2)
    end
    @testset "y as regular vector" begin
    # regular vector
        t1 = PWL(1:5, collect(5:-1:1))
        @test UniformlySampledStyle(t1) == IsUniformlySampled()
        t2 = clip(t1, 2 .. 4)
        @test UniformlySampledStyle(t2) == IsUniformlySampled()   # main point of clip exact
        # length shrunk:
        @test length(t2) == 3
        @test length(t2.x) == 3
        @test length(t2.y) == 3
        ## Indicies should remain unchanged
        #@test t2[2].x == 2
        #@test t2.x[2] == 2
        #@test t2[2].y == 4
        #@test t2.y[2] == 4
        #
        @test t2.x == 2:4
        @test collect(t2.y) == collect(4:-1:2)
    end
    @testset "both as regular vector" begin
    # regular vector
        r1 = PWL(collect(1:5), collect(5:-1:1))
        @test UniformlySampledStyle(r1) == IsUniformlySampled()
        r2 = clip(r1, 2 .. 4)
        @test UniformlySampledStyle(r2) == IsUniformlySampled()
        # length shrunk:
        @test length(r2) == 3
        @test length(r2.x) == 3
        @test length(r2.y) == 3
        @test r2[1].x == 2
        @test r2.x[1] == 2
        @test r2[1].y == 4
        @test r2.y[1] == 4
        #
        @test collect(r2.y) == collect(4:-1:2)
    end
    @testset "clip(clip(sig))" begin
        sr1 = PWL(1:5, 11:15)
        sr2 = clip(sr1, 2 .. 4)
        sr3 = clip(sr2, 1 .. 5)
    end
end