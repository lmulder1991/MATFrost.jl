module MATFrost
using Artifacts
using TOML

struct _MATFrostArray
    type::Cint
    ndims::Csize_t
    dims::Ptr{Csize_t}
    data::Ptr{Cvoid}
    nfields::Csize_t
    fieldnames::Ptr{Cstring}
end

struct _MATFrostException <: Exception 
    id::String
    message::String
end

include("stream.jl")

include("converttojulia.jl")
include("converttomatlab.jl")
include("juliacall.jl")
include("install.jl")
include("mex.jl")

using ._Stream

function serve(h_stdin_num, h_stdout_num)
    Nel = 1000000 + 2*3 + 1
    buf = Vector{Int32}(undef, Nel)
#    el = 0
    # h_stdin = @ccall "kernel32".GetStdHandle(Int32(-10)::Cint)::Ptr{Cvoid}
    # h_stdout = @ccall "kernel32".GetStdHandle(Int32(-11)::Cint)::Ptr{Cvoid}
   
    h_stdin = reinterpret(Ptr{Cvoid}, h_stdin_num)
    h_stdout = reinterpret(Ptr{Cvoid}, h_stdout_num)

    open(raw"C:\Users\jbelier\Documents\matfrosthandles.txt","w") do io
        println(io,h_stdin)
        println(io, h_stdout)
    end

    in_buf = _Stream.BufferedStream(h_stdin, Vector{UInt8}(undef, 2<<13), 0, 0)
    # io = _Stream
    out_buf  = _Stream.BufferedStream(h_stdout, Vector{UInt8}(undef, 2<<13), 0, 0)

    while true  
        
        t = _Stream.read!(in_buf, Int32)
        ndimsv = _Stream.read!(in_buf, Int64)
        
        totsize = 1
        for i=1:ndimsv
            totsize *= _Stream.read!(in_buf, Int64)
        end

        arr = Vector{Int32}(undef, totsize)

        _Stream.read!(in_buf, arr)


        _Stream.write!(out_buf, Int32(11))
        _Stream.write!(out_buf, Int64(2))
        _Stream.write!(out_buf, Int64(1))
        _Stream.write!(out_buf, Int64(1))
        _Stream.write!(out_buf, convert(Int64, sum(arr)))
        _Stream.flush!(out_buf)
        
        # write(stdout, convert(Int64, sum(arr)))
        # _stream.write!(out_buf, convert(Int64, sum(arr)))

        
        # _Stream.flush!(out_buf)

        # bytesread = Ref{UInt32}(0)
        # br = 0
        # while br < 4*Nel
        #     toread = min(65536, 4*Nel - br)
        #     @ccall "kernel32".ReadFile(
        #         h_stdin::Ptr{Cvoid},
        #         (pointer(buf) + br)::Ptr{Cvoid},
        #         Int32(toread)::Cint,
        #         bytesread::Ref{UInt32},
        #         C_NULL::Ptr{Cvoid})::Int32

        #     br = br + toread
        # end
        # read!(stdin, buf)


        # write(stdout, convert(Int64, buf[1]))
    end

    # while true
    #     read()

    # end

end

end
