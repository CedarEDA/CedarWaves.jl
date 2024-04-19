using PackageCompiler
import Pkg
Pkg.activate(".")
println("Building system image without CedarWaves:")
PackageCompiler.create_sysimage(; sysimage_path="partial_sysimage.so")
