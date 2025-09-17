module _Constants

export LOGICAL, CHAR, MATLAB_STRING,
    DOUBLE, SINGLE,
    INT8, UINT8, INT16, UINT16, INT32, UINT32, INT64, UINT64,
    COMPLEX_DOUBLE, COMPLEX_SINGLE,
    COMPLEX_INT8, COMPLEX_UINT8, COMPLEX_INT16, COMPLEX_UINT16,
    COMPLEX_INT32, COMPLEX_UINT32, COMPLEX_INT64, COMPLEX_UINT64,
    CELL, STRUCT, 
    OBJECT, VALUE_OBJECT, HANDLE_OBJECT_REF, ENUM, 
    SPARSE_LOGICAL, SPARSE_DOUBLE, SPARSE_COMPLEX_DOUBLE,
    mapped_matlab_type,
    matlab_type_name


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



mapped_matlab_type(::Type{T}) where {T} = STRUCT

mapped_matlab_type(::Type{T}) where {T<:Tuple} = CELL
mapped_matlab_type(::Type{T}) where {T<:Array{<:Union{Array,Tuple}}} = CELL

mapped_matlab_type(::Type{String}) = MATLAB_STRING

mapped_matlab_type(::Type{Float32}) = SINGLE
mapped_matlab_type(::Type{Float64}) = DOUBLE

mapped_matlab_type(::Type{UInt8})   = UINT8
mapped_matlab_type(::Type{Int8})    = INT8
mapped_matlab_type(::Type{UInt16})   = UINT16
mapped_matlab_type(::Type{Int16})    = INT16
mapped_matlab_type(::Type{UInt32})   = UINT32
mapped_matlab_type(::Type{Int32})    = INT32
mapped_matlab_type(::Type{UInt64})   = UINT64
mapped_matlab_type(::Type{Int64})    = INT64

mapped_matlab_type(::Type{Complex{Float32}}) = COMPLEX_SINGLE
mapped_matlab_type(::Type{Complex{Float64}}) = COMPLEX_DOUBLE

mapped_matlab_type(::Type{Complex{UInt8}})   = COMPLEX_UINT8
mapped_matlab_type(::Type{Complex{Int8}})    = COMPLEX_INT8
mapped_matlab_type(::Type{Complex{UInt16}})   = COMPLEX_UINT16
mapped_matlab_type(::Type{Complex{Int16}})    = COMPLEX_INT16
mapped_matlab_type(::Type{Complex{UInt32}})   = COMPLEX_UINT32
mapped_matlab_type(::Type{Complex{Int32}})    = COMPLEX_INT32
mapped_matlab_type(::Type{Complex{UInt64}})   = COMPLEX_UINT64
mapped_matlab_type(::Type{Complex{Int64}})    = COMPLEX_INT64

mapped_matlab_type(::Type{Array{T, N}}) where {T <: Union{Number, String}, N} = mapped_matlab_type(T)


function matlab_type_name(type::Int32)
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

end