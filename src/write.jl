
module _Write


import ..MATFrost._Stream: read!, write!, flush!, BufferedUDS

using .._Constants
using .._Types


@noinline function write_matfrostarray_empty!(socket::BufferedUDS, ::MATFrostArrayEmpty)
    write!(socket, DOUBLE)
    write!(socket, 1)
    write!(socket, 0)
end

@noinline function write_matfrostarray_primitive!(socket::BufferedUDS, marr::MATFrostArrayPrimitive{T}) where {T<: Number}
    write!(socket, matlab_type(T))
    write!(socket, length(marr.dims))
    for dim in marr.dims
        write!(socket, dim)
    end
    write!(socket, marr.values)
end

@noinline function write_matfrostarray_string!(socket::BufferedUDS, marr::MATFrostArrayString)
    write!(socket, MATLAB_STRING)
    write!(socket, length(marr.dims))
    for dim in marr.dims
        write!(socket, dim)
    end
    for s in marr.values
        write!(socket, s)
    end
end

@noinline function write_matfrostarray_cell!(socket::BufferedUDS, marr::MATFrostArrayCell)
    write!(socket, CELL)
    write!(socket, length(marr.dims))
    for dim in marr.dims
        write!(socket, dim)
    end

    for v in marr.values
        write_matfrostarray!(socket, v)
    end
end

@noinline function write_matfrostarray_struct!(socket::BufferedUDS, marr::MATFrostArrayStruct)
    write!(socket, STRUCT)
    write!(socket, length(marr.dims))
    for dim in marr.dims
        write!(socket, dim)
    end

    write!(socket, length(marr.fieldnames))
    for fn in marr.fieldnames
        write!(socket, String(fn))
    end

    for v in marr.values
        write_matfrostarray!(socket, v)
    end
end

@noinline function write_matfrostarray!(socket::BufferedUDS, @nospecialize(marr::MATFrostArrayAbstract))
    if marr isa MATFrostArrayEmpty
        write_matfrostarray_empty!(socket, marr)

    elseif marr isa MATFrostArrayStruct
        write_matfrostarray_struct!(socket, marr)

    elseif marr isa MATFrostArrayCell
        write_matfrostarray_cell!(socket, marr)

    elseif marr isa MATFrostArrayString
        write_matfrostarray_string!(socket, marr)
        
    elseif marr isa MATFrostArrayPrimitive{Bool}
        write_matfrostarray_primitive!(socket, marr)

    elseif marr isa MATFrostArrayPrimitive{Float64}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Float32}
        write_matfrostarray_primitive!(socket, marr)

    elseif marr isa MATFrostArrayPrimitive{Complex{Float64}}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Complex{Float32}}
        write_matfrostarray_primitive!(socket, marr)

    elseif marr isa MATFrostArrayPrimitive{Int8}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{UInt8}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Int16}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{UInt16}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Int32}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{UInt32}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Int64}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{UInt64}
        write_matfrostarray_primitive!(socket, marr)

    elseif marr isa MATFrostArrayPrimitive{Complex{Int8}}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Complex{UInt8}}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Complex{Int16}}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Complex{UInt16}}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Complex{Int32}}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Complex{UInt32}}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Complex{Int64}}
        write_matfrostarray_primitive!(socket, marr)
    elseif marr isa MATFrostArrayPrimitive{Complex{UInt64}}
        write_matfrostarray_primitive!(socket, marr)
    else
        error("Unrecoverable crash - MATFrost communication channel corrupted at write side")
    end


end


end