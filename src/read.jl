module _Read

import ..MATFrost._Stream: read!, write!, flush!, discard!, BufferedUDS
using .._Types
using .._Constants



struct MATFrostArrayHeader
    type :: Int32
    dims :: Vector{Int64}
    nel  :: Int64
end

function read_string!(socket::BufferedUDS) :: String
    nb = read!(socket, Int64)
    sarr = Vector{UInt8}(undef, nb)
    read!(socket, sarr)
    transcode(String, sarr)
end

function read_matfrostarray_header!(socket::BufferedUDS) :: MATFrostArrayHeader
    type = read!(socket, Int32)
    ndims = read!(socket, Int64)
    dims = Int64[read!(socket, Int64) for _ in 1:ndims]
    nel  = prod(dims; init=1)
    MATFrostArrayHeader(type, dims, nel)
end

@noinline function read_matfrostarray_primitive!(socket::BufferedUDS, header::MATFrostArrayHeader, ::Type{T}) :: MATFrostArrayPrimitive{T}  where {T<:Number}
    values = Vector{T}(undef, header.nel)
    read!(socket, values)
    MATFrostArrayPrimitive{T}(header.dims, values)
end

@noinline function read_matfrostarray_string!(socket::BufferedUDS, header::MATFrostArrayHeader) :: MATFrostArrayString
    values = String[read_string!(socket) for _ in 1:header.nel]
    MATFrostArrayString(header.dims, values)
end

@noinline function read_matfrostarray_struct!(socket::BufferedUDS, header::MATFrostArrayHeader)::MATFrostArrayStruct
    nfields = read!(socket, Int64)
    fns = Symbol[Symbol(read_string!(socket)) for _ in 1:nfields]
    
    values = MATFrostArrayAbstract[
        read_matfrostarray!(socket) for _ in 1:(nfields*header.nel)
    ]

    MATFrostArrayStruct(header.dims, fns, values)
end

@noinline function read_matfrostarray_cell!(socket::BufferedUDS, header::MATFrostArrayHeader)::MATFrostArrayCell
    values = MATFrostArrayAbstract[
        read_matfrostarray!(socket) for _ in 1:header.nel
    ]
    MATFrostArrayCell(header.dims, values)
    
end

@noinline function read_matfrostarray!(socket::BufferedUDS) :: MATFrostArrayAbstract
    header = read_matfrostarray_header!(socket)

    if header.nel == 0
        if header.type == STRUCT
            nfields = read!(socket, Int64)
            for _ in 1:nfields
                nb = read!(socket, Int64)
                discard!(socket, nb)
            end
        end
        return MATFrostArrayEmpty()
    end


    if header.type == STRUCT
        read_matfrostarray_struct!(socket, header)

    elseif header.type == CELL
        read_matfrostarray_cell!(socket, header)

    elseif header.type == MATLAB_STRING
        read_matfrostarray_string!(socket, header)
        
    elseif header.type == LOGICAL
        read_matfrostarray_primitive!(socket, header, Bool)

    elseif header.type == DOUBLE
        read_matfrostarray_primitive!(socket, header, Float64)
    elseif header.type == SINGLE
        read_matfrostarray_primitive!(socket, header, Float32)

    elseif header.type == COMPLEX_DOUBLE
        read_matfrostarray_primitive!(socket, header, Complex{Float64})
    elseif header.type == COMPLEX_SINGLE
        read_matfrostarray_primitive!(socket, header, Complex{Float32})

    elseif header.type == INT8
        read_matfrostarray_primitive!(socket, header, Int8)
    elseif header.type == UINT8
        read_matfrostarray_primitive!(socket, header, UInt8)
    elseif header.type == INT16
        read_matfrostarray_primitive!(socket, header, Int16)
    elseif header.type == UINT16
        read_matfrostarray_primitive!(socket, header, UInt16)
    elseif header.type == INT32
        read_matfrostarray_primitive!(socket, header, Int32)
    elseif header.type == UINT32
        read_matfrostarray_primitive!(socket, header, UInt32)
    elseif header.type == INT64
        read_matfrostarray_primitive!(socket, header, Int64)
    elseif header.type == UINT64
        read_matfrostarray_primitive!(socket, header, UInt64)

    elseif header.type == COMPLEX_INT8
        read_matfrostarray_primitive!(socket, header, Complex{Int8})
    elseif header.type == COMPLEX_UINT8
        read_matfrostarray_primitive!(socket, header, Complex{UInt8})
    elseif header.type == COMPLEX_INT16
        read_matfrostarray_primitive!(socket, header, Complex{Int16})
    elseif header.type == COMPLEX_UINT16
        read_matfrostarray_primitive!(socket, header, Complex{UInt16})
    elseif header.type == COMPLEX_INT32
        read_matfrostarray_primitive!(socket, header, Complex{Int32})
    elseif header.type == COMPLEX_UINT32
        read_matfrostarray_primitive!(socket, header, Complex{UInt32})
    elseif header.type == COMPLEX_INT64
        read_matfrostarray_primitive!(socket, header, Complex{Int64})
    elseif header.type == COMPLEX_UINT64
        read_matfrostarray_primitive!(socket, header, Complex{UInt64})
    else
        error("Unrecoverable crash - MATFrost communication channel corrupted at read side")
    end

end



end