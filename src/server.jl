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
    for i in 2:lastindex(syms)
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

function callsequence(socket::BufferedUDS)

    callstruct = read_matfrostarray!(socket)

    try
        if !(callstruct isa MATFrostArrayCell) || length(callstruct.values) != 2
            throw("error")
        end

        callmeta = convert_matfrostarray(CallMeta, callstruct.values[1])
        
        f = getfunction(callmeta)
        
        Args = Tuple{methods(f)[1].sig.types[2:end]...}

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



function connect()
    uds_init()

    println("WSA setup")

    socket_fd = uds_socket()

    println("Made socket")

    path = raw"C:\Users\jbelier\Documents\test_matfrost3.sock"

    rc_connect = uds_connect(socket_fd, path)

    # function uds_socket()
    vsize = Ref{Cint}()
    optlen = Ref{Cint}(4)
    @ccall "Ws2_32.dll".getsockopt(
        socket_fd::FD_TYPE, 
        Cint(0xffff)::Cint,
        Cint(0x1001)::Cint,
        vsize::Ref{Cint},
        optlen::Ref{Cint})::Cint

    println("Send size: $(vsize[])")    
    
    @ccall "Ws2_32.dll".getsockopt(
        socket_fd::FD_TYPE, 
        Cint(0xffff)::Cint,
        Cint(0x1002)::Cint,
        vsize::Ref{Cint},
        optlen::Ref{Cint})::Cint

    println("Recieve size: $(vsize[])")
# end

#     int WSAAPI getsockopt(
#   [in]      SOCKET s,
#   [in]      int    level,
#   [in]      int    optname,
#   [out]     char   *optval,
#   [in, out] int    *optlen
# );
    socket = BufferedUDS(
        socket_fd, 
        Buffer(Vector{UInt8}(undef, 2 << 15), 0, 0),
        Buffer(Vector{UInt8}(undef, 2 << 15), 0, 0))
    
    callstruct = (
        (fully_qualified_name="MATFrost._Server.matfrosttest",),
        (12.0,)
    )
    
    println("Writing")
    write_matfrostarray!(socket, callstruct)
    flush!(socket)
    
    println("Written")
    out = read_matfrostarray!(socket)

    println(out)

    uds_close(socket_fd)

end

matfrostserve() = matfrostserve(raw"C:\Users\jbelier\Documents\test_matfrost3.sock")

function matfrostserve(socket_path::String)

    server_socket_fd = setup_uds_server(socket_path)
    bufin = Buffer(Vector{UInt8}(undef, 2 << 15), 0, 0)
    bufout = Buffer(Vector{UInt8}(undef, 2 << 15), 0, 0)


    while true  
        try 
            client_socket_fd = uds_accept(server_socket_fd)

            println("Accepted")

            bufin.position = 0
            bufin.available = 0
            bufout.position = 0
            bufout.available = 0

            bufuds = BufferedUDS(client_socket_fd, bufin, bufout)
            callsequence(bufuds)

            uds_close(client_socket_fd)

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