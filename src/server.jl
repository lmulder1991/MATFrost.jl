module _Server

import ..MATFrost as MATFrost
import ..MATFrost._Stream: BufferedStream
import ..MATFrost._Read: read_matfrostarray_header!, read_matfrostarray!, discard_matfrostarray!, Ok, Err, CELL
import ..MATFrost._Write: write_matfrostarray!
import ..MATFrost._Stream: flush!

struct CallMeta
    fully_qualified_name::String
end

matfrosttest(x::Float64)=23*x

function getfunction(meta::CallMeta)
    syms = Symbol.(eachsplit(meta.fully_qualified_name,"."))

    if length(syms) < 2
        return nothing
    end
    
    packagename = syms[1]
    package = nothing
    try
        package = getfield(Main, packagename)
    catch _
        try
            Main.eval(:(import $packagename))
            package = getfield(Main, packagename)
        catch _
            return nothing
        end
    end

    f = package
    for i in 2:length(syms)
        try
            f = getfield(f, syms[i])
        catch _
            return nothing
        end
    end

    if length(methods(f)) != 1
        return nothing
    end

    return f

end


function callsequence()

end


function matfrostserve(matfrostin::Ptr{Cvoid}, matfrostout::Ptr{Cvoid})
    in_buf = BufferedStream(matfrostin, Vector{UInt8}(undef, 2<<13), 0, 0)
    out_buf  = BufferedStream(matfrostout, Vector{UInt8}(undef, 2<<13), 0, 0)

    while true  
        try 

            header = read_matfrostarray_header!(in_buf)

            if header.type != CELL || prod(header.dims) != 2
                # This should in theory not happen.
                discard_matfrostarray_body!(in_buf, header)
                write_matfrostarray!(out_buf, "error")
                flush!(out_buf)
                continue
            end

            meta = read_matfrostarray!(in_buf, CallMeta)
            if meta.x isa Err
                discard_matfrostarray!(in_buf)
                write_matfrostarray!(out_buf, "error")
                flush!(out_buf)
                continue
            end


            f = getfunction(meta.x.x)

            if isnothing(f)
                discard_matfrostarray!(in_buf)
                write_matfrostarray!(out_buf, "error")
                flush!(out_buf)
                continue
            end

            Args = Tuple{methods(f)[1].sig.types[2:end]...}

            args = read_matfrostarray!(in_buf, Args)

            if args.x isa Err
                write_matfrostarray!(out_buf, "error")
                flush!(out_buf)
                continue
            end

            try
                o = f((args.x.x)...)
                write_matfrostarray!(out_buf, o)           
                flush!(out_buf)
            catch
                write_matfrostarray!(out_buf, "Execution error")           
                flush!(out_buf)
            end

        catch e
            
            open(raw"C:\Users\jbelier\Documents\matfrosttest\errored.txt", "w") do iof
                println(iof, e)
                Base.showerror(iof, e)
                Base.show_backtrace(iof, Base.catch_backtrace())
            end

            exit()
        end
        
    end


end



macro MATFrost.matfrostserve(matfrostin, matfrostout)
esc(quote

    MATFrost._Server.matfrostserve($matfrostin, $matfrostout)

end)

end







end