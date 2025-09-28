
using MATFrost: MATFrost,  _Stream.BufferedStream as BufferedStream, _Read2.read_matfrostarray! as read_matfrostarray!
using MATFrost._Types
using Test
using JET

include("types.jl")
include("readwrite.jl")
# include("primitives.jl")
include("composites.jl")
# include("incompatible_datatypes.jl")
# include("read.jl")
# stream = MATFrost._Stream.BufferedStream(C_NULL, Vector{UInt8}(undef, 2 << 16), 0, 0)


# struct TestStruct1
#     a::Float64
#     b::Int64
#     d::String
# end


# # @test_opt  MATFrost._Read.incompatible_datatypes_exception(TestStruct1, Int32(23))
# # @test_call MATFrost._Read.incompatible_datatypes_exception(TestStruct1, Int32(23))

# # @test_opt MATFrost._Read.incompatible_array_dimensions_exception(Array{TestStruct1,2}, Int64[2,3,4])
# # @test_call MATFrost._Read.incompatible_array_dimensions_exception(Array{TestStruct1,2}, Int64[2,3,4])

# # @test_opt MATFrost._Read.not_scalar_value_exception(Array{TestStruct1,2}, Int64[2,3,4])
# # @test_call MATFrost._Read.not_scalar_value_exception(Array{TestStruct1,2}, Int64[2,3,4])

# # @test_opt MATFrost._Read.missing_fields_exception(Array{TestStruct1,2}, Symbol[:a,:b])
# # @test_call MATFrost._Read.missing_fields_exception(Array{TestStruct1,2}, Symbol[:a,:b])


# # @test_opt MATFrost._Read.additional_fields_exception(Array{TestStruct1,2}, Symbol[:a,:b])
# # @test_call MATFrost._Read.additional_fields_exception(Array{TestStruct1,2}, Symbol[:a,:b])




# _clearbuffer!(stream)
# _writebuffer!(stream, MATFrost._Read.CELL)
# _writebuffer!(stream, 1)
# _writebuffer!(stream, 3)
# _writebuffermatfrostarray!(stream, 23)
# _writebuffermatfrostarray!(stream, 23.0)
# _writebuffermatfrostarray!(stream, Int32(23))

# @test MATFrost._Read.read_matfrostarray!(stream,Tuple{Int64, Float64, Int32}).x.x == (23, 23.0, Int32(23))

# # @test_opt MATFrost._Read.read_matfrostarray!(stream, Tuple{Int64, Float64, Int32})
# # @test_call MATFrost._Read.read_matfrostarray!(stream, Tuple{Int64, Float64, Int32})







# _clearbuffer!(stream)
# _writebuffermatfrostarray!(stream, "TestingString")
# @test MATFrost._Read.read_matfrostarray!(stream, String).x.x == "TestingString"




# _clearbuffer!(stream)
# _writebuffer!(stream, MATFrost._Read.STRUCT)
# _writebuffer!(stream, 1) # ndims
# _writebuffer!(stream, 1) # dim1
# _writebuffer!(stream, 3) # nfields
# _writebuffer!(stream, "a")
# _writebuffer!(stream, "b")
# _writebuffer!(stream, "d")
# _writebuffermatfrostarray!(stream, 321.0)
# _writebuffermatfrostarray!(stream, 321)
# _writebuffermatfrostarray!(stream, "321")

# @test MATFrost._Read.read_matfrostarray!(stream, TestStruct1).x.x == TestStruct1(321.0, 321, "321")
# @test_opt MATFrost._Read.read_matfrostarray!(stream,  TestStruct1)
# @test_call MATFrost._Read.read_matfrostarray!(stream, TestStruct1)






# _clearbuffer!(stream)
# _writebuffer!(stream, MATFrost._Read.STRUCT)
# _writebuffer!(stream, 2) # ndims
# _writebuffer!(stream, 3) # dim1
# _writebuffer!(stream, 4) # dim2
# _writebuffer!(stream, 3) # nfields
# _writebuffer!(stream, "a")
# _writebuffer!(stream, "b")
# _writebuffer!(stream, "d")

# arr = Matrix{TestStruct1}(undef, 3, 4)
# for i in 1:12
#     arr[i] = TestStruct1(Float64(i), i, string(i))
#     _writebuffermatfrostarray!(stream, Float64(i))
#     _writebuffermatfrostarray!(stream, i)
#     _writebuffermatfrostarray!(stream, string(i))
# end

# @test MATFrost._Read.read_matfrostarray!(stream, Matrix{TestStruct1}).x.x == arr

# @test_opt MATFrost._Read.read_matfrostarray!(stream, Matrix{TestStruct1})
# @test_call MATFrost._Read.read_matfrostarray!(stream, Matrix{TestStruct1})





# _writebuffermatfrostarray!(stream, 23)
# _writebuffermatfrostarray!(stream, 23.0)
# _writebuffermatfrostarray!(stream, Int32(23))





