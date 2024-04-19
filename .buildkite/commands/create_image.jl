#!/usr/bin/env julia
using SysimageBuilder, Pkg, TOML
project_version= TOML.parsefile("Project.toml")["version"]
project_url, project_rev = ARGS

@info "Creating relocatable project..."
create_reloc_project(
    name="CedarSysimg",
    version=project_version,
    packages=[
        PackageSpec(name="CedarWaves", url=project_url, rev=project_rev),
        "Plots",
        PackageSpec(name="GR", url="https://github.com/bmharsha/GR.jl", rev="harsha-gr-sysimg"),
    ],
    precompile_files=Dict("CedarWaves" => ["runtests.jl"])
)
