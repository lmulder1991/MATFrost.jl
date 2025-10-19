
module _Write


import ..MATFrost._Stream: read!, write!, flush!, BufferedUDS

using .._Constants


function write_matfrostarray!(socket::BufferedUDS, v::T) where{T <: Union{Number, String}}
    write!(socket, matlab_type(T))
    write!(socket, Int64(1))
    write!(socket, Int64(1))
    write!(socket, v)
    nothing
end

function write_matfrostarray!(socket::BufferedUDS, arr::Array{T,N}) where{N, T <: Number}
    write!(socket, matlab_type(T))
    write!(socket, Int64(N))
    for i in 1:N
        write!(socket, Int64(size(arr, i)))
    end
    write!(socket, arr)
    nothing
end


function write_matfrostarray!(socket::BufferedUDS, arr::Array{String,N}) where{N}
    write!(socket, MATLAB_STRING)
    write!(socket, Int64(N))
    for i in 1:N
        write!(socket, Int64(size(arr, i)))
    end
    for s in arr
        write!(socket, s)
    end
    nothing
end

@generated function write_matfrostarray!(socket::BufferedUDS, structval::T) where {T}
    quote
        write!(socket, STRUCT)
        write!(socket, Int64(1)) # ndims
        write!(socket, Int64(1)) # size dim1

        write!(socket, Int64(fieldcount(T))) # numfields
        for fn in fieldnames(T)
            write!(socket, String(fn))
        end

        $((
            :(write_matfrostarray!(socket, structval.$fn))
            for fn in fieldnames(T)
        )...)
        nothing
    end
end

@generated function write_matfrostarray!(socket::BufferedUDS, arr::Array{T,N}) where {T,N}
    if isstructtype(T)
        quote
            write!(socket, STRUCT)
            write!(socket, Int64(N)) # ndims
            for i in 1:N
                write!(socket, Int64(size(arr, i)))
            end

            write!(socket, Int64(fieldcount(T))) # numfields
            for fn in fieldnames(T)
                write!(socket, String(fn))
            end

            for el in arr
                $((
                    :(write_matfrostarray!(socket, el.$fn))
                    for fn in fieldnames(T)
                )...)
            end
            nothing
        end
    else
        quote
            write!(socket, CELL)
            write!(socket, Int64(N)) # ndims
            for i in 1:N
                write!(socket, Int64(size(arr, i)))
            end
        
            for el in arr
                write_matfrostarray!(socket, el)
            end
            nothing
        end
    end
end


@generated function write_matfrostarray!(socket::BufferedUDS, tup::T) where {T<:Tuple}
    quote 
        write!(socket, CELL)
        write!(socket, Int64(1)) # ndims
        write!(socket, Int64(length(tup))) # size dim1

        for el in tup
            write_matfrostarray!(socket, el)
        end
        nothing
    end
end

@generated function write_matfrostarray!(socket::BufferedUDS, arr::Array{T,N}) where {T<:Union{Array, Tuple}, N}
    quote 
        write!(socket, CELL)
        write!(socket, Int64(N)) # ndims
        for i in 1:N
            write!(socket, Int64(size(arr, i)))
        end
      
        for el in arr
            write_matfrostarray!(socket, el)
        end
        nothing
    end
end



end