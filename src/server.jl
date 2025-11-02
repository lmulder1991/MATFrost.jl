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


function MATFrost.matfrostserve(socket_path::String)

    server_socket_fd = setup_uds_server(socket_path)

    client_socket_fd = uds_accept(server_socket_fd)

    bufin = Buffer(Vector{UInt8}(undef, 2 << 15), 0, 0)
    bufout = Buffer(Vector{UInt8}(undef, 2 << 15), 0, 0)
    
    bufuds = BufferedUDS(client_socket_fd, bufin, bufout)
    
    while true  
        try 
            callsequence(bufuds)
        catch e
            Base.showerror(stdout, e)
            Base.show_backtrace(stdout, Base.catch_backtrace())
            exit()
        end
        
    end

end


function callsequence(socket::BufferedUDS)

    callstruct = read_matfrostarray!(socket)

    result = try
        if !(callstruct isa MATFrostArrayCell) || length(callstruct.values) != 2
            throw("error")
        end

        callmeta = convert_matfrostarray(CallMeta, callstruct.values[1])
        
        f = getfunction(callmeta)
        
        Args = Tuple{methods(f)[1].sig.types[2:end]...}

        args = convert_matfrostarray(Args, callstruct.values[2])

        out = f(args...)

        MATFrostResultMATLAB("SUCCESFUL", "", out)

    catch e
        Base.showerror(stdout, e)
        Base.show_backtrace(stdout, Base.catch_backtrace())
        MATFrostResultMATLAB("ERROR", "", e)
    end

    write_matfrostarray!(socket, result)
    flush!(socket)

end


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
            throw("Package $(packagename) not found")
        end
    end

    f = package
    for i in 2:lastindex(syms)
        try
            f = getfield(f, syms[i])
        catch _
            throw("Function $(meta.fully_qualified_name) not found")
        end
    end

    if length(methods(f)) != 1
        throw("Multiple methods found for function: $(meta.fully_qualified_name)")
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


function setup_uds_server(path)
    uds_init()
 
    println("WSA setup")

    server_socket_fd = uds_socket()

    println("Made socket")

    # path = raw"C:\Users\jbelier\Documents\test_matfrost3.sock"
    # if isfile(path)
    #     rm(path)
    # end
    rc_bind = uds_bind(server_socket_fd, path)
        
    println("Binded")

    rc_listen = uds_listen(server_socket_fd)
        
    println("Listening")

    server_socket_fd

end



# macro MATFrost.matfrostserve(socket_path)
# esc(quote

#     MATFrost._Server.matfrostserve($socket_path)

# end)

# end







end