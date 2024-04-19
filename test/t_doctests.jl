using CedarWaves
using Documenter, Test

@testset "doctests" begin
    DocMeta.setdocmeta!(CedarWaves, :DocTestSetup, :(using CedarWaves, Logging; Logging.disable_logging(Logging.Warn)); recursive=true)
    doctest(CedarWaves, manual=false)  # don't run on .md files yet
end