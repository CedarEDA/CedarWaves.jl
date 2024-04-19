#!/usr/bin/env julia
using Pkg

# Set to clone everything via SSH (if it can't be found in the package server)
# so we authenticate via SSH key to GitHub for our private packages/registries
Pkg.setprotocol!(protocol="ssh")

# Add our registries
Pkg.Registry.add([
    RegistrySpec(name="General"),
    RegistrySpec(url="https://github.com/JuliaComputing/JuliaSimRegistry")
])

# Instantiate the current project
Pkg.instantiate()

# Build (needed for Conda)
Pkg.build()

# Precompile in parallel
Pkg.precompile()

# Add the helper packages to build the sysimage
Pkg.add(["PackageCompiler", "SysimageBuilder"])