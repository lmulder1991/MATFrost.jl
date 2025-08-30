





const LOGICAL = Int32(0)

const CHAR = Int32(1)

const MATLAB_STRING = Int32(2)

const DOUBLE = Int32(3)
const SINGLE = Int32(4)

const INT8 = Int32(5)
const UINT8 = Int32(6)
const INT16 = Int32(7)
const UINT16 = Int32(8)
const INT32 = Int32(9)
const UINT32 = Int32(10)
const INT64 = Int32(11)
const UINT64 = Int32(12)

const COMPLEX_DOUBLE = Int32(13)
const COMPLEX_SINGLE = Int32(14)

const COMPLEX_INT8 = Int32(15)
const COMPLEX_UINT8 = Int32(16)
const COMPLEX_INT16 = Int32(17)
const COMPLEX_UINT16 = Int32(18)
const COMPLEX_INT32 = Int32(19)
const COMPLEX_UINT32 = Int32(20)
const COMPLEX_INT64 = Int32(21)
const COMPLEX_UINT64 = Int32(22)

const CELL = Int32(23)
const STRUCT = Int32(24)

const OBJECT = Int32(25)
const VALUE_OBJECT = Int32(26)
const HANDLE_OBJECT_REF = Int32(27)
const ENUM = Int32(28)
const SPARSE_LOGICAL = Int32(29)
const SPARSE_DOUBLE = Int32(30)
const SPARSE_COMPLEX_DOUBLE = Int32(31)



function array_type_name(type::Int32)
    if type == LOGICAL
        "logical"

    elseif type == CHAR
        "char"
    elseif type == MATLAB_STRING
        "string"

    elseif type == SINGLE
        "single"
    elseif type == DOUBLE
        "double"

    elseif type == INT8
        "int8"
    elseif type == UINT8
        "uint8"
    elseif type == INT16
        "int16"
    elseif type == UINT16
        "uint16"
    elseif type == INT32
        "int32"
    elseif type == UINT32
        "uint32"
    elseif type == INT64
        "int64"
    elseif type == UINT64
        "uint64"

    elseif type == COMPLEX_SINGLE
        "complex single"
    elseif type == COMPLEX_DOUBLE
        "complex double"

    elseif type == COMPLEX_INT8
        "complex int8"
    elseif type == COMPLEX_UINT8
        "complex uint8"
    elseif type == COMPLEX_INT16
        "complex int16"
    elseif type == COMPLEX_UINT16
        "complex uint16"
    elseif type == COMPLEX_INT32
        "complex int32"
    elseif type == COMPLEX_UINT32
        "complex uint32"
    elseif type == COMPLEX_INT64
        "complex int64"
    elseif type == COMPLEX_UINT64
        "complex uint64"

    elseif type == CELL
        "cell"
    elseif type == STRUCT
        "struct"
        
    elseif type == OBJECT
        "object"
    elseif type == VALUE_OBJECT
        "value object"
    elseif type == HANDLE_OBJECT_REF
        "handle object ref"
    elseif type == SPARSE_LOGICAL
        "sparse logical"
    elseif type == SPARSE_DOUBLE
        "sparse double"
    elseif type == SPARSE_COMPLEX_DOUBLE
        "sparse complex double"
    else
        "unknown"
    end
end

expected_matlab_type_name(::Type{T}) where {T} = "struct"

expected_matlab_type_name(::Type{T}) where {T<:Tuple} = "cell"
expected_matlab_type_name(::Type{T}) where {T<:Array{<:Union{Array,Tuple}}} = "cell"

expected_matlab_type_name(::Type{String}) = "string"

expected_matlab_type_name(::Type{Float32}) = "single"
expected_matlab_type_name(::Type{Float64}) = "double"

expected_matlab_type_name(::Type{UInt8})   = "uint8"
expected_matlab_type_name(::Type{Int8})    = "int8"
expected_matlab_type_name(::Type{UInt16})   = "uint16"
expected_matlab_type_name(::Type{Int16})    = "int16"
expected_matlab_type_name(::Type{UInt32})   = "uint32"
expected_matlab_type_name(::Type{Int32})    = "int32"
expected_matlab_type_name(::Type{UInt64})   = "uint64"
expected_matlab_type_name(::Type{Int64})    = "int64"

expected_matlab_type_name(::Type{Complex{Float32}}) = "complex single"
expected_matlab_type_name(::Type{Complex{Float64}}) = "complex double"

expected_matlab_type_name(::Type{Complex{UInt8}})   = "complex uint8"
expected_matlab_type_name(::Type{Complex{Int8}})    = "complex int8"
expected_matlab_type_name(::Type{Complex{UInt16}})   = "complex uint16"
expected_matlab_type_name(::Type{Complex{Int16}})    = "complex int16"
expected_matlab_type_name(::Type{Complex{UInt32}})   = "complex uint32"
expected_matlab_type_name(::Type{Complex{Int32}})    = "complex int32"
expected_matlab_type_name(::Type{Complex{UInt64}})   = "complex uint64"
expected_matlab_type_name(::Type{Complex{Int64}})    = "complex int64"

expected_matlab_type_name(::Type{Array{T, N}}) where {T <: Number, N} = expected_matlab_type_name(T)




expected_matlab_type(::Type{T}) where {T} = STRUCT

expected_matlab_type(::Type{T}) where {T<:Tuple} = CELL
expected_matlab_type(::Type{T}) where {T<:Array{<:Union{Array,Tuple}}} = CELL

expected_matlab_type(::Type{String}) = MATLAB_STRING

expected_matlab_type(::Type{Float32}) = SINGLE
expected_matlab_type(::Type{Float64}) = DOUBLE

expected_matlab_type(::Type{UInt8})   = UINT8
expected_matlab_type(::Type{Int8})    = INT8
expected_matlab_type(::Type{UInt16})   = UINT16
expected_matlab_type(::Type{Int16})    = INT16
expected_matlab_type(::Type{UInt32})   = UINT32
expected_matlab_type(::Type{Int32})    = INT32
expected_matlab_type(::Type{UInt64})   = UINT64
expected_matlab_type(::Type{Int64})    = INT64

expected_matlab_type(::Type{Complex{Float32}}) = COMPLEX_SINGLE
expected_matlab_type(::Type{Complex{Float64}}) = COMPLEX_DOUBLE

expected_matlab_type(::Type{Complex{UInt8}})   = COMPLEX_UINT8
expected_matlab_type(::Type{Complex{Int8}})    = COMPLEX_INT8
expected_matlab_type(::Type{Complex{UInt16}})   = COMPLEX_UINT16
expected_matlab_type(::Type{Complex{Int16}})    = COMPLEX_INT16
expected_matlab_type(::Type{Complex{UInt32}})   = COMPLEX_UINT32
expected_matlab_type(::Type{Complex{Int32}})    = COMPLEX_INT32
expected_matlab_type(::Type{Complex{UInt64}})   = COMPLEX_UINT64
expected_matlab_type(::Type{Complex{Int64}})    = COMPLEX_INT64

expected_matlab_type(::Type{Array{T, N}}) where {T <: Number, N} = expected_matlab_type(T)


const PRIMITIVE_TYPES_AND_SIZE = (
    (LOGICAL, 1), 
    (DOUBLE, 8), (SINGLE, 4), 
    (INT8, 1), (UINT8, 1), (INT16, 2), (UINT16,2), (INT32,4), (UINT32,4), (INT64,8), (UINT64,8),
    (COMPLEX_DOUBLE, 16), (COMPLEX_SINGLE,8),
    (COMPLEX_INT8, 2), (COMPLEX_UINT8, 2), (COMPLEX_INT16, 4), (COMPLEX_UINT16,4), (COMPLEX_INT32,8), (COMPLEX_UINT32,8), (COMPLEX_INT64,16), (COMPLEX_UINT64,16),
)
