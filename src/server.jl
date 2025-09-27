module _Server

import ..MATFrost as MATFrost
import ..MATFrost._Stream: BufferedStream
import ..MATFrost._Read: read_matfrostarray_header!, read_matfrostarray!, discard_matfrostarray!, Ok, Err, CELL
import ..MATFrost._Write: write_matfrostarray!
import ..MATFrost._Stream: flush!

struct CallMeta
    fully_qualified_name::String
end

struct MATFrostResultMATLAB{T}
    status::String # ERROR/SUCCESFUL
    log::String
    value::T
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

function matfrostexceptionresult(id, message)
    MATFrostResultMATLAB{MATFrostException}(
        "ERROR",
        "",
        MATFrostException(id, message)
    )
end

function callsequence(matfrostin::BufferedStream, matfrostout::BufferedStream)
    header = read_matfrostarray_header!(matfrostin)
    
    if header.type != CELL || prod(header.dims) != 2
        # This should in theory not happen.
        discard_matfrostarray_body!(matfrostin, header)
        write_matfrostarray!(matfrostout, matfrostexceptionresult("", "error"))
        return
    end

    meta = read_matfrostarray!(matfrostin, CallMeta).x

    if meta isa Err
        discard_matfrostarray!(matfrostin)
        write_matfrostarray!(matfrostout, matfrostexceptionresult("", "CallMeta not properly written"))
        return
    end

    f = getfunction(meta.x)

    if isnothing(f)
        discard_matfrostarray!(matfrostin)
        write_matfrostarray!(matfrostout, matfrostexceptionresult("", "Cannot find function"))
        return
    end

    Args = Tuple{methods(f)[1].sig.types[2:end]...}

    args = read_matfrostarray!(matfrostin, Args).x

    if args isa Err
        write_matfrostarray!(matfrostout, matfrostexceptionresult("", "Parsing error"))
        return
    end

    try
        o = f((args.x)...)
        write_matfrostarray!(matfrostout, 
            MATFrostResultMATLAB("SUCCESFUL", "", o)
        )
    catch
        write_matfrostarray!(matfrostout, matfrostexceptionresult("", "Execution error"))
    end
end


function matfrostserve(matfrostin_handle::Ptr{Cvoid}, matfrostout_handle::Ptr{Cvoid})
    matfrostin = BufferedStream(matfrostin_handle, Vector{UInt8}(undef, 2<<13), 0, 0)
    matfrostout  = BufferedStream(matfrostout_handle, Vector{UInt8}(undef, 2<<13), 0, 0)

    while true  
        try 

            callsequence(matfrostin, matfrostout)
            flush!(matfrostout)

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