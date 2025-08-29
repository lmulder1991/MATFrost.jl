
using MATFrost
using Test
using JET



function _writebuffer!(io::MATFrost._Stream.BufferedStream, v::T) where T
    p = reinterpret(Ptr{T}, pointer(io.buffer) + io.available)
    unsafe_store!(p, v)
    io.available += sizeof(T)
end

# function _writebuffer!(io::MATFrost._Stream.BufferedStream, v::String)
#     p = reinterpret(Ptr{T}, pointer(io.buffer) + io.available)
#     unsafe_store!(p, v)
#     io.available += sizeof(T)
# end

function _writebuffer!(io::MATFrost._Stream.BufferedStream, s::String)
    _writebuffer!(io, ncodeunits(s))
    
    psrc = reinterpret(Ptr{UInt8}, pointer(s))
    pdest = pointer(io.buffer) + io.available

    Base.memcpy(pdest, psrc, ncodeunits(s))

    io.available += ncodeunits(s)

end


function _writematfrostarray!(io::MATFrost._Stream.BufferedStream, v::T) where T
    _writebuffer!(io, MATFrost._Read.expected_matlab_type(T))
    _writebuffer!(io, 2)
    _writebuffer!(io, 1)
    _writebuffer!(io, 1)
    _writebuffer!(io, v)
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


stream = MATFrost._Stream.BufferedStream(C_NULL, Vector{UInt8}(undef, 2 << 16), 0, 0)

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




_clearbuffer(stream)
_writebuffer!(stream, MATFrost._Read.CELL)
_writebuffer!(stream, 1)
_writebuffer!(stream, 3)
_writematfrostarray!(stream, 23)
_writematfrostarray!(stream, 23.0)
_writematfrostarray!(stream, Int32(23))

@test MATFrost._Read.read_matfrostarray!(stream,Tuple{Int64, Float64, Int32}).x.x == (23, 23.0, Int32(23))

@test_opt MATFrost._Read.read_matfrostarray!(stream, Tuple{Int64, Float64, Int32})
@test_call MATFrost._Read.read_matfrostarray!(stream, Tuple{Int64, Float64, Int32})







_clearbuffer(stream)
_writematfrostarray!(stream, "TestingString")
@test MATFrost._Read.read_matfrostarray!(stream, String).x.x == "TestingString"




_clearbuffer(stream)
_writebuffer!(stream, MATFrost._Read.STRUCT)
_writebuffer!(stream, 1) # ndims
_writebuffer!(stream, 1) # dim1
_writebuffer!(stream, 3) # nfields
_writebuffer!(stream, "a")
_writebuffer!(stream, "b")
_writebuffer!(stream, "d")
_writematfrostarray!(stream, 321.0)
_writematfrostarray!(stream, 321)
_writematfrostarray!(stream, "321")

@test MATFrost._Read.read_matfrostarray!(stream, TestStruct1).x.x == TestStruct1(321.0, 321, "321")
@test_opt MATFrost._Read.read_matfrostarray!(stream,  TestStruct1)
@test_call MATFrost._Read.read_matfrostarray!(stream, TestStruct1)






_clearbuffer(stream)
_writebuffer!(stream, MATFrost._Read.STRUCT)
_writebuffer!(stream, 2) # ndims
_writebuffer!(stream, 3) # dim1
_writebuffer!(stream, 4) # dim2
_writebuffer!(stream, 3) # nfields
_writebuffer!(stream, "a")
_writebuffer!(stream, "b")
_writebuffer!(stream, "d")

arr = Matrix{TestStruct1}(undef, 3, 4)
for i in 1:12
    arr[i] = TestStruct1(Float64(i), i, string(i))
    _writematfrostarray!(stream, Float64(i))
    _writematfrostarray!(stream, i)
    _writematfrostarray!(stream, string(i))
end

@test MATFrost._Read.read_matfrostarray!(stream, Matrix{TestStruct1}).x.x == arr

@test_opt MATFrost._Read.read_matfrostarray!(stream, Matrix{TestStruct1})
@test_call MATFrost._Read.read_matfrostarray!(stream, Matrix{TestStruct1})





# _writematfrostarray!(stream, 23)
# _writematfrostarray!(stream, 23.0)
# _writematfrostarray!(stream, Int32(23))





