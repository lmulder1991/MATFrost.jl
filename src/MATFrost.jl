module MATFrost
using Artifacts
using TOML

function _read! end
function _write! end

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

include("read.jl")
include("converttomatlab.jl")
include("juliacall.jl")
include("install.jl")
include("mex.jl")

using ._Stream

struct StructTest
    a::Float64
    b::Int64
    c::Float64
    d::String
end

struct StructTestNest
    a::StructTest
    b::StructTest
    c::Tuple{Float64,Int64}
end
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
        # arr = _ConvertToJulia.read_matlab!(in_buf, Vector{Int32})

        # _ConvertToMATLAB.write_matlab!(out_buf, arr)
        try 
            
        # arr = _ConvertToJulia.read_matlab!(in_buf, Vector{Int32})
            arr = _Read.read_matfrostarray!(in_buf, Vector{StructTestNest})

            _ConvertToMATLAB.write_matlab!(out_buf, arr)
        catch e
            _ConvertToMATLAB.write_matlab!(out_buf, string(e))
        end
        _Stream.flush!(out_buf)
        # t = _Stream.read!(in_buf, Int32)
        # ndimsv = _Stream.read!(in_buf, Int64)
        
        # totsize = 1
        # for i=1:ndimsv
        #     totsize *= _Stream.read!(in_buf, Int64)
        # end

        

        # arr = Vector{Int32}(undef, totsize)

        # _Stream.read!(in_buf, arr)


        # _Stream.write!(out_buf, Int32(11))
        # _Stream.write!(out_buf, Int64(2))
        # _Stream.write!(out_buf, Int64(1))
        # _Stream.write!(out_buf, Int64(1))
        # _Stream.write!(out_buf, convert(Int64, sum(arr)))
        # _ConvertToMATLAB.write_matlab!(out_buf, convert(Int64, sum(arr)))

        # _ConvertToMATLAB.write_matlab!(out_buf, collect(5:1000))
        
        # _Stream.flush!(out_buf)
        # sarr = Array{String,3}(undef, 3,2,3)
        # for i in eachindex(sarr)
        #     sarr[i] = "FFEF" * string(i)
        # end
        
        # _ConvertToMATLAB.write_matlab!(out_buf, [StructTest(23.0, 33, "FFDF"), StructTest(23332.0, 3553, "2nd")])

        # _ConvertToMATLAB.write_matlab!(out_buf, collect(5:1000))


        
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
