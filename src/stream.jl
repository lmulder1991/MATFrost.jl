

module _Stream

function read! end
function write! end
function flush! end


mutable struct BufferedStream
    handle::Ptr{Cvoid}
    buffer::Vector{UInt8}
    position::Int64
    available::Int64
end

function flush!(io::BufferedStream)  
    byteswritten = Ref{UInt32}()
    while (io.available > io.position) 

        @ccall "kernel32".WriteFile(
            io.handle::Ptr{Cvoid},
            (pointer(io.buffer)+io.position)::Ptr{Cvoid},
            Int32(io.available - io.position)::Cint,
            byteswritten::Ref{UInt32},
            C_NULL::Ptr{Cvoid})::Int32

        io.position += byteswritten[]
    end
    io.position = 0
    io.available = 0
    nothing
end

function write!(io::BufferedStream, data::Ptr{UInt8}, nb::Int64)

    bw = min(length(io.buffer) - io.available, nb);
    Base.memcpy(pointer(io.buffer) + io.available, data, bw);
    io.available += bw

    if (bw >= nb) 
        return
    end

    flush!(io)
    # p = pointer(io.buffer)
    byteswritten = Ref{UInt32}()
    while (nb - bw >= length(io.buffer))
        @ccall "kernel32".WriteFile(
            io.handle::Ptr{Cvoid},
            (data + bw)::Ptr{Cvoid},
            Int32(length(io.buffer))::Cint,
            byteswritten::Ref{UInt32},
            C_NULL::Ptr{Cvoid})::Int32
        bw += byteswritten[]
    end

    if (bw < nb) 
        io.position  = 0
        io.available = nb - bw
        Base.memcpy(pointer(io.buffer), data+bw, io.available);
    end
    nothing
end

function write!(io::BufferedStream, v::T) where {T<:Number}
    if (length(io.buffer) - io.available > sizeof(T))
        unsafe_store!(reinterpret(Ptr{T}, pointer(io.buffer) + io.available), v)
        io.available += sizeof(T)
    else
        vref = Ref{T}(v)
        write!(io, reinterpret(Ptr{UInt8}, pointer_from_objref(vref)), sizeof(T))
    end
    nothing
end


function write!(io::BufferedStream, arr::Array{T}) where {T<:Number}
    write!(io, reinterpret(Ptr{UInt8}, pointer(arr)), sizeof(T)*length(arr))
    nothing
end




function read!(io::BufferedStream, data::Ptr{UInt8}, nb::Int64)
    br = 0
    while (br < nb)
        if (io.available - io.position > 0) 
            brn = min(io.available - io.position , nb - br)
            Base.memcpy(data + br, pointer(io.buffer) + io.position, brn)
            io.position += brn
            br += brn
        elseif (nb - br >= length(io.buffer)) 
            bytesread = Ref{UInt32}()
            toread = min(length(io.buffer), nb - br)
            @ccall "kernel32".ReadFile(
                io.handle::Ptr{Cvoid},
                (data + br)::Ptr{Cvoid},
                Int32(toread)::Cint,
                bytesread::Ref{UInt32},
                C_NULL::Ptr{Cvoid})::Int32

            br += bytesread[]
        else
            bytesread = Ref{UInt32}()

            @ccall "kernel32".ReadFile(
                io.handle::Ptr{Cvoid},
                pointer(io.buffer)::Ptr{Cvoid},
                Int32(length(io.buffer))::Cint,
                bytesread::Ref{UInt32},
                C_NULL::Ptr{Cvoid})::Int32

            io.position = 0
            io.available = bytesread[]

         end
    end
    nothing
end


function read!(io::BufferedStream, arr::Array{T}) where {T <: Number}
    read!(io, reinterpret(Ptr{UInt8}, pointer(arr)), sizeof(T) * length(arr))
    nothing
end



function read!(io::BufferedStream, ::Type{T}) :: T where {T <: Number}
    if io.available - io.position >= sizeof(T)
        v = unsafe_load(reinterpret(Ptr{T}, pointer(io.buffer) + io.position))
        io.position += sizeof(T)
        return v
    else
        v = Ref{T}()
        read!(io, reinterpret(Ptr{UInt8}, pointer_from_objref(v)), sizeof(T))
        return v[]
    end
end




end