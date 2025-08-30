"""
Write buffer is a simple 
"""
function _writebuffer!(io::BufferedStream, v::T) where T
    p = reinterpret(Ptr{T}, pointer(io.buffer) + io.available)
    unsafe_store!(p, v)
    io.available += sizeof(T)
end

# function _writebuffer!(io::MATFrost._Stream.BufferedStream, v::String)
#     p = reinterpret(Ptr{T}, pointer(io.buffer) + io.available)
#     unsafe_store!(p, v)
#     io.available += sizeof(T)
# end

function _writebuffer!(io::BufferedStream, s::String)
    _writebuffer!(io, ncodeunits(s))
    
    psrc = reinterpret(Ptr{UInt8}, pointer(s))
    pdest = pointer(io.buffer) + io.available

    Base.memcpy(pdest, psrc, ncodeunits(s))

    io.available += ncodeunits(s)

end


function _writebuffermatfrostarray!(io::BufferedStream, v::T) where {T <: Union{Number, String}}
    _writebuffer!(io, expected_matlab_type(T))
    _writebuffer!(io, 1)
    _writebuffer!(io, 1)
    _writebuffer!(io, v)
end



function _writebuffermatfrostarray!(io::BufferedStream, arr::Array{T,N}) where {T <: Number,N}
    _writebuffer!(io, expected_matlab_type(Array{T,N}))
    _writebuffer!(io, N)
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

function _writebuffermatfrostarray!(io::BufferedStream, arr::Array{String,N}) where {N}
    _writebuffer!(io, expected_matlab_type(Array{String,N}))
    _writebuffer!(io, N)
    dims = size(arr)
    for dim in dims
        _writebuffer!(io, dim)
    end
    for s in arr
        _writebuffer!(io,s)
    end
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