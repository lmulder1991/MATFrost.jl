
module _ConvertToMATLAB

using ..MATFrost: _MATFrostArray as MATFrostArray

import ..MATFrost._Stream: read!, write!, flush!, BufferedStream

mutable struct MATFrostArrayMemory{N, T, Nf}
    matfrostarray::MATFrostArray
    dims::NTuple{N, Csize_t}
    data::T
    fieldnames::NTuple{Nf, Cstring}

    function MATFrostArrayMemory{N, T, Nf}(type::Cint, dims::NTuple{N, Csize_t}, data::T, fieldnames::NTuple{Nf, Cstring}) where {N, T, Nf}
        mfam = new()
        mfam.dims = dims
        mfam.data = data
        mfam.fieldnames = fieldnames
        mfam.matfrostarray = MATFrostArray(
            type,
            N,
            pointer_from_objref(mfam) + fieldoffset(MATFrostArrayMemory{N, T, Nf}, 2),
            pointer_from_objref(mfam) + fieldoffset(MATFrostArrayMemory{N, T, Nf}, 3),
            Nf,
            pointer_from_objref(mfam) + fieldoffset(MATFrostArrayMemory{N, T, Nf}, 4)
        )
        mfam
    end
    function MATFrostArrayMemory{N, T, Nf}(type::Cint, dims::NTuple{N, Csize_t}, data::T, dataptr::Ptr{Cvoid}, fieldnames::NTuple{Nf, Cstring}) where {N, T, Nf}
        mfam = new()
        mfam.dims = dims
        mfam.data = data
        mfam.fieldnames = fieldnames
        mfam.matfrostarray = MATFrostArray(
            type, 
            N, 
            pointer_from_objref(mfam) + fieldoffset(MATFrostArrayMemory{N, T, Nf}, 2),
            dataptr,
            Nf,
            pointer_from_objref(mfam) + fieldoffset(MATFrostArrayMemory{N, T, Nf}, 4)
        )
        mfam
    end
end


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

const MFA_NULL = MATFrostArray(0, 0, 0, 0, 0, 0)

array_type(::Type{Bool}) = LOGICAL



array_type(::Type{Float64}) = DOUBLE
array_type(::Type{Float32}) = SINGLE

array_type(::Type{Int8})  = INT8
array_type(::Type{UInt8}) = UINT8
array_type(::Type{Int16})  = INT16
array_type(::Type{UInt16}) = UINT16
array_type(::Type{Int32})  = INT32
array_type(::Type{UInt32}) = UINT32
array_type(::Type{Int64})  = INT64
array_type(::Type{UInt64}) = UINT64

array_type(::Type{Complex{Float64}}) = COMPLEX_DOUBLE
array_type(::Type{Complex{Float32}}) = COMPLEX_SINGLE

array_type(::Type{Complex{Int8}})  = COMPLEX_INT8
array_type(::Type{Complex{UInt8}}) = COMPLEX_UINT8
array_type(::Type{Complex{Int16}})  = COMPLEX_INT16
array_type(::Type{Complex{UInt16}}) = COMPLEX_UINT16
array_type(::Type{Complex{Int32}})  = COMPLEX_INT32
array_type(::Type{Complex{UInt32}}) = COMPLEX_UINT32
array_type(::Type{Complex{Int64}})  = COMPLEX_INT64
array_type(::Type{Complex{UInt64}}) = COMPLEX_UINT64


function write_matlab!(io::BufferedStream, v::T) where{T <: Number}
    write!(io, array_type(T))
    write!(io, Int64(1))
    write!(io, Int64(1))
    write!(io, v)
    nothing
end

function write_matlab!(io::BufferedStream, arr::Array{T,N}) where{N, T <: Number}
    write!(io, array_type(T))
    write!(io, Int64(N))
    for i in 1:N
        write!(io, Int64(size(arr, i)))
    end
    write!(io, arr)
    nothing
end


function write_matlab!(io::BufferedStream, s::String)
    write!(io, MATLAB_STRING)
    write!(io, Int64(1))
    write!(io, Int64(1))

    write!(io, Int64(ncodeunits(s)))
    write!(io, pointer(s), Int64(ncodeunits(s)))
    nothing
end

function write_matlab!(io::BufferedStream, arr::Array{String,N}) where{N}
    write!(io, MATLAB_STRING)
    write!(io, Int64(N))
    for i in 1:N
        write!(io, Int64(size(arr, i)))
    end
    for s in arr
        write!(io, Int64(ncodeunits(s)))
        write!(io, pointer(s), Int64(ncodeunits(s)))
    end
    nothing
end

function write_matlab!(io::BufferedStream, structval::T) where {T}
    write!(io, STRUCT)
    write!(io, Int64(1)) # ndims
    write!(io, Int64(1)) # size dim1

    write!(io, Int64(length(fieldnames(T)))) # numfields
    
    for fieldname in fieldnames(T)
        fns = string(fieldname)
        write!(io, Int64(ncodeunits(fns)))
        write!(io, pointer(fns), Int64(ncodeunits(fns)))
    end

    for fieldname in fieldnames(T)
        write_matlab!(io, getfield(structval, fieldname))
    end
    nothing
end

function write_matlab!(io::BufferedStream, arr::Array{T,N}) where {T,N}
    write!(io, STRUCT)
    write!(io, Int64(N)) # ndims
    for i in 1:N
        write!(io, Int64(size(arr, i)))
    end

    write!(io, Int64(length(fieldnames(T)))) # numfields
    for fieldname in fieldnames(T)
        fns = string(fieldname)
        write!(io, Int64(ncodeunits(fns)))
        write!(io, pointer(fns), Int64(ncodeunits(fns)))
    end

    for el in arr
        for fieldname in fieldnames(T)
            write_matlab!(io, getfield(el, fieldname))
        end
    end
    nothing
end


function write_matlab!(io::BufferedStream, tup::T) where {T<:Tuple}
    write!(io, CELL)
    write!(io, Int64(1)) # ndims
    write!(io, Int64(length(tup))) # size dim1

    for el in tup
        write_matlab!(io, el)
    end
    nothing
end

# function write_matlab!(io::BufferedStream, t::T) where {T <: Tuple}
#     write!(io, CELL)
#     write!(io, Int64(length(fieldnames(T)))) # ndims
#     for i in 1:N
#         write!(io, Int64(size(arr, i)))
#     end

#     for el in arr
#         write_matlab!(io, el)
#     end

#     nothing
# end

end