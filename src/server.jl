module _Server

import ..MATFrost as MATFrost
import ..MATFrost._Read:  read_matfrostarray!
import ..MATFrost._Write: write_matfrostarray!
import ..MATFrost._Stream: flush!, uds_accept, uds_bind, uds_connect, uds_listen, uds_socket, uds_read, uds_write, uds_init, uds_close, FD_TYPE, Buffer, BufferedUDS
using ..MATFrost._Types
using ..MATFrost._Constants
using ..MATFrost._ConvertToJulia: _ConvertToJulia
using ..MATFrost._ConvertToMATLAB: _ConvertToMATLAB


struct CallMeta
    fully_qualified_name::String
end

struct MATFrostResultMATLAB{T}
    status::String # ERROR/SUCCESFUL
    log::String
    value::T
end

"""
This function is the basis of the MATFrostServer.
"""
function MATFrost.matfrostserve(socket_path::String)

    server_socket_fd = setup_uds_server(socket_path)

    client_socket_fd = uds_accept(server_socket_fd)
    
    println("MATFrost server connected. Ready for requests.")

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

function package_is_loaded(packagename)
    try 
        # Check if package is loaded. 
        getfield(Main, packagename)
        return true
    catch
        return false
    end
end

function callsequence(socket::BufferedUDS)

    callstruct = read_matfrostarray!(socket)

    marr = try

        if !(callstruct isa MATFrostArrayCell) || length(callstruct.values) != 2
            throw("error")
        end
        
        callmeta = _ConvertToJulia.convert_matfrostarray(CallMeta, callstruct.values[1])
        syms = Symbol.(split(callmeta.fully_qualified_name,"."))
        packagename = syms[1]


        if !Base.invokelatest(package_is_loaded, packagename)
            try
                Main.eval(:(import $packagename))
            catch e
                throw(MATFrostException("matfrostjulia:call:packageNotFound", 
"""
Package not found exception:

Package: $(packagename)
"""
))
            end
        end

        # As packages (currently) are loaded loaded on-demand after MATFrost server has been started,
        # the functions in those packages need to be called from a newer world age.
        # This ofcourse is not ideal and should be treated with care.
        Base.invokelatest(callsequence_latest_world_age, callmeta, callstruct.values[2])

    catch e 
        
        buf = IOBuffer()
        Base.showerror(buf, e)
        Base.show_backtrace(buf, Base.catch_backtrace())
        s = String(take!(buf))

        matfe=if e isa MATFrostException
            MATFrostException(e.id, "$(e.message)\n\n$(s)")
        else
            MATFrostException("matfrostjulia:call:call", s)
        end

        _ConvertToMATLAB.convert_matfrostarray(matfrostexceptionresult(matfe))
    end

    if marr isa MATFrostArrayAbstract
        write_matfrostarray!(socket, marr)
        flush!(socket)
    else
        error("Unclear error")
    end

end

function callsequence_latest_world_age(callmeta, callargs)
    
    f = getfunction(callmeta)
    
    Args = Tuple{methods(f)[1].sig.types[2:end]...}

    args=try
        _ConvertToJulia.convert_matfrostarray(Args, callargs)
    catch e
        if e isa MATFrostConversionException
            rethrow(matfrostinputconversionexception(e))
        end
        rethrow(e)
    end

    # The function call!
    out = f(args...)

    _ConvertToMATLAB.convert_matfrostarray(MATFrostResultMATLAB("SUCCESFUL", "", out))
    
end


function getfunction(meta::CallMeta)
    syms = Symbol.(split(meta.fully_qualified_name,"."))

    if length(syms) < 2
        throw(MATFrostException("matfrostjulia:call:callMeta", """
Invalid function call exception:

Minimum need at least a package and a function.

Function: $(meta.fully_qualified_name)
"""
))
    end
    
    packagename = syms[1]
    package = getfield(Main, packagename)

    f = package
    for i in 2:lastindex(syms)
        try
            f = getfield(f, syms[i])
        catch _
            throw(MATFrostException("matfrostjulia:call:functionNotFound", 
"""
Function not found exception:

Function: $(meta.fully_qualified_name)
"""
))
        end
    end

    if length(methods(f)) != 1
        throw(MATFrostException("matfrostjulia:call:multipleMethodDefinitions", 
"""
Multiple method definitions exception:

MATFrost determines the interface based on the call signature of a methods. Currently it is only supported to have one method per function.

For function: $(meta.fully_qualified_name)
    Actual number of methods:   $(length(methods(f)))
    Expected number of methods: 1
"""
))
    end

    return f

end

function matfrostinputconversionexception(e::MATFrostConversionException)
    tracereverse = reverse(e.stacktrace)

    tracestring = (
        if s isa Int64
            "[$(s)]" 
        elseif s isa Symbol
            ".$s"
        else
            ""
        end for s in tracereverse)
            
    message = "$(e.message)\n\nInput invalid at: arg$(tracestring...)"
    MATFrostException(e.id, message)
end

function matfrostexceptionresult(e)
    if e isa MATFrostException
        MATFrostResultMATLAB{MATFrostException}(
            "ERROR",
            "",
            e
        )
    else
        MATFrostResultMATLAB(
            "ERROR",
            "",
            e
        )
    end
end


function setup_uds_server(path)
    uds_init()

    server_socket_fd = uds_socket()

    rc_bind = uds_bind(server_socket_fd, path)

    rc_listen = uds_listen(server_socket_fd)

    server_socket_fd

end








end