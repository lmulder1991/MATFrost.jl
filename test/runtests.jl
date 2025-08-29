
using MATFrost
using Test
using JET



function _writebuffer!(io::MATFrost._Stream.BufferedStream, v::T) where T
    p = reinterpret(Ptr{T}, pointer(io.buffer) + io.available)
    unsafe_store!(p, v)
    io.available += sizeof(T)
end


function _readbuffer!(io::MATFrost._Stream.BufferedStream, ::Type{T}) where T
    p = reinterpret(Ptr{T}, pointer(io.buffer) + io.position)
    io.position += sizeof(T)
    unsafe_load(p)
end

function _clearbuffer(io)
    io.position = 0
    io.available =0 
end


stream = MATFrost._Stream.BufferedStream(C_NULL, Vector{UInt8}(undef, 2 << 8), 0, 0)

_writebuffer!(stream, MATFrost._Read.INT64)
_writebuffer!(stream, 2)
_writebuffer!(stream, 1)
_writebuffer!(stream, 1)
_writebuffer!(stream, 4321)

@test MATFrost._Read.read_matfrostarray!(stream, Int64).x.x == 4321
@test_opt MATFrost._Read.read_matfrostarray!(stream, Int64)


_clearbuffer(stream)
_writebuffer!(stream, MATFrost._Read.INT64)
_writebuffer!(stream, 2)
_writebuffer!(stream, 4)
_writebuffer!(stream, 3)
foreach(i -> _writebuffer!(stream, i), 1:12)

@test MATFrost._Read.read_matfrostarray!(stream, Matrix{Int64}).x.x == collect(reshape(1:12, (4,3))) 


struct TestStruct1
    a::Float64
    b::Int64
    d::String
end


@test_opt  MATFrost._Read.incompatible_datatypes_exception(TestStruct1, Int32(23))
@test_call MATFrost._Read.incompatible_datatypes_exception(TestStruct1, Int32(23))

@test_opt MATFrost._Read.incompatible_array_dimensions_exception(Array{TestStruct1,2}, Int64[2,3,4])
@test_call MATFrost._Read.incompatible_array_dimensions_exception(Array{TestStruct1,2}, Int64[2,3,4])

@test_opt MATFrost._Read.not_scalar_value_exception(Array{TestStruct1,2}, Int64[2,3,4])
@test_call MATFrost._Read.not_scalar_value_exception(Array{TestStruct1,2}, Int64[2,3,4])

@test_opt MATFrost._Read.missing_fields_exception(Array{TestStruct1,2}, Symbol[:a,:b])
@test_call MATFrost._Read.missing_fields_exception(Array{TestStruct1,2}, Symbol[:a,:b])


@test_opt MATFrost._Read.additional_fields_exception(Array{TestStruct1,2}, Symbol[:a,:b])
@test_call MATFrost._Read.additional_fields_exception(Array{TestStruct1,2}, Symbol[:a,:b])

