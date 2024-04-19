using TimerOutputs

const to = TimerOutput()

for exp in [6, 7, 8]
    @timeit to "10^$exp points" begin
        for fact in Int64[1, 10^exp/100]
            @timeit to "factor $fact" begin
                println("Run of 10^$exp points with frequency factor $fact")
                @timeit to "Julia" run(`julia --project jlplain.jl $exp $fact`)
                @timeit to "Julia tturbo" run(`julia --project --threads=auto jlopt.jl $exp $fact`)
                @timeit to "CedarWaves" run(`julia --project jlcedar.jl $exp $fact`)
                @timeit to "Julia Sysimg" run(`julia --project --sysimage=full_sysimage.so jlplain.jl $exp $fact`)
                @timeit to "Julia tturbo Sysimg" run(`julia --project --sysimage=full_sysimage.so --threads=auto jlopt.jl $exp $fact`)
                @timeit to "CedarWaves sysimg" run(`julia --project --sysimage=full_sysimage.so jlcedar.jl $exp $fact`)
                if exp < 8
                    @timeit to "Python" run(`cpyenv/bin/python pyplain.py $exp $fact`)
                end
                @timeit to "Numpy" run(`cpyenv/bin/python pynumpy.py $exp $fact`)
                @timeit to "Numba" run(`cpyenv/bin/python pynumba.py $exp $fact`)
                @timeit to "Pypy" run(`pypyenv/bin/python pyplain.py $exp $fact`)
                @timeit to "Pypy numpy" run(`pypyenv/bin/python pynumpy.py $exp $fact`)
            end
        end
    end
end

show(to, allocations = false)