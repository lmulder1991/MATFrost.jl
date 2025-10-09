module _Server

import ..MATFrost as MATFrost
import ..MATFrost._Stream: BufferedStream
import ..MATFrost._Read:  read_matfrostarray!
import ..MATFrost._Write: write_matfrostarray!
import ..MATFrost._Stream: flush!
using ..MATFrost._Types
using ..MATFrost._Constants
using ..MATFrost._Convert: convert_matfrostarray

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
        throw("Incompatible fully_qualified_name")
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
            throw("Package not found")
        end
    end

    f = package
    for i in 2:length(syms)
        try
            f = getfield(f, syms[i])
        catch _
            throw("Function not found")
        end
    end

    if length(methods(f)) != 1
        throw("Multiple methods for function defintion found")
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

    callstruct = read_matfrostarray!(matfrostin)

    try
        if !(callstruct isa MATFrostArrayCell) || length(callstruct.values) != 2
            throw("error")
        end

        callmeta = convert_matfrostarray(CallMeta, callstruct.values[1])
        
        f = getfunction(callmeta)
        
        Args = Tuple{methods(f)[1].sig.types[2:end]...}

        args = convert_matfrostarray(Args, callstruct.values[2])

        out = f(args...)

        write_matfrostarray!(matfrostout, 
            MATFrostResultMATLAB("SUCCESFUL", "", out)
        )
    catch e
        write_matfrostarray!(matfrostout, 
            MATFrostResultMATLAB("ERROR", "", e)
        )
    end

    flush!(matfrostout)


end


function matfrostserve(matfrostin_handle::Ptr{Cvoid}, matfrostout_handle::Ptr{Cvoid})
    matfrostin = BufferedStream(matfrostin_handle, Vector{UInt8}(undef, 2<<13), 0, 0)
    matfrostout  = BufferedStream(matfrostout_handle, Vector{UInt8}(undef, 2<<13), 0, 0)

    while true  
        try 

            callsequence(matfrostin, matfrostout)

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