using PackageCompiler
import Pkg
Pkg.activate(".")

PackageCompiler.create_sysimage(; sysimage_path="full_sysimage.so",
    precompile_execution_file="generate_precompile.jl")
