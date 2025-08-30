

"""
This file contains inefficiently written code to map julia objects to matfrostarray. 
Buffer is supposed to be big enough.
"""

"""
Write to buffer in a unsafe manner
"""
function _writebuffer!(io::BufferedStream, v::T) where T
    p = reinterpret(Ptr{T}, pointer(io.buffer) + io.available)
    unsafe_store!(p, v)
    io.available += sizeof(T)
end



function _writebuffer!(io::BufferedStream, s::String)
    _writebuffer!(io, ncodeunits(s))
    
    psrc = reinterpret(Ptr{UInt8}, pointer(s))
    pdest = pointer(io.buffer) + io.available

    Base.memcpy(pdest, psrc, ncodeunits(s))

    io.available += ncodeunits(s)

end



"""
Primitive arrays
"""
function _writebuffermatfrostarray!(io::BufferedStream, arr::Array{T,N}) where {T <: Number,N}
    _writebuffer!(io, expected_matlab_type(Array{T,N}))
    _writebuffer!(io, Int64(N))
    dims = size(arr)
    for dim in dims
        _writebuffer!(io, dim)
    end
    nb = length(arr) * sizeof(T)
    psrc = reinterpret(Ptr{UInt8}, pointer(arr))
    pdest = pointer(io.buffer) + io.available
    Base.memcpy(pdest, psrc, nb)
    io.available += nb
end

"""
String arrays
"""
function _writebuffermatfrostarray!(io::BufferedStream, arr::Array{String,N}) where {N}
    _writebuffer!(io, expected_matlab_type(Array{String,N}))
    _writebuffer!(io, Int64(N))
    dims = size(arr)
    for dim in dims
        _writebuffer!(io, dim)
    end
    for s in arr
        _writebuffer!(io,s)
    end
end


"""
Struct arrays and Named tuple arrays
"""
function _writebuffermatfrostarray!(io::BufferedStream, arr::Array{T,N}) where {T,N}
    _writebuffer!(io, expected_matlab_type(Array{T,N}))
    _writebuffer!(io, Int64(N))
    dims = size(arr)
    for dim in dims
        _writebuffer!(io, dim)
    end
    _writebuffer!(io, Int64(fieldcount(T)))
    for fn in fieldnames(T)
        _writebuffer!(io, String(fn))
    end
    for i in eachindex(arr)
        el = arr[i]
        for fn in fieldnames(T)
            _writebuffermatfrostarray!(io, getfield(el, fn))
        end

    end
end



"""
Tuple
"""
function _writebuffermatfrostarray!(io::BufferedStream, tup::T) where {T <: Tuple}
    _writebuffer!(io, expected_matlab_type(T))
    _writebuffer!(io, 1)
    _writebuffer!(io, length(tup))

    for el in tup
        _writebuffermatfrostarray!(io, el)
    end
    
end


"""
Tuple arrays and Array of arrays
"""
function _writebuffermatfrostarray!(io::BufferedStream, arr::Array{T,N}) where {T <: Union{Array, Tuple}, N}
    _writebuffer!(io, expected_matlab_type(Array{T,N}))
    _writebuffer!(io, Int64(N))
    dims = size(arr)
    for dim in dims
        _writebuffer!(io, dim)
    end
    for i in eachindex(arr)
        el = arr[i]
        _writebuffermatfrostarray!(io, el)
    end
end



"""
Map scalar to array
"""
function _writebuffermatfrostarray!(io::BufferedStream, v::T) where {T}
    _writebuffermatfrostarray!(io, T[v])
end




function _readbuffer!(io::BufferedStream, ::Type{T}) where T
    p = reinterpret(Ptr{T}, pointer(io.buffer) + io.position)
    io.position += sizeof(T)
    unsafe_load(p)
end

function _clearbuffer!(io)
    io.position = 0
    io.available =0 
end