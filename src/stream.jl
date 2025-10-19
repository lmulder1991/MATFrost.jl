

module _Stream

function read! end
function write! end
function flush! end

const AF_UNIX = Cint(1)
const SOCK_STREAM = Cint(1)
const SOMAXCONN = Cint(0x7fffffff)

const FD_TYPE = UInt64

const SOCKADDR_UN = @NamedTuple{sun_family::UInt16, sun_path::NTuple{256,UInt8}}

function uds_socket()
    @ccall "Ws2_32.dll".socket(
        AF_UNIX::Cint, 
        SOCK_STREAM::Cint, 
        Int32(0)::Cint)::FD_TYPE
end

function uds_init()
    wsadata=Ref{NTuple{408, UInt8}}()
    @ccall "Ws2_32.dll".WSAStartup(
        reinterpret(UInt16, (UInt8(2),UInt8(2)))::UInt16, 
        wsadata::Ref{NTuple{408, UInt8}})::Cint
end

function uds_bind(socket_fd::FD_TYPE, path::String)

    pathu8 = transcode(UInt8, path)

    sun_path = ntuple(Val{256}()) do i
        if i <= length(pathu8)
            pathu8[i]
        else
            UInt8(0)
        end 
    end
    
    socket_addr = SOCKADDR_UN((UInt16(AF_UNIX), sun_path))

    socket_addr_ref = Ref{SOCKADDR_UN}(socket_addr)
    @ccall "Ws2_32.dll".bind(
        socket_fd::FD_TYPE, 
        socket_addr_ref::Ref{SOCKADDR_UN}, 
        Cint(sizeof(SOCKADDR_UN))::Cint)::Cint
end

function uds_connect(socket_fd::FD_TYPE, path::String)
    pathu8 = transcode(UInt8, path)

    sun_path = ntuple(Val{256}()) do i
        if i <= length(pathu8)
            pathu8[i]
        else
            UInt8(0)
        end 
    end
    
    socket_addr = SOCKADDR_UN((UInt16(AF_UNIX), sun_path))
    socket_addr_ref = Ref{SOCKADDR_UN}(socket_addr)

    @ccall "Ws2_32.dll".connect(
        socket_fd::FD_TYPE, 
        socket_addr_ref::Ref{SOCKADDR_UN}, 
        Cint(sizeof(SOCKADDR_UN))::Cint)::Cint
end

function uds_listen(socket_fd::FD_TYPE)
    @ccall "Ws2_32.dll".listen(
        socket_fd::FD_TYPE, 
        SOMAXCONN::Cint)::Cint
end

function uds_accept(socket_fd::FD_TYPE)
    @ccall "Ws2_32.dll".accept(
        socket_fd::FD_TYPE,
        C_NULL::Ptr{Cvoid},
        C_NULL::Ptr{Cvoid})::FD_TYPE
end

function uds_read(socket_fd::FD_TYPE, data::Ptr{UInt8}, nb::Int64)
    @ccall "Ws2_32.dll".recv(
        socket_fd::FD_TYPE, 
        data::Ptr{UInt8}, 
        Cint(nb)::Cint,
        Cint(0)::Cint)::Cint
end

function uds_write(socket_fd::FD_TYPE, data::Ptr{UInt8}, nb::Int64)
    @ccall "Ws2_32.dll".send(
        socket_fd::FD_TYPE, 
        data::Ptr{UInt8}, 
        Cint(nb)::Cint,
        Cint(0)::Cint)::Cint
end


mutable struct Buffer
    data::Vector{UInt8}
    position::Int64
    available::Int64
end

struct BufferedUDS
    socket_fd::FD_TYPE
    input::Buffer
    output::Buffer
end

@noinline function flush!(socket::BufferedUDS)  
    out = socket.output
    while (out.available > out.position) 
        bw = uds_write(socket.socket_fd, pointer(out.data) + out.position, out.available - out.position)
        out.position += bw
    end
    out.position = 0
    out.available = 0
    nothing
end

@noinline function write!(socket::BufferedUDS, data::Ptr{UInt8}, nb::Int64)
    out = socket.output
    bw = min(length(out.data) - out.available, nb);
    Base.memcpy(pointer(out.data) + out.available, data, bw);
    out.available += bw

    if (bw >= nb) 
        return
    end

    flush!(socket)

    while (nb - bw >= length(out.data)) 
        bwn = uds_write(
            socket.socket_fd, 
            data + bw, 
            length(out.data))
        bw += bwn
    end

    if (bw < nb) 
        out.position  = 0
        out.available = nb - bw
        Base.memcpy(pointer(out.data), data+bw, out.available);
    end
    nothing
end

@noinline function write!(socket::BufferedUDS, v::T) where {T<:Number}
    out = socket.output

    if (length(out.data) - out.available < sizeof(T))
        flush!(socket)
    end

    unsafe_store!(reinterpret(Ptr{T}, pointer(out.data) + out.available), v)
    out.available += sizeof(T)

    nothing
end

@noinline function write!(socket::BufferedUDS, arr::Array{T}) where {T<:Number}
    write!(socket, reinterpret(Ptr{UInt8}, pointer(arr)), sizeof(T)*length(arr))
    nothing
end

@noinline function write!(socket::BufferedUDS, v::String)
    nb = ncodeunits(v)
    write!(socket, Int64(nb))
    write!(socket, pointer(v), nb)
    nothing
end

@noinline function read!(socket::BufferedUDS, data::Ptr{UInt8}, nb::Int64)
    in = socket.input
    br = 0
    while (br < nb)
        if (in.available - in.position > 0) 
            brn = min(in.available - in.position, nb - br)
            Base.memcpy(data + br, pointer(in.data) + in.position, brn)
            in.position += brn
            br += brn
        elseif (nb - br >= length(in.data))
            brn = uds_read(socket.socket_fd, data + br, length(in.data))
            br += brn
        else
            brn = uds_read(socket.socket_fd, pointer(in.data), length(in.data))
            in.position = 0
            in.available = brn
         end
    end
    nothing
end

@noinline function read!(socket::BufferedUDS, arr::Array{T}) where {T <: Number}
    read!(socket, reinterpret(Ptr{UInt8}, pointer(arr)), sizeof(T) * length(arr))
    arr
end

@noinline function read!(socket::BufferedUDS, ::Type{T}) :: T where {T <: Number}
    in = socket.input
    if in.available - in.position >= sizeof(T)
        v = unsafe_load(reinterpret(Ptr{T}, pointer(in.data) + in.position))
        in.position += sizeof(T)
        return v
    else
        v = Ref{T}()
        read!(socket, reinterpret(Ptr{UInt8}, pointer_from_objref(v)), sizeof(T))
        return v[]
    end
end

@noinline function read!(socket::BufferedUDS, ::Type{String}) :: String
    nb = read!(socket, Int64)
    sarr = Vector{UInt8}(undef, nb)
    read!(socket, sarr)
    transcode(String, sarr)
end


mutable struct BufferedStream
    handle::Ptr{Cvoid}
    buffer::Vector{UInt8}
    position::Int64
    available::Int64
end

@noinline function flush!(io::BufferedStream)  
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

@noinline function write!(io::BufferedStream, data::Ptr{UInt8}, nb::Int64)

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

@noinline function write!(io::BufferedStream, v::T) where {T<:Number}
    if (length(io.buffer) - io.available > sizeof(T))
        unsafe_store!(reinterpret(Ptr{T}, pointer(io.buffer) + io.available), v)
        io.available += sizeof(T)
    else
        vref = Ref{T}(v)
        write!(io, reinterpret(Ptr{UInt8}, pointer_from_objref(vref)), sizeof(T))
    end
    nothing
end


@noinline function write!(io::BufferedStream, arr::Array{T}) where {T<:Number}
    write!(io, reinterpret(Ptr{UInt8}, pointer(arr)), sizeof(T)*length(arr))
    nothing
end


@noinline function write!(io::BufferedStream, v::String)
    nb = ncodeunits(v)
    write!(io, Int64(nb))
    write!(io, pointer(v), nb)
    nothing
end


@noinline function read!(io::BufferedStream, data::Ptr{UInt8}, nb::Int64)
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


@noinline function read!(io::BufferedStream, arr::Array{T}) where {T <: Number}
    read!(io, reinterpret(Ptr{UInt8}, pointer(arr)), sizeof(T) * length(arr))
    arr
end

@noinline function read!(io::BufferedStream, ::Type{T}) :: T where {T <: Number}
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

@noinline function read!(io::BufferedStream, ::Type{String}) :: String
    nb = read!(io, Int64)
    sarr = Vector{UInt8}(undef, nb)
    read!(io, sarr)
    transcode(String, sarr)
end

const CLEAR_BUFFER = Vector{UInt8}(undef, 2 << 14) # This buffer is used to clear the MATFrost object transmitted over the PIPE.

@noinline function discard!(io::BufferedStream, nb::Int64)
    br = 0
    lbuf = length(CLEAR_BUFFER)
    pbuf = pointer(CLEAR_BUFFER)
    while (br < nb)
        brn = min(lbuf, nb-br)
        read!(io, pbuf, brn)
        br += brn
    end
    nothing
end




end