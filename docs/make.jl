ENV["JULIA_DEBUG"] = "Documenter"
using Documenter
using CedarWaves
using Plots
ENV["MPLBACKEND"] = "agg"
# intialize plot backend
gr()

DocMeta.setdocmeta!(CedarWaves, :DocTestSetup, :(using CedarWaves, Plots; gr()); recursive=true)

makedocs(;
    sitename = "CedarWaves",
    authors="JuliaHub, Inc.",
    format=Documenter.HTML(; edit_link=nothing, sidebar_sitename=false, ansicolor=true),
    clean=true,
    modules = [CedarWaves],
    strict=[
        :doctest,
        :linkcheck,
        :parse_error,
        :example_block,
        # Other available options are
        # :autodocs_block, :cross_references, :docs_block, :eval_block, :example_block, :footnote, :meta_block, :missing_docs, :setup_block
    ],
    pages = [
        "Getting Started" => "index.md",
        "user_guide.md",
        #"User Guide" => [   "user_guide/all.md",
                            #hide("user_guide/user_guide.md"),
                            #"Introduction" => "user_guide/intro.md",
                            #"Signal Creation" => "user_guide/signal_creation.md",
                            #"TODO" => "user_guide/signals.md",
        #],
        "Reference" => "reference.md",
        "Index" => "docs_index.md",
        "License" => "license.md",
        #"Signal Types" => "into.md",
        #"Tutorials" => [
        #                "tutorials/purpose.md",
        #                "tutorials/basic.md",
        #                "tutorials/freq_domain.md",
        #],
        #"Manual" => [
        #                "manual/overview.md",
        #                "manual/construction.md",
        #                "manual/deconstruction.md",
        #                "manual/indexing.md",
        #                "manual/iteration.md",
        #                "manual/interpolation.md",
        #                "manual/thresholds.md",
        #                "manual/percent.md",
        #                "manual/custom.md",
        #],
        #"Index" => [
        #                "index/index.md",
        #                "index/operators.md",
        #                "index/elementary.md",
        #                "index/wave.md",
        #                "index/scalar.md",
        #                "index/freq.md",
        #]
    ]
)

if occursin(r"^refs\/tags\/(.*)$", get(ENV, "GITHUB_REF", ""))
    deploydocs(
        repo = "github.com/JuliaComputing/CedarWaves.jl.git",
        branch = "docs",
        target = "build"
    )
end
