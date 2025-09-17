
module _Write


import ..MATFrost._Stream: read!, write!, flush!, BufferedStream

using .._Constants



array_type(::Type{Bool}) = LOGICAL

array_type(::Type{String}) = MATLAB_STRING

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


array_type(::Type{<:Tuple}) = CELL

array_type(::Type{Array{T}}) where {T<:Union{Number, String}} = array_type(T)

array_type(::Type{Array{<:Array}}) = CELL
array_type(::Type{Array{<:Tuple}}) = CELL

array_type(::Type{T}) where T = STRUCT


function write_matfrostarray!(io::BufferedStream, v::T) where{T <: Union{Number, String}}
    write!(io, array_type(T))
    write!(io, Int64(1))
    write!(io, Int64(1))
    write!(io, v)
    nothing
end

function write_matfrostarray!(io::BufferedStream, arr::Array{T,N}) where{N, T <: Number}
    write!(io, array_type(T))
    write!(io, Int64(N))
    for i in 1:N
        write!(io, Int64(size(arr, i)))
    end
    write!(io, arr)
    nothing
end



function write_matfrostarray!(io::BufferedStream, arr::Array{String,N}) where{N}
    write!(io, MATLAB_STRING)
    write!(io, Int64(N))
    for i in 1:N
        write!(io, Int64(size(arr, i)))
    end
    for s in arr
        write!(io, s)
    end
    nothing
end

@generated function write_matfrostarray!(io::BufferedStream, structval::T) where {T}
    quote
        write!(io, STRUCT)
        write!(io, Int64(1)) # ndims
        write!(io, Int64(1)) # size dim1

        write!(io, Int64(fieldcount(T))) # numfields
        for fn in fieldnames(T)
            write!(io, String(fn))
        end

        $((
            :(write_matfrostarray!(io, structval.$fn))
            for fn in fieldnames(T)
        )...)
        nothing
    end
end

@generated function write_matfrostarray!(io::BufferedStream, arr::Array{T,N}) where {T,N}
    quote
        write!(io, STRUCT)
        write!(io, Int64(N)) # ndims
        for i in 1:N
            write!(io, Int64(size(arr, i)))
        end

        write!(io, Int64(fieldcount(T))) # numfields
        for fn in fieldnames(T)
            write!(io, String(fn))
        end

        for el in arr
            $((
                :(write_matfrostarray!(io, el.$fn))
                for fn in fieldnames(T)
            )...)
        end
        nothing
    end
end


@generated function write_matfrostarray!(io::BufferedStream, tup::T) where {T<:Tuple}
    quote 
        write!(io, CELL)
        write!(io, Int64(1)) # ndims
        write!(io, Int64(length(tup))) # size dim1

        for el in tup
            write_matfrostarray!(io, el)
        end
        nothing
    end
end


end