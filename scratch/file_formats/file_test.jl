using Parquet2, Tables, DataFrames, Arrow, Tables, HDF5, H5Zblosc, H5Zzstd, H5Zlz4, HDF5.Filters, Blosc
using PrettyTables, TerminalPager, ColorSchemes
import Parquet2
import CSV

function benchmark(testcases=1:3; N=3, points=12_500_000, select=minimum, minrows=1000, chunksize=1250)
    res = DataFrame(Trial=Int[], Format=String[], Operation=String[], Codec=String[], Chunk=Int[], Rows=Int[], Columns=Int[], Time=Float64[], MB=Float64[])
    # Parquet2:
    C = 1
    R = points÷C
    chunk=(min(chunksize, R),)
    while R >= minrows
        MB = R*C*8 ÷ 1000000
        println("Generating test data ($(R)x$(C) x8 = $MB MB)")
        times = range(0, 1, length=R)
        data = [sin(2π*t*freq) for t in times, freq in 1:C]
        df = DataFrame(data, :auto)
        # Write tests
        for compression_codec in [:uncompressed, :snappy, :zstd]
            println("Benchmarking Parquet2.writefile with $compression_codec compression")
            for i in 1:N
                f = "test.W=$C.L=$R.$compression_codec.parq"
                t = @elapsed Parquet2.writefile(f, df; compression_codec)
                MB = round(filesize(f)/1_000_000, digits=2)
                push!(res, [i, "Parquet2", "write", "$compression_codec", 0, R, C, t, MB])
            end
        end
        println("Benchmarking CSV.write")
        for i in 1:N
            f = "test.W=$C.L=$R.csv"
            t = @elapsed CSV.write(f, df)
            MB = round(filesize(f)/1_000_000, digits=2)
            push!(res, [i, "CSV", "write", "uncompressed", 0, R, C, t, MB])
        end
        println("Benchmarking Arrow.write")
        for i in 1:N
            f = "test.W=$C.L=$R.arrow"
            t = @elapsed Arrow.write(f, df)
            MB = round(filesize(f)/1_000_000, digits=2)
            push!(res, [i, "Arrow", "write", "uncompressed", 0, R, C, t, MB])
        end
        comp = "uncompressed"
        println("Benchmarking h5write $comp")
        for i in 1:N
            f = "test.W=$C.L=$R.$comp.h5"
            t = @elapsed begin
                h5open(f, "w") do h5
                    for (c, col) in enumerate(eachcol(df))
                        h5["$c"] = col
                    end
                end
            end
            MB = round(filesize(f)/1_000_000, digits=2)
            push!(res, [i, "HDF5", "write", "$comp", 0, R, C, t, MB])
        end
        comp = "zlib"
        println("Benchmarking h5write $comp")
        for i in 1:N
            f = "test.W=$C.L=$R.$comp.h5"
            t = @elapsed begin
                h5open(f, "w") do h5
                    for (c, col) in enumerate(eachcol(df))
                        h5["$c", chunk=chunk, shuffle=(), compress=3] = col
                    end
                end
            end
            MB = round(filesize(f)/1_000_000, digits=2)
            push!(res, [i, "HDF5", "write", "$comp", chunk, R, C, t, MB])
        end
        comp = "zstd"
        println("Benchmarking h5write $comp")
        for i in 1:N
            f = "test.W=$C.L=$R.$comp.h5"
            t = @elapsed begin
                h5open(f, "w") do h5
                    for (c, col) in enumerate(eachcol(df))
                        h5["$c", chunk=chunk, shuffle=(), filters=[ZstdFilter(3)]] = col
                    end
                end
            end
            MB = round(filesize(f)/1_000_000, digits=2)
            push!(res, [i, "HDF5", "write", "$comp", chunk, R, C, t, MB])
        end
        comp = "lz4"
        println("Benchmarking h5write $comp")
        for i in 1:N
            f = "test.W=$C.L=$R.$comp.h5"
            t = @elapsed begin
                h5open(f, "w") do h5
                    for (c, col) in enumerate(eachcol(df))
                        h5["$c", chunk=chunk, shuffle=(), filters=[Lz4Filter(64)]] = col
                    end
                end
            end
            MB = round(filesize(f)/1_000_000, digits=2)
            push!(res, [i, "HDF5", "write", "$comp", chunk, R, C, t, MB])
        end
        comp = "szip"
        println("Benchmarking h5write $comp")
        for i in 1:N
            f = "test.W=$C.L=$R.$comp.h5"
            t = @elapsed begin
                h5open(f, "w") do h5
                    for (c, col) in enumerate(eachcol(df))
                        h5["$c", chunk=chunk, filters=[Szip()]] = col
                    end
                end
            end
            MB = round(filesize(f)/1_000_000, digits=2)
            push!(res, [i, "HDF5", "write", "$comp", chunk, R, C, t, MB])
        end
        for comp in Blosc.compressors()
            println("Benchmarking h5write $comp")
            for i in 1:N
                f = "test.W=$C.L=$R.$comp.h5"
                t = @elapsed begin
                    h5open(f, "w") do h5
                        for (c, col) in enumerate(eachcol(df))
                            h5["$c", chunk=chunk, filters=[BloscFilter(compressor=comp)]] = col
                        end
                    end
                end
                MB = round(filesize(f)/1_000_000, digits=2)
                push!(res, [i, "HDF5", "write", "$comp", chunk, R, C, t, MB])
            end
        end
        # Update loop vars
        C *= 100
        R = points÷C
    end
    # Read tests to read the last column (do after read tests to avoid caching)
    C = 1
    R = points÷C
    while R >= minrows
        MB = R*C*8 ÷ 1000000
        for compression_codec in [:uncompressed, :snappy, :zstd]
            println("Benchmarking Parquet2.readfile with $compression_codec compression")
            for i in 1:N
                f = "test.W=$C.L=$R.$compression_codec.parq"
                t = @elapsed begin
                    ds = Parquet2.readfile(f)
                    x1 = Tables.getcolumn(ds, Symbol("x", C))
                    sum(x1)
                end
                MB = round(filesize(f)/1_000_000, digits=2)
                push!(res, [i, "Parquet2", "read", "$compression_codec", 0, R, C, t, MB])
            end
        end
        println("Benchmarking Arrow.read")
        for i in 1:N
            f = "test.W=$C.L=$R.arrow"
            t = @elapsed begin
                t = Arrow.Table(f)
                x1 = t[C]
                sum(x1)
            end
            MB = round(filesize(f)/1_000_000, digits=2)
            push!(res, [i, "Arrow", "read", "uncompressed", 0, R, C, t, MB])
        end
        for nm in vcat([:uncompressed, :zlib, :lz4, :zstd, :szip], Blosc.compressors())
            println("Benchmarking HDF5.h5read $nm")
            for i in 1:N
                f = "test.W=$C.L=$R.$nm.h5"
                t = @elapsed begin
                    x1 = h5read(f, "$C")
                    sum(x1)
                end
                MB = round(filesize(f)/1_000_000, digits=2)
                push!(res, [i, "HDF5", "read", "$nm", nm == :uncompressed ? 0 : chunk, R, C, t, MB])
            end
        end
        println("Benchmarking CSV.read")
        for i in 1:N
            f = "test.W=$C.L=$R.csv"
            t = @elapsed begin
                csv = CSV.read(f, DataFrame)
                x1 = getproperty(csv, Symbol("x", C))
                sum(x1)
            end
            MB = round(filesize(f)/1_000_000, digits=2)
            push!(res, [i, "CSV", "read", "uncompressed", 0, R, C, t, MB])
        end
        # Update loop vars
        C *= 100
        R = points÷C
    end
    #sort(DataFrames.combine(groupby(res, [:Format, :Operation, :Codec, :Rows, :Columns]), :Time => select, :MB => select), [:Operation, :Columns, Symbol("Time_$select")])
    #sort(DataFrames.combine(groupby(res, [:Format, :Operation, :Codec, :Rows, :Columns]), :Time => select, :MB => select), [:Operation, :Columns, Symbol("Time_$select")])
    return res
end
function show_colors(df::DataFrame; colorize_cols=nothing, colorscheme=:Wistia, kwargs...)
    int_cols = Int[]
    if isnothing(colorize_cols)
        colorize_cols = names(df, Real)
    end
    for col in colorize_cols
        if !(col isa Int)
            col = findfirst(isequal(string(col)), names(df))
            @assert col isa Int "Column name `$col` must be a column name or index"
        end
        push!(int_cols, col)
    end
    hls = Highlighter[]
    for col in int_cols
        a, b = extrema(df[:, col])
        if a > 0 && b > 0
            if log10(b/a) > 2
                scale = x -> log10(x)
            else
                scale = x -> x
            end
        else
            scale = x -> x
        end
        hl = Highlighter((data, i, j) -> j == col,
            (h, data, i, j) -> begin
            color = get(colorschemes[colorscheme], scale(data[i, j]), extrema(scale.(data[:, j])))
            return Crayon(foreground = (round(Int, color.r * 255),
                                        round(Int, color.g * 255),
                                        round(Int, color.b * 255)))
        end)
        push!(hls, hl)
    end
    show(df; header=names(df), highlighters=tuple(hls...), kwargs...)
end

if false
    #raw1250 = benchmark(N=10, points=12_500_000, chunksize=1250) # faster
    #raw1250.Chunk .= 1250
    #raw128 = benchmark(N=10, points=12_500_000, chunksize=128) # slower
    #raw128.Chunk .= 128
    #raw125000 = benchmark(N=10, points=12_500_000, chunksize=125000) # slower, more compressed
    #raw125000.Chunk .= 125000
    #rawres = vcat(raw1250, raw128, raw125000)
    rawres = benchmark(N=10, points=12_500_000, chunksize=1250)
    show_colors(rawres)
    show_colors(sort(rawres, [:Rows, :Time]))
    show_colors(sort(rawres[rawres.Format .!= "CSV" .&& rawres.Codec .!= "zlib" .&& rawres.Trial .!= 1, :], [:Rows, :Time])) # remove really slow ones
    res1 = rawres[rawres.Trial .== 1, :]
    sort!(res1, [:Operation, :Columns, :Time])
    show_colors(res1)
    select=minimum
    reads = rawres[rawres.Operation .== "read", :]
    minreads = sort(DataFrames.combine(groupby(reads, [:Format, :Operation, :Codec, :Rows, :Columns]), :Time => select, :MB => select), [:Operation, :Columns, Symbol("Time_$select")])
    writes = rawres[rawres.Operation .== "write", :]
    minwrites = sort(DataFrames.combine(groupby(writes, [:Format, :Operation, :Codec, :Rows, :Columns]), :Time => select, :MB => select), [:Operation, :Columns, Symbol("Time_$select")])
    show_colors(minreads)
    show_colors(minwrites)
end


