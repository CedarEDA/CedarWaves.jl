using Pkg, TOML

docs_build_dir = "DocsBuild"
isdir(docs_build_dir) || mkdir(docs_build_dir)

pkg = "CedarWaves"
docpath = joinpath(@__DIR__)
dirpath = joinpath(docs_build_dir, pkg)
isdir(dirpath) || mkdir(dirpath)

if isdir(docpath)
    # Activate and instantiate the docs-Project
    @info "Pkg.activate($docpath)"
    Pkg.activate(docpath)

    # Add the dev-package
    me=joinpath(@__DIR__, "..")
    !isdir(me) && error("Project at $me doesn't exist")
    @info "Pkg.develop(path=$me)"
    Pkg.develop(path=me)
    @info "Pkg.instantiate()"
    Pkg.instantiate()
    # Although, a simple instantiate should do, it results in failing doctests
    # So parse its deps and add to the docs-env
    p_pkgs = TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))["deps"] |> keys |> collect
    @info "Pkg.add($p_pkgs)"
    Pkg.add(p_pkgs)

    # Make and copy the `build` as Cedar/package
    @info """include($(joinpath(docpath, "make.jl")))"""
    include(joinpath(docpath, "make.jl"))
    cp(
        joinpath(docpath, "build"),
        dirpath,
        force=true)
else
    error("docs path not found ($docpath) from dir $(pwd())")
end