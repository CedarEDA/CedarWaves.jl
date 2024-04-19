# Tables.jl interface for reading Tables into Signals
function fromcolumns(table, constructor)
    cols = Tables.columns(table)
    names = string.(collect(Symbol, Tables.columnnames(cols)))
    # Assume first column is x-axis
    x = Tables.getcolumn(cols, 1)
    signals = Dict{String,AbstractSignal}()
    for i in 2:length(names)
        y = _getvector(Tables.getcolumn(cols, i))
        signals[names[i]] = constructor(x, y)
    end
    return signals
end
_getvector(x::AbstractVector) = x
_getvector(x) = collect(x)
PWL(t::Tables.CopiedColumns) = fromcolumns(t, PWL)
PWC(t::Tables.CopiedColumns) = fromcolumns(t, PWC)
PWQuadratic(t::Tables.CopiedColumns) = fromcolumns(t, PWQuadratic)
PWAkima(t::Tables.CopiedColumns) = fromcolumns(t, PWAkima)
PWCubic(t::Tables.CopiedColumns) = fromcolumns(t, PWCubic)
Series(t::Tables.CopiedColumns) = fromcolumns(t, Series)