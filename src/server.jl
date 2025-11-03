module _Server

import ..MATFrost as MATFrost
import ..MATFrost._Stream: BufferedStream
import ..MATFrost._Read:  read_matfrostarray!
import ..MATFrost._Write: write_matfrostarray!
import ..MATFrost._Stream: flush!, uds_accept, uds_bind, uds_connect, uds_listen, uds_socket, uds_read, uds_write, uds_init, uds_close, FD_TYPE, Buffer, BufferedUDS, write!, read!
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

function getMethod(meta::CallMeta)
    m = match(r"^([^.]+)\.([^(]+)(\(.*\))?$", meta.fully_qualified_name)
    if m === nothing
        throw("Incompatible fully_qualified_name")
    end
    (packagename, function_name, signature) = m.captures
    package = nothing

    try
        package = getfield(Main, Symbol(packagename))
    catch _
        try
            Main.eval(:(import $(Symbol(packagename))))
            package = getfield(Main, Symbol(packagename))
        catch _
            throw("Package $(packagename) not found")
        end
    end

    f = package
    function_symbols = Symbol.(split(function_name, "."))
    for sym in function_symbols
        try
            f = getfield(f, sym)
        catch _
            if isa(f, Function)
                continue
            else
                throw(ErrorException("Function $(meta.fully_qualified_name) not found"))
            end
        end
    end

    if length(methods(f)) !== 1 
        if signature === nothing
            error_msg = """
            Ambiguous function call: The function $(f) has multiple methods.
            Please specify the desired method signature.
            
            Available methods:
            $(methods(f))
            """
            throw(ErrorException(error_msg))
        else
            pattern = Regex("^$(function_symbols[end])\\($signature\\)")
            index = findfirst(m -> match(pattern, string(m)) !== nothing, methods(f))
            if index === nothing
                error_msg = """
                No matching method found for function $(f) with signature $(signature).
                
                Available methods:
                $(methods(f))
                """
                throw(ErrorException(error_msg))
            end
        end
        f = methods(f)[index]
    else
        f = methods(f)[1]
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

function callsequence(socket::BufferedUDS)

    callstruct = read_matfrostarray!(socket)

    try
        if !(callstruct isa MATFrostArrayCell) || length(callstruct.values) != 2
            throw("error")
        end

        callmeta = convert_matfrostarray(CallMeta, callstruct.values[1])
        
        f = getMethod(callmeta)
        
        Args = Tuple{f.sig.types[2:end]...}

        args = convert_matfrostarray(Args, callstruct.values[2])

        out = f(args...)

        write_matfrostarray!(socket, 
            MATFrostResultMATLAB("SUCCESFUL", "", out)
        )
    catch e
        write_matfrostarray!(socket, 
            MATFrostResultMATLAB("ERROR", "", e)
        )
    end

    flush!(socket)


end


function setup_uds_server(path)
    uds_init()

    server_socket_fd = uds_socket()

    rc_bind = uds_bind(server_socket_fd, path)

    rc_listen = uds_listen(server_socket_fd)

    server_socket_fd

end








end