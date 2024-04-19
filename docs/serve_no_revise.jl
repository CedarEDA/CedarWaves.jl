println("Run this with: julia -L serve.jl")
println("Go to http://localhost:8801/build to view docs")
println("""Using Revise so after updating docs then run: include("make.jl")""")
import LiveServer
@async LiveServer.serve(port=8801)

#includet("make.jl")
include("make.jl")
