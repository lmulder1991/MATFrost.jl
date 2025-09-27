
module _Write


import ..MATFrost._Stream: read!, write!, flush!, BufferedStream

using .._Constants


function write_matfrostarray!(io::BufferedStream, v::T) where{T <: Union{Number, String}}
    write!(io, mapped_matlab_type(T))
    write!(io, Int64(1))
    write!(io, Int64(1))
    write!(io, v)
    nothing
end

function write_matfrostarray!(io::BufferedStream, arr::Array{T,N}) where{N, T <: Number}
    write!(io, mapped_matlab_type(T))
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
    if isstructtype(T)
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
    else
        quote
            write!(io, CELL)
            write!(io, Int64(N)) # ndims
            for i in 1:N
                write!(io, Int64(size(arr, i)))
            end
        
            for el in arr
                write_matfrostarray!(io, el)
            end
            nothing
        end
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

@generated function write_matfrostarray!(io::BufferedStream, arr::Array{T,N}) where {T<:Union{Array, Tuple}, N}
    quote 
        write!(io, CELL)
        write!(io, Int64(N)) # ndims
        for i in 1:N
            write!(io, Int64(size(arr, i)))
        end
      
        for el in arr
            write_matfrostarray!(io, el)
        end
        nothing
    end
end



end