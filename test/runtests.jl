using Test
using TimerOutputs

function include(str)
    m = Module()
    ex = quote
        using TimerOutputs
        using Test
        import ..@testset
        Base.include(@__MODULE__, $str)
    end
    Base.eval(m, ex)
end

macro testset(str, block)
    return quote
        @timeit "$($(esc(str)))" begin
            Test.@testset "$($(esc(str)))" begin
                $(esc(block))
            end
        end
    end
end

reset_timer!()

@testset "ScalingFactors" begin
    include("t_scalingfactors.jl")
end

@testset "Signals" begin

@testset "thresholds" begin
    include("t_thresholds.jl")
end
@testset "basics" begin
    include("t_basics.jl")
end

@testset "interval" begin
    include("t_interval.jl")
end

@testset "iteration" begin
    include("t_iteration.jl")
end

@testset "operators" begin
    include("t_operators.jl")
end

@testset "pointfinder" begin
    include("t_pointfinder.jl")
end

@testset "cross" begin
    include("t_cross.jl")
end

@testset "stats" begin
    include("t_stats.jl")
end

@testset "measures" begin
    include("t_measure.jl")
end

#@testset "memoization" begin
#    include("t_memoization.jl")
#end

@testset "filter" begin
    include("t_filter.jl")
end

#@testset "online" begin
#    include("t_online.jl")
#end

@testset "bitpattern" begin
    include("t_bitpattern.jl")
end


# include("t_doctests.jl")
#    @testset "clip_exact" begin
#        include("t_clip_exact.jl")
#    end
#    @testset "interpolation" begin
#        include("t_interpolation.jl")
#    end

#    @testset "slope" begin
#        include("t_slope.jl")
#    end
#    @testset "slew" begin
#        include("t_slew.jl")
#    end
#    @testset "round" begin
#        include("t_round.jl")
#    end
    @testset "phase" begin
        include("t_phase.jl")
    end
#    @testset "percent" begin
#        include("t_percent.jl")
#    end
#    @testset "dft" begin
#        include("t_dft.jl")
#    end
    @testset "fourier" begin
        include("t_fourier.jl")
    end
#    @testset "mapped_sig" begin
#        include("t_mapped_sig.jl")
#    end
#    @testset "mapped_vec" begin
#        include("t_mapped_vec.jl")
#    end
#    @testset "rms" begin
#        include("t_rms.jl")
#    end
    @testset "signals with odd types" begin
        include("t_signal_odd_types.jl")
    end
    @testset "glitches" begin
        include("t_glitch.jl")
    end
    @testset "transitions" begin
        include("t_transitions.jl")
    end
    @testset "plotting" begin
        include("t_plotting.jl")
    end
end

print_timer()
println()
