using PkgBenchmark, BenchmarkTools
#import CedarWaves
current = benchmarkpkg("..")
cur = current.benchmarkgroup
println(current)
previous = benchmarkpkg("..", BenchmarkConfig(id="HEAD~1"))
ref = previous.benchmarkgroup
println(judge(minimum(cur), minimum(ref)))