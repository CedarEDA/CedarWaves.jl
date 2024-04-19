using BenchmarkTools
using CedarWaves
import Dates

const SUITE = BenchmarkGroup()

# to run faster for testing
BenchmarkTools.DEFAULT_PARAMETERS.seconds = 0.50

const N = 10_001
const x = range(0, 10, length=N)
const y = sin.(x)
const t = PWL(x, x)
const x2 = range(0, 10, length=N+1)
const y2 = sin.(x2)
const t2 = PWL(x2, x2)
const interps = [Series, PWL]
const continuous_interps = [PWL]

# Load time
SUITE["load"] = BenchmarkGroup()
SUITE["load"]["CedarWaves"] = @benchmarkable run(`$(Base.julia_cmd()) --project=$(Base.active_project()) -e 'using CedarWaves'`)


# Constructors
SUITE["new"] = BenchmarkGroup()
SUITE["new"]["Vec"] = @benchmarkable zeros($N)
SUITE["new"]["Series"] = @benchmarkable Series($x, $x)
SUITE["new"]["PWL"] = @benchmarkable PWL($x, $x)

# Function calls
# of each sample
c = "call"
nm = "sum(t)"
SUITE[c] = BenchmarkGroup()
SUITE[c][nm] = BenchmarkGroup([c])
SUITE[c][nm]["Vec"] = @benchmarkable sum(i for i in $x)
SUITE[c][nm]["Vec."] = @benchmarkable sum($x)
SUITE[c][nm]["PWL"] = @benchmarkable sum(s(i) for i in $x) setup=(s=PWL(x, x))
SUITE[c][nm]["PWL."] = @benchmarkable sum(s.($x)) setup=(s=PWL(x, x))
nm = "sum(sin(t))"
SUITE[c] = BenchmarkGroup()
SUITE[c][nm] = BenchmarkGroup([c])
SUITE[c][nm]["Vec"] = @benchmarkable sum(sin(i) for i in $x)
SUITE[c][nm]["Vec."] = @benchmarkable sum(sin.($x))
SUITE[c][nm]["PWL"] = @benchmarkable sum((s(i) for i in $x)) setup=(s=sin(PWL(x, x)))
SUITE[c][nm]["PWL."] = @benchmarkable sum(s.($x)) setup=(s = sin(PWL(x, x)))
nm = "sum(sin(t)/2 + cos(t)^2 + 5)"
SUITE[c][nm] = BenchmarkGroup([c])
SUITE[c][nm]["Vec"] = @benchmarkable sum(((sin(xi)/2 + cos(xi)^2 + 5) for xi in $x))
SUITE[c][nm]["Vec."] = @benchmarkable sum(@.(sin(x)/2 + cos(x)^2 + 5))
SUITE[c][nm]["PWL"] = @benchmarkable sum(s(i) for i in $x) setup=(s=sin(t)/2 + cos(t)^2 + 5)
SUITE[c][nm]["PWL."] = @benchmarkable sum(s.($x)) setup=(s=sin(t)/2 + cos(t)^2 + 5)

c = "FS"
SUITE[c] = BenchmarkGroup()
nm = "non-zero components"
nz = [0, 2, 3, 10]
function fs1()
    t3 = PWL(0 .. 10, 0 .. 10)
    sf = ymap_signal(t->0.5 + 2cospi(2*2t) + 3sinpi(2*3t) + 10sinpi(2*10t), t3)
    clip(FS(sf), 0 .. 200)
end
SUITE[c][nm] = BenchmarkGroup([c])
SUITE[c][nm]["fs(0)"] = @benchmarkable fs(0) setup=(fs = fs1())
SUITE[c][nm]["fs(2)"] = @benchmarkable fs(2) setup=(fs = fs1())
SUITE[c][nm]["fs(3)"] = @benchmarkable fs(3) setup=(fs = fs1())
SUITE[c][nm]["fs(10)"] = @benchmarkable fs(10) setup=(fs = fs1())

# These are slow because QuadGK doesn't like integrating around zero:
nm = "zero components"
SUITE[c][nm] = BenchmarkGroup([c])
SUITE[c][nm]["fs(1)"] = @benchmarkable fs(1) setup=(fs = fs1())
SUITE[c][nm]["fs(4)"] = @benchmarkable fs(4) setup=(fs = fs1())
SUITE[c][nm]["fs(5)"] = @benchmarkable fs(5) setup=(fs = fs1())
SUITE[c][nm]["fs(6)"] = @benchmarkable fs(6) setup=(fs = fs1())
SUITE[c][nm]["fs(7)"] = @benchmarkable fs(7) setup=(fs = fs1())
SUITE[c][nm]["fs(8)"] = @benchmarkable fs(8) setup=(fs = fs1())
SUITE[c][nm]["fs(9)"] = @benchmarkable fs(9) setup=(fs = fs1())
SUITE[c][nm]["fs(11)"] = @benchmarkable fs(11) setup=(fs = fs1())
SUITE[c][nm]["fs(12)"] = @benchmarkable fs(12) setup=(fs = fs1())
SUITE[c][nm]["fs(13)"] = @benchmarkable fs(13) setup=(fs = fs1())
SUITE[c][nm]["fs(190)"] = @benchmarkable fs(190) setup=(fs = fs1())
SUITE[c][nm]["fs(191)"] = @benchmarkable fs(191) setup=(fs = fs1())
SUITE[c][nm]["fs(192)"] = @benchmarkable fs(192) setup=(fs = fs1())
SUITE[c][nm]["fs(193)"] = @benchmarkable fs(193) setup=(fs = fs1())

# RMS
c = "funcs"
nm = "modulated"
SUITE[c] = BenchmarkGroup()
N3 = 125_000
t3 = range(0, 1, length = N3)
y3 = @.(sin(2pi*1000*t3)*cos(2pi*2*t3))
SUITE[c][nm] = BenchmarkGroup([c])
myrms(a_signal) = sqrt(integral(a_signal^2)/xspan(a_signal))
itr_x(s) = foreach(identity, eachx(s))
itr_y(s) = foreach(identity, eachy(s))
itr_xy(s) = foreach(identity, eachxy(s))
itr_cross(s) = foreach(identity, eachcross(s, 0.0))
itr_crossr(s) = foreach(identity, eachcross(s, rising(0.0)))
itr_crossf(s) = foreach(identity, eachcross(s, falling(0.0)))
c_eachy(s) = collect(eachy(s))
c_eachxy(s) = collect(eachxy(s))
itr_deriv(s) = (d =derivative(s); foreach(x->d(x), eachx(s)))
debug = false
begin
    debug && println("N = $N3:")
    for func in [itr_x, itr_y, itr_xy, c_eachy, c_eachxy, 
                 itr_cross, crosses, 
                 itr_deriv,
                 minimum, maximum, extrema, 
                 integral, sum, mean, myrms, rms, std,
                ]
    #for func in [extrema]
        for (name, modulated) in [("$func PWL", PWL(t3, y3)), ("$func Series", Series(t3, y3))]
            if name in ["myrms Series", "integral Series", "sum PWL"]
                continue
            end
            SUITE[c][nm][name] = @benchmarkable ($func)($modulated)
            if debug 
                print(rpad(string(name, ": "), 18))
                @time func(modulated)
            end
        end
    end
end

nothing


#nm = "sum eachy 2*sin(s1) + 4 + cos(s1)^2"
#SUITE[c][nm] = BenchmarkGroup([c])
#SUITE[c][nm]["Vec"] = @benchmarkable sum(2 .*sin.($x) .+ 4 .+ cos.($x).^2)
#SUITE[c][nm]["Vec."] = @benchmarkable sum(@.(2 .*sin.($x) .+ 4 .+ cos.($x).^2))
#SUITE[c][nm]["PWL"] = @benchmarkable sum(s(i) for i in $x) setup=(s=2*sin.(t) + 4 + cos(t)^2)
#SUITE[c][nm]["PWL."] = @benchmarkable sum(s.($x)) setup=(s=2*sin(t) + 4 + cos(t)^2)
#nm = "sum eachy sin"
#SUITE[c][nm] = BenchmarkGroup([c])
#SUITE[c][nm]["Vec"] = @benchmarkable sum(sin.($x))
#for interp in interps
#	SUITE["call"]["sum eachy sin"]["$interp"] = @benchmarkable sum(eachy(sin($interp($x,$x))))
#end
#SUITE["call"]["sum eachy 2*sin(s1) + 4 + cos(s1)^2"] = BenchmarkGroup(["call"])
#SUITE["call"]["sum eachy 2*sin(s1) + 4 + cos(s1)^2"]["Vec"] = @benchmarkable sum(2 .*sin.($x) .+ 4 .+ cos.($x).^2)
#for interp in continuous_interps
#	SUITE["call"]["sum eachy 2*sin(s1) + 4 + cos(s1)^2"]["$interp"] = @benchmarkable sum(eachy(2*sin($interp($x, $x)) + 4 + cos($interp($x, $x))^2))
#end
#
#SUITE["call"]["maximum eachy sin"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum eachy sin"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in interps
#	SUITE["call"]["maximum eachy sin"]["$interp"] = @benchmarkable maximum(eachy(sin($interp($x, $x))))
#end
#SUITE["call"]["maximum eachy xshift sin"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum eachy xshift sin"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in continuous_interps
#	SUITE["call"]["maximum eachy xshift sin"]["$interp"] = @benchmarkable maximum(eachy(sin(xshift($interp($x, $x), 10))))
#end
#SUITE["call"]["maximum eachy xscale sin"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum eachy xscale sin"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in continuous_interps
#	SUITE["call"]["maximum eachy xscale sin"]["$interp"] = @benchmarkable maximum(eachy(sin(xscale($interp($x, $x), 10))))
#end
#SUITE["call"]["maximum eachy clip sin"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum eachy clip sin"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in continuous_interps # shouldn't this work for discretes?
#	SUITE["call"]["maximum eachy clip sin"]["$interp"] = @benchmarkable maximum(eachy(sin(clip($interp($x, $x), 2..9))))
#end
#SUITE["call"]["maximum eachy sin(s1 + s1)"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum eachy sin(s1 + s1)"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in continuous_interps  # why doesn't this work for discretes?
#	SUITE["call"]["maximum eachy sin(s1 + s1)"]["$interp"] = @benchmarkable maximum(eachy(sin($interp($x, $x) + $interp($x, $x))))
#end
#SUITE["call"]["maximum eachy sin(s1 + s2)"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum eachy sin(s1 + s2)"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in continuous_interps
#	SUITE["call"]["maximum eachy sin(s1 + s2)"]["$interp"] = @benchmarkable maximum(eachy(sin($interp($x, $x) + $interp($x2, $x2))))
#end
#SUITE["call"]["maximum eachy sin(s1 + s2)"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum eachy sin(s1 + s2)"]["Vec"] = @benchmarkable maximum(sin.($x) .+ sin.($x))
#for interp in continuous_interps
#	SUITE["call"]["maximum eachy sin(s1 + s2)"]["$interp"] = @benchmarkable maximum(eachy(sin($interp($x, $x) + $interp($x2, $x2))))
#end
#SUITE["call"]["maximum eachy 2*sin(s1) + 4 + cos(s1)^2"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum eachy 2*sin(s1) + 4 + cos(s1)^2"]["Vec"] = @benchmarkable maximum(2 .*sin.($x) .+ 4 .+ cos.($x).^2)
#for interp in continuous_interps
#	SUITE["call"]["maximum eachy 2*sin(s1) + 4 + cos(s1)^2"]["$interp"] = @benchmarkable maximum(eachy(2*sin($interp($x, $x)) + 4 + cos($interp($x, $x))^2))
#end
#SUITE["call"]["maximum eachy 2*sin(s1) + 4 + cos(s2)^2"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum eachy 2*sin(s1) + 4 + cos(s2)^2"]["Vec"] = @benchmarkable maximum(2 .*sin.($x) .+ 4 .+ cos.($x).^2)
#for interp in continuous_interps
#	SUITE["call"]["maximum eachy 2*sin(s1) + 4 + cos(s2)^2"]["$interp"] = @benchmarkable maximum(eachy(2*sin($interp($x, $x)) + 4 + cos($interp($x2, $x2))^2))
#end
#
## maximum of continuous
#SUITE["call"]["maximum sin"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum sin"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in interps
#	SUITE["call"]["maximum sin"]["$interp"] = @benchmarkable maximum(sin($interp($x, $x)))
#end
#SUITE["call"]["maximum xshift sin"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum xshift sin"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in continuous_interps
#	SUITE["call"]["maximum xshift sin"]["$interp"] = @benchmarkable maximum(sin(xshift($interp($x, $x), 10)))
#end
#SUITE["call"]["maximum xscale sin"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum xscale sin"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in continuous_interps
#	SUITE["call"]["maximum xscale sin"]["$interp"] = @benchmarkable maximum(sin(xscale($interp($x, $x), 10)))
#end
#SUITE["call"]["maximum clip sin"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum clip sin"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in continuous_interps # shouldn't this work for discretes?
#	SUITE["call"]["maximum clip sin"]["$interp"] = @benchmarkable maximum(sin(clip($interp($x, $x), 2..9)))
#end
#SUITE["call"]["maximum sin(s1 + s1)"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum sin(s1 + s1)"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in continuous_interps  # why doesn't this work for discretes?
#	SUITE["call"]["maximum sin(s1 + s1)"]["$interp"] = @benchmarkable maximum(sin($interp($x, $x) + $interp($x, $x)))
#end
#SUITE["call"]["maximum sin(s1 + s2)"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum sin(s1 + s2)"]["Vec"] = @benchmarkable maximum(sin.($x))
#for interp in continuous_interps
#	SUITE["call"]["maximum sin(s1 + s2)"]["$interp"] = @benchmarkable maximum(sin($interp($x, $x) + $interp($x2, $x2)))
#end
#SUITE["call"]["maximum sin(s1 + s2)"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum sin(s1 + s2)"]["Vec"] = @benchmarkable maximum(sin.($x) .+ sin.($x))
#for interp in continuous_interps
#	SUITE["call"]["maximum sin(s1 + s2)"]["$interp"] = @benchmarkable maximum(sin($interp($x, $x) + $interp($x2, $x2)))
#end
#SUITE["call"]["maximum 2*sin(s1) + 4 + cos(s2)^2"] = BenchmarkGroup(["call"])
#SUITE["call"]["maximum 2*sin(s1) + 4 + cos(s2)^2"]["Vec"] = @benchmarkable maximum(2 .*sin.($x) .+ 4 .+ cos.($x).^2)
#for interp in continuous_interps
#	SUITE["call"]["maximum 2*sin(s1) + 4 + cos(s2)^2"]["$interp"] = @benchmarkable maximum(2*sin($interp($x, $x)) + 4 + cos($interp($x2, $x2))^2)
#end
## Realizing the values
#SUITE["realize"] = BenchmarkGroup()
#SUITE["realize"]["xvals"] = BenchmarkGroup()
#SUITE["realize"]["xvals"]["Vec"] = @benchmarkable zeros($N)
#for interp in interps
#	SUITE["realize"]["xvals"]["$interp"] = @benchmarkable xvals($interp($x, $x))
#end
#SUITE["realize"]["yvals"] = BenchmarkGroup()
#SUITE["realize"]["yvals"]["Vec"] = @benchmarkable sin.($x)
#for interp in interps
#	SUITE["realize"]["yvals"]["$interp"] = @benchmarkable yvals($interp($x, $x))
#end
#

## Then script that includes this should call `run(SUITE)`
#if false
#	today = run(SUITE)
#	BenchmarkTools.save("$(Dates.today()).json", today)
#	ref = BenchmarkTools.load("2021-10-05.json") |> first
#	@show minimum(today)
#	@show judge(minimum(today), minimum(ref))
#end
