module _Read


import ..MATFrost._Stream: read!, write!, flush!, BufferedStream, discard!

using ..MATFrost: _MATFrostException as MATFrostException
# using ..MATFrost: _MATFrostArray as MATFrostArray
# using ..MATFrost: _MATFrostException as MATFrostException
# using ..MATFrost._Stream: BufferedStream, 

# function new_array(::Type{T}, dims::Ptr{Csize_t}, nel::Csize_t) where {T}
#     T(undef, ntuple(i -> ifelse(i <= nel, unsafe_load(dims, i), Csize_t(1)), ndims(T)))
# end

struct MATFrostArrayHeader{N}
    type  :: Int32
    ndims :: Int64
    nel   :: Int64            # Total number of elements in array.
    dims1 :: NTuple{N, Int64} # The first N-dimensions of array
    dims2 :: NTuple{4, Int64} # Dimensions (N+1):(N+4) of array. 
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



function array_type_name(type::Int32)
    if type == LOGICAL
        "logical"

    elseif type == CHAR
        "char"
    elseif type == MATLAB_STRING
        "string"

    elseif type == SINGLE
        "single"
    elseif type == DOUBLE
        "double"

    elseif type == INT8
        "int8"
    elseif type == UINT8
        "uint8"
    elseif type == INT16
        "int16"
    elseif type == UINT16
        "uint16"
    elseif type == INT32
        "int32"
    elseif type == UINT32
        "uint32"
    elseif type == INT64
        "int64"
    elseif type == UINT64
        "uint64"

    elseif type == COMPLEX_SINGLE
        "complex single"
    elseif type == COMPLEX_DOUBLE
        "complex double"

    elseif type == COMPLEX_INT8
        "complex int8"
    elseif type == COMPLEX_UINT8
        "complex uint8"
    elseif type == COMPLEX_INT16
        "complex int16"
    elseif type == COMPLEX_UINT16
        "complex uint16"
    elseif type == COMPLEX_INT32
        "complex int32"
    elseif type == COMPLEX_UINT32
        "complex uint32"
    elseif type == COMPLEX_INT64
        "complex int64"
    elseif type == COMPLEX_UINT64
        "complex uint64"

    elseif type == CELL
        "cell"
    elseif type == STRUCT
        "struct"
        
    elseif type == OBJECT
        "object"
    elseif type == VALUE_OBJECT
        "value object"
    elseif type == HANDLE_OBJECT_REF
        "handle object ref"
    elseif type == SPARSE_LOGICAL
        "sparse logical"
    elseif type == SPARSE_DOUBLE
        "sparse double"
    elseif type == SPARSE_COMPLEX_DOUBLE
        "sparse complex double"
    else
        "unknown"
    end
end

expected_matlab_type_name(::Type{T}) where {T} = "struct"

expected_matlab_type_name(::Type{T}) where {T<:Tuple} = "cell"
expected_matlab_type_name(::Type{T}) where {T<:Array{<:Union{Array,Tuple}}} = "cell"

expected_matlab_type_name(::Type{String}) = "string"

expected_matlab_type_name(::Type{Float32}) = "single"
expected_matlab_type_name(::Type{Float64}) = "double"

expected_matlab_type_name(::Type{UInt8})   = "uint8"
expected_matlab_type_name(::Type{Int8})    = "int8"
expected_matlab_type_name(::Type{UInt16})   = "uint16"
expected_matlab_type_name(::Type{Int16})    = "int16"
expected_matlab_type_name(::Type{UInt32})   = "uint32"
expected_matlab_type_name(::Type{Int32})    = "int32"
expected_matlab_type_name(::Type{UInt64})   = "uint64"
expected_matlab_type_name(::Type{Int64})    = "int64"

expected_matlab_type_name(::Type{Complex{Float32}}) = "complex single"
expected_matlab_type_name(::Type{Complex{Float64}}) = "complex double"

expected_matlab_type_name(::Type{Complex{UInt8}})   = "complex uint8"
expected_matlab_type_name(::Type{Complex{Int8}})    = "complex int8"
expected_matlab_type_name(::Type{Complex{UInt16}})   = "complex uint16"
expected_matlab_type_name(::Type{Complex{Int16}})    = "complex int16"
expected_matlab_type_name(::Type{Complex{UInt32}})   = "complex uint32"
expected_matlab_type_name(::Type{Complex{Int32}})    = "complex int32"
expected_matlab_type_name(::Type{Complex{UInt64}})   = "complex uint64"
expected_matlab_type_name(::Type{Complex{Int64}})    = "complex int64"

expected_matlab_type_name(::Type{Array{T, N}}) where {T <: Number, N} = expected_matlab_type_name(T)




expected_matlab_type(::Type{T}) where {T} = STRUCT

expected_matlab_type(::Type{T}) where {T<:Tuple} = CELL
expected_matlab_type(::Type{T}) where {T<:Array{<:Union{Array,Tuple}}} = CELL

expected_matlab_type(::Type{String}) = MATLAB_STRING

expected_matlab_type(::Type{Float32}) = SINGLE
expected_matlab_type(::Type{Float64}) = DOUBLE

expected_matlab_type(::Type{UInt8})   = UINT8
expected_matlab_type(::Type{Int8})    = INT8
expected_matlab_type(::Type{UInt16})   = UINT16
expected_matlab_type(::Type{Int16})    = INT16
expected_matlab_type(::Type{UInt32})   = UINT32
expected_matlab_type(::Type{Int32})    = INT32
expected_matlab_type(::Type{UInt64})   = UINT64
expected_matlab_type(::Type{Int64})    = INT64

expected_matlab_type(::Type{Complex{Float32}}) = COMPLEX_SINGLE
expected_matlab_type(::Type{Complex{Float64}}) = COMPLEX_DOUBLE

expected_matlab_type(::Type{Complex{UInt8}})   = COMPLEX_UINT8
expected_matlab_type(::Type{Complex{Int8}})    = COMPLEX_INT8
expected_matlab_type(::Type{Complex{UInt16}})   = COMPLEX_UINT16
expected_matlab_type(::Type{Complex{Int16}})    = COMPLEX_INT16
expected_matlab_type(::Type{Complex{UInt32}})   = COMPLEX_UINT32
expected_matlab_type(::Type{Complex{Int32}})    = COMPLEX_INT32
expected_matlab_type(::Type{Complex{UInt64}})   = COMPLEX_UINT64
expected_matlab_type(::Type{Complex{Int64}})    = COMPLEX_INT64

expected_matlab_type(::Type{Array{T, N}}) where {T <: Number, N} = expected_matlab_type(T)


const PRIMITIVE_TYPES_AND_SIZE = (
    (LOGICAL, 1), 
    (DOUBLE, 8), (SINGLE, 4), 
    (INT8, 1), (UINT8, 1), (INT16, 2), (UINT16,2), (INT32,4), (UINT32,4), (INT64,8), (UINT64,8),
    (COMPLEX_DOUBLE, 16), (COMPLEX_SINGLE,8),
    (COMPLEX_INT8, 2), (COMPLEX_UINT8, 2), (COMPLEX_INT16, 4), (COMPLEX_UINT16,4), (COMPLEX_INT32,8), (COMPLEX_UINT32,8), (COMPLEX_INT64,16), (COMPLEX_UINT64,16),
)


function read_string!(io::BufferedStream) :: String
    sarr = Vector{UInt8}(undef, read!(io, Int64))
    read!(io, sarr)
    transcode(String, sarr)
end




"""
This function will read a specified number of matfrostarray objects from stream and discard the data.
Used in cases of errors to keep the connection state correct.
"""
function discard_matfrostarray!(io::BufferedStream, numobjects::Int64 = 1)
    while numobjects > 0
        type = read!(io, Int32)
        ndims = read!(io, Int64)
        nel = 1

        for _ in 1:ndims
            nel *= read!(io, Int64)
        end

        if type == STRUCT
            nfields = read!(io, Int64)
            for _ in 1:nfields
                nb = read!(io, Int64)
                discard!(io, nb)
            end
            numobjects += nfields * nel
        elseif type == CELL
            numobjects += nel
        elseif type == MATLAB_STRING
            for _ in 1:nel
                nb = read!(io, Int64)
                discard!(io, nb)
            end
        else
            for (prim_type, prim_size) in PRIMITIVE_TYPES_AND_SIZE
                if prim_type == type
                    nb = prim_size*nel
                    discard!(io, nb)
                end
            end
        end
        
        numobjects -= 1
    end
    nothing
end

"""
Discard a matfrostarray with a stream that has read the header and will
start from the body of a matfrostarray.

NOTE: Very similar to `discard_matfrostarray`
"""
function discard_matfrostarray_body!(io::BufferedStream, type::Int32, nel::Int64)
    if type == STRUCT
        nfields = read!(io, Int64)
        for _ in 1:nfields
            nb = read!(io, Int64)
            discard!(io, nb)
        end
        discard_matfrostarray!(io, nfields * nel)
    elseif type == CELL
        discard_matfrostarray!(io, nel)
    elseif type == MATLAB_STRING
        for _ in 1:nel
            nb = read!(io, Int64)
            discard!(io, nb)
        end
    else
        for (prim_type, prim_size) in PRIMITIVE_TYPES_AND_SIZE
            if prim_type == type
                nb = prim_size*nel
                discard!(io, nb)
            end
        end
    end
    nothing
end

function discard_matfrostarray_body!(io::BufferedStream, header::MATFrostArrayHeader) 
    discard_matfrostarray_body!(io, header.type, header.nel)
end


function read_matfrostarray_header3!(io::BufferedStream, ::Val{N}) :: MATFrostArrayHeader{N} where {N}
    type = read!(io, Int32)
   
    ndims = read!(io, Int64)

    dims1 = ntuple(Val{N}()) do i
        if i <= ndims
            return read!(io, Int64)
        else
            return 1
        end
    end

    dims2 = ntuple(Val{4}()) do i
        if (i+N) <= ndims
            return read!(io, Int64)
        else
            return 1
        end
    end
    
    nel = prod(dims1; init=1)*prod(dims2)

    for _ in (N+4+1):ndims
        dim = read!(io, Int64)
        nel *= dim
    end

    MATFrostArrayHeader{N}(type, ndims, nel, dims1, dims2)
end


function incompatible_datatypes_exception(::Type{T}, type::Int32) where {T}
    MATFrostException(
        "matfrostjulia:conversion:incompatibleDatatypes",
"""
Converting to: $(T) 

Incompatible datatypes conversion:
    Actual MATLAB type:   $(array_type_name(type))[]
    Expected MATLAB type: $(expected_matlab_type_name(T))[]
""")
end


function incompatible_array_dimensions_exception(::Type{Array{T,N}}, nel::Int64,  ndims_mat::Int64, dimsmat::NTuple{M,Int64}) where {T,N, M}
    dimsprint = ((string(dimsmat[i]) * ", ") for i in 1:min(M, ndims_mat))

    MATFrostException(
        "matfrostjulia:conversion:incompatibleArrayDimensions",
"""
Converting to: $(string(Array{T,N})) 

Array dimensions incompatible:
    Actual array numel:        $(nel)
    Actual array dimensions:   numdims=$(ndims_mat); dimensions=($(dimsprint...))
    Expected array dimensions: numdims=$(N)
""")
end

function not_scalar_value_exception(::Type{T}, nel::Int64, ndims_mat::Int64, dimsmat::NTuple{M,Int64}) where {T, M}
    # actual_shape = join((string(unsafe_load(mfa.dims, i)) for i in 1:mfa.ndims), ", ")
    dimsprint = ((string(dimsmat[i]) * ", ") for i in 1:min(M, ndims_mat))

    MATFrostException(
        "matfrostjulia:conversion:notScalarValue",
"""
Converting to: $(T) 

Not scalar value:
    Actual array numel:        $(nel)
    Actual array dimensions:   ($(dimsprint...)) 
    Expected array dimensions: (1, 1)
""")
end



function validate_matfrostarray_type_and_size(io::BufferedStream, ::Type{T}, header::MATFrostArrayHeader) where {T}
    expected_type = expected_matlab_type(T)

    if (header.nel != 1)
        discard_matfrostarray_body!(io, header)
        throw(not_scalar_value_exception(T, header.nel, header.ndims, header.dims2))
    elseif (header.type != expected_type)
        discard_matfrostarray_body!(io, header)
        throw(incompatible_datatypes_exception(T, header.type))
    end

    nothing
end

function validate_matfrostarray_type_and_size(io::BufferedStream, ::Type{T}, header::MATFrostArrayHeader) where {T<:Array}
    expected_type = expected_matlab_type(T)

    if (prod(header.dims1; init=1) != header.nel)
        discard_matfrostarray_body!(io, header)
        throw(incompatible_array_dimensions_exception(T, header.nel, header.ndims, (header.dims1..., header.dims2...)))
    elseif ((header.nel != 0) & (header.type != expected_type))
        discard_matfrostarray_body!(io, header)
        throw(incompatible_datatypes_exception(T, header.type))
    end

    nothing
end

function validate_matfrostarray_type_and_size(io::BufferedStream, ::Type{T}, header::MATFrostArrayHeader) where {T<:Tuple}
    expected_type = expected_matlab_type(T)
    
    if ((header.nel != length(fieldnames(T))) || (header.dims1[1] != header.nel))
        discard_matfrostarray_body!(io, header)
        throw("Tuple error size does not match")
    elseif (header.type != expected_type)
        discard_matfrostarray_body!(io, header)
        throw(incompatible_datatypes_exception(T, header.type))
    end

    nothing
end


function read_matfrostarray_header!(io::BufferedStream, ::Type{T}) :: Tuple{} where {T}

    header = read_matfrostarray_header3!(io, Val{0}())

    expected_type = expected_matlab_type(T)

    if (header.nel != 1)
        discard_matfrostarray_body!(io, header)
        throw(not_scalar_value_exception(T, header.nel, header.ndims, header.dims2))
    elseif (header.type != expected_type)
        discard_matfrostarray_body!(io, header)
        throw(incompatible_datatypes_exception(T, header.type))
    end


    return ()
end
# function read_matfrostarray_header2!(io::BufferedStream, ::Type{T})

# end
function read_matfrostarray_header!(io::BufferedStream, ::Type{Array{T,N}}) :: NTuple{N, Int64} where {T,N}

    header = read_matfrostarray_header3!(io, Val{N}())


    expected_type = expected_matlab_type(Array{T,N})

    # incompatible_datatypes = type != expected_type
    # incompatible_array_dimension = false

    if (prod(header.dims1; init=1) != header.nel)
        discard_matfrostarray_body!(io, header)
        throw(incompatible_array_dimensions_exception(Array{T,N}, header.nel, header.ndims, (header.dims1..., header.dims2...)))
    elseif (header.nel == 0) 
        # Special behavior if nel==0. For this case allow any datatype input. 
        # MATLAB does not act strict on the datatype of empty values.

        if header.type == STRUCT
            nfields = read!(io, Int64)
            for _ in 1:nfields
                nb = read!(io, Int64)
                discard!(io, nb)
            end
        end
    elseif (header.type != expected_type)
        discard_matfrostarray_body!(io, header)
        throw(incompatible_datatypes_exception(Array{T,N}, header.type))
    end


    return header.dims1
end



function read_matfrostarray_header!(io::BufferedStream, ::Type{T}) :: NTuple{1, Int64} where {T <: Tuple}

    header = read_matfrostarray_header3!(io, Val{1}())


    expected_type = expected_matlab_type(T)


    if ((header.nel != length(fieldnames(T))) || (header.dims1[1] != header.nel))
        discard_matfrostarray_body!(io, header)
        throw("Tuple error size does not match")
    elseif (header.type != expected_type)
        discard_matfrostarray_body!(io, header)
        throw(incompatible_datatypes_exception(T, header.type))
    end


    return header.dims1
end



@noinline function read_matfrostarray!(io::BufferedStream, ::Type{T}) where {T <: Number}
    read_matfrostarray_header!(io, T)
    read!(io, T)
end

@noinline function read_matfrostarray!(io::BufferedStream, ::Type{Array{T,N}}) where {N, T <: Number}
    dims = read_matfrostarray_header!(io, Array{T,N})
    arr = Array{T,N}(undef, dims)
    read!(io, arr)
    arr
end

@noinline function read_matfrostarray!(io::BufferedStream, ::Type{String})
    read_matfrostarray_header!(io, String)
    read_string!(io)
end


@noinline function read_matfrostarray!(io::BufferedStream, ::Type{Array{String,N}}) where {N}
    dims = read_matfrostarray_header!(io, Array{String,N})
    arr = Array{String, N}(undef, dims)
    for i in eachindex(arr)
        arr[i] = read_string!(io)
    end
    arr
end


@generated function read_matfrostarray!(io::BufferedStream, ::Type{Array{Array{T,M}, N}}) where {T,N,M}
    return quote
        dims = read_matfrostarray_header!(io, Array{Array{T,M}, N})
        arr = Array{Array{T,M}, N}(undef, dims)
        for i in eachindex(arr)
            try
                arr[i] = @noinline read_matfrostarray!(io, Array{T,M})
            catch e
                discard_matfrostarray!(io, prod(dims; init=1) - i)
                throw(e)
            end
        end
        arr
    end
end


"""
Read a tuple object.
"""
@generated function read_matfrostarray!(io::BufferedStream, ::Type{T}) where {T <: Tuple}
    
    return quote

        dim = read_matfrostarray_header!(io, T)

        if (dim[1] != length(fieldnames(T)))
            discard_matfrostarray!(io, dim[1])
            throw("Cell does not contain amount of expected values:")
        end

        fi = 0
        try
            tup = ($((quote
                (fi = $(i); @noinline read_matfrostarray!(io, $(fieldtypes(T)[i])))
            end for i in eachindex(fieldnames(T)))...),)
            
            return T(tup)
        catch e
            discard_matfrostarray!(io, length(fieldnames(T)) - fi)
            throw(e)
        end


    end

end

function read_matrfrostarray_struct_header!(io::BufferedStream, expected_fieldnames::NTuple{N, Symbol}, nel::Int64) where {N}

    numfields_mat = read!(io, Int64)
    fieldnames_mat = Vector{Symbol}(undef, numfields_mat)
    fieldname_in_type = Vector{Bool}(undef, numfields_mat)
    for i in eachindex(fieldnames_mat)
        fieldnames_mat[i] = Symbol(read_string!(io))
        fieldname_in_type[i] = fieldnames_mat[i] in expected_fieldnames
    end
    
    if (numfields_mat != N || !all(fieldname_in_type))
        discard_matfrostarray!(io, nel*numfields_mat)
        throw("Fieldnames do not match: \nExpected: " * string(expected_fieldnames) *
            "\nRecieved: " * string(fieldnames_mat))
    end

    return fieldnames_mat
end

"""
Read a scalar struct object.
"""
@generated function read_matfrostarray_struct_object!(io::BufferedStream, fieldnames_mat::Vector{Symbol}, ::Type{T}) where{T}
    quote
        # Create local variables with type annotation, {Nothing, FieldType}
        $((quote
            $(Symbol(:_lfv_, fieldnames(T)[i])) :: Union{Nothing, $(fieldtypes(T)[i])} = nothing
        end for i in eachindex(fieldnames(T)))...)

        # Parse each field value. Parsing must be done in the order of MATFrostSequence
        for fn_i in 1:length(fieldnames_mat)
            fieldname = fieldnames_mat[fn_i]
            try 
                $((quote
                    if (fieldname == fieldnames(T)[$(i)])
                        $(Symbol(:_lfv_, fieldnames(T)[i])) = @noinline read_matfrostarray!(io, $(fieldtypes(T)[i]))
                    end
                end for i in eachindex(fieldnames(T)))...)
            catch e
                discard_matfrostarray!(io, length(fieldnames(T)) - fn_i)
                throw(e)
            end
        end

        # Force {Nothing, FieldType} to FieldType
        $((quote
            $(Symbol(:_lfva_, fieldnames(T)[i])) :: $(fieldtypes(T)[i]) = $(Symbol(:_lfv_, fieldnames(T)[i]))
        end for i in eachindex(fieldnames(T)))...)

        # Construct new struct
        $(
            if (T <: NamedTuple)
                :(T(($((Symbol(:_lfva_, fieldnames(T)[i]) for i in eachindex(fieldnames(T)))...),)))
            else    
                :(T($((Symbol(:_lfva_, fieldnames(T)[i]) for i in eachindex(fieldnames(T)))...)))
            end
        )
    end
end

"""
Read scalar struct object from MATFrostArray
"""
@generated function read_matfrostarray!(io::BufferedStream, ::Type{T}) where {T}
    if isabstracttype(T)
        return quote
            discard_matfrostarray!(io)
            throw("Interface contains abstract type: " * string(T))
        end
    end

    return quote
        read_matfrostarray_header!(io, T)
        fieldnames_mat = read_matrfrostarray_struct_header!(io, fieldnames(T), 1)

        read_matfrostarray_struct_object!(io, fieldnames_mat, T)

    end

end

"""
Read array of struct objects from MATFrostArray
"""
@generated function read_matfrostarray!(io::BufferedStream, ::Type{Array{T,N}}) where {T,N}
    if isabstracttype(T)
        return quote
            discard_matfrostarray!(io)
            throw("Interface contains abstract type: " * string(T))
        end
    end


    return quote
        dims = read_matfrostarray_header!(io, Array{T,N})

        nel = prod(dims; init=1)

        if nel == 0 
            # Special behavior for empty arrays. 
            # The matfrostarray object has already been cleared in read_matfrostarray_header!
            return Array{T,N}(undef, dims)
        end
        
        fieldnames_mat = read_matrfrostarray_struct_header!(io, fieldnames(T), nel)

        arr = Array{T,N}(undef, dims)
        
        for eli in eachindex(arr)
            try
                arr[eli] = read_matfrostarray_struct_object!(io, fieldnames_mat, T)
            catch e
                discard_matfrostarray!(io, (nel-eli)*length(fieldnames_mat))
                throw(e)
            end
        end
        arr
    end

end




# function incompatible_datatypes_exception(::Type{T}, mfa::MATFrostArray) where {T}
#     MATFrostException(
#         "matfrostjulia:conversion:incompatibleDatatypes",
#         "Converting to: " * string(T) * "\n\nNo conversion defined:\n    Actual MATLAB type:   " * array_type_name(mfa) * "[]\n    Expected MATLAB type: " * expected_matlab_type(T) * "[]")
# end

# function is_empty_array(mfa::MATFrostArray)
#     if mfa.ndims == 0
#         return true
#     end
#     any(unsafe_load(mfa.dims, i) == 0 for i in 1:mfa.ndims)
# end

# function empty_array(::Type{T}) where {T<:Array}
#     T(undef, ntuple(_-> 0, Val(ndims(T))))
# end

# function is_scalar_value(mfa::MATFrostArray)
#     if mfa.ndims == 0
#         return false
#     end
#     for i in 1:mfa.ndims
#         if unsafe_load(mfa.dims, i) != 1
#             return false
#         end
#     end
#     return true
# end

# function not_scalar_value_exception(::Type{T}, mfa::MATFrostArray) where {T}
#     actual_shape = join((string(unsafe_load(mfa.dims, i)) for i in 1:mfa.ndims), ", ")

#     MATFrostException(
#         "matfrostjulia:conversion:notScalarValue",
# """
# Converting to: $(T) 

# Not scalar value:
#     Actual array dimensions:   ($actual_shape) 
#     Expected array dimensions: (1, 1)
# """)
# end

# function array_dimensions_compatible(::Type{T}, mfa::MATFrostArray) where {T}
#     for i in (ndims(T)+1):mfa.ndims
#         if unsafe_load(mfa.dims, i) != 1
#             return false
#         end
#     end
#     return true
# end

# function incompatible_array_dimensions_exception(::Type{T}, mfa::MATFrostArray) where {T}
#     actual_shape = join((string(unsafe_load(mfa.dims, i)) for i in 1:mfa.ndims), ", ")
    
#     actual_numdims = maximum(ifelse(unsafe_load(mfa.dims, i) != 1, i, 0) for i in 1:mfa.ndims)

#     expected_array_dimensions = ifelse(ndims(T) == 1,
#         "1 (column-vector); dimensions=(:, 1)", 
#         "$(ndims(T)); dimensions=($( join((":" for _ in 1:ndims(T)), ", ") ))")

#     MATFrostException(
#         "matfrostjulia:conversion:incompatibleArrayDimensions",
# """
# Converting to: $(string(T)) 

# Array dimensions incompatible:
#     Actual array dimensions:   numdims=$(string(actual_numdims)); dimensions=($(actual_shape))
#     Expected array dimensions: numdims=$(expected_array_dimensions)
# """)
# end

# function read!(::Type{T}, mfa::MATFrostArray) where {T<:Number}
#     if !is_scalar_value(mfa)
#         throw(not_scalar_value_exception(T, mfa))
#     end
#     if !type_compatible(T, mfa)
#         throw(incompatible_datatypes_exception(T, mfa))
#     end
#     unsafe_load(reinterpret(Ptr{T}, mfa.data))
# end

# function convert_to_julia(::Type{T}, mfa::MATFrostArray) where {T<:Number}
#     if !is_scalar_value(mfa)
#         throw(not_scalar_value_exception(T, mfa))
#     end
#     if !type_compatible(T, mfa)
#         throw(incompatible_datatypes_exception(T, mfa))
#     end
#     unsafe_load(reinterpret(Ptr{T}, mfa.data))
# end

# function convert_to_julia(::Type{T}, mfa::MATFrostArray) where {T<:Array{<:Number}}
#     if is_empty_array(mfa)
#         return empty_array(T)
#     end
#     if !array_dimensions_compatible(T, mfa)
#         throw(incompatible_array_dimensions_exception(T, mfa))
#     end
#     if !type_compatible(T, mfa)
#         throw(incompatible_datatypes_exception(T, mfa))
#     end
#     ptr = reinterpret(Ptr{eltype(T)}, mfa.data)
#     arr = new_array(T, mfa.dims, mfa.ndims)
#     unsafe_copyto!(pointer(arr), ptr, length(arr))
#     arr  
# end




# function convert_to_julia(::Type{String}, mfa::MATFrostArray)
#     if !is_scalar_value(mfa)
#         throw(not_scalar_value_exception(String, mfa))
#     end
#     if !type_compatible(String, mfa)
#         throw(incompatible_datatypes_exception(String, mfa))
#     end
#     unsafe_string(unsafe_load(reinterpret(Ptr{Cstring}, mfa.data)))
# end

# function convert_to_julia(::Type{T}, mfa::MATFrostArray) where {T <: Array{String}} 
#     if is_empty_array(mfa)
#         return empty_array(T)
#     end
#     if !array_dimensions_compatible(T, mfa)
#         throw(incompatible_array_dimensions_exception(T, mfa))
#     end
#     if !type_compatible(T, mfa)
#         throw(incompatible_datatypes_exception(T, mfa))
#     end
#     arr = new_array(T, mfa.dims, mfa.ndims)
#     ptr = reinterpret(Ptr{Cstring}, mfa.data)
#     for i in eachindex(arr)
#         arr[i] = unsafe_string(unsafe_load(ptr, i))
#     end
#     arr
# end

# function convert_to_julia(::Type{T}, mfa::MATFrostArray) where {T<:Array{<:Union{Array, Tuple}}}
#     if is_empty_array(mfa)
#         return empty_array(T)
#     end
#     if !array_dimensions_compatible(T, mfa)
#         throw(incompatible_array_dimensions_exception(T, mfa))
#     end
#     if !type_compatible(T, mfa)
#         throw(incompatible_datatypes_exception(T, mfa))
#     end
#     ptr = reinterpret(Ptr{Ptr{MATFrostArray}}, mfa.data)
#     arr = new_array(T, mfa.dims, mfa.ndims)
#     for i in eachindex(arr)
#         arr[i] = convert_to_julia(eltype(T), unsafe_load(unsafe_load(ptr, i)))
#     end
#     arr
# end

# function convert_to_julia(::Type{T}, mfafields::NTuple{N, MATFrostArray}) where {T, N}
#     T(convert_to_julia.(fieldtypes(T), mfafields)...)
# end

# function convert_to_julia(::Type{T}, mfafields::NTuple{N, MATFrostArray}) where {T<:NamedTuple, N}
#     T(convert_to_julia.(fieldtypes(T), mfafields))
# end



# function missing_fields_exception(::Type{T}, fieldnames_mat::Vector{Symbol}) where {T}
#     missingfields  = join(("    " * string(missingfield)  for missingfield in  fieldnames(T) if !(missingfield in fieldnames_mat)), "\n")
#     actualfields   = join(("    " * string(fieldnamemat)  for fieldnamemat in fieldnames_mat), "\n")
#     expectedfields = join(("    " * string(fieldnamejl) * "::" * fieldtype for (fieldnamejl, fieldtype)  in zip(fieldnames(T), string.(fieldtypes(T)))), "\n")

#     MATFrostException(
#         "matfrostjulia:conversion:missingFields",
# """
# Converting to: $(string(T))

# Input MATLAB struct value is missing fields.
    
# Missing fields: 
# $(missingfields)

# Actual fields:
# $(actualfields)

# Expected fields:
# $(expectedfields)
# """
#     )
# end        
        
# function additional_fields_exception(::Type{T}, fieldnames_mat::Vector{Symbol}) where {T}
#     additionalfields  = join(("    " * string(additionalfield)  for additionalfield in fieldnames_mat if !(additionalfield in fieldnames(T) )), "\n")
#     actualfields   = join(("    " * string(fieldnamemat)  for fieldnamemat in fieldnames_mat), "\n")
#     expectedfields = join(("    " * string(fieldnamejl) * "::" * fieldtype for (fieldnamejl, fieldtype)  in zip(fieldnames(T), string.(fieldtypes(T)))), "\n")

#     MATFrostException(
#         "matfrostjulia:conversion:additionalFields",
# """
# Converting to: $(string(T))

# Input MATLAB struct value has additional fields.
    
# Additional fields: 
# $(additionalfields)

# Actual fields:
# $(actualfields)

# Expected fields:
# $(expectedfields)
# """
#     )
# end        
   

# #if !(missingfield in fieldnames(T))


# function convert_to_julia(::Type{T}, mfa::MATFrostArray) where {T}
#     if !is_scalar_value(mfa)
#         throw(not_scalar_value_exception(T, mfa))
#     end
#     if !type_compatible(T, mfa)
#         throw(incompatible_datatypes_exception(T, mfa))
#     end

#     fieldnames_mat = [Symbol(unsafe_string(unsafe_load(mfa.fieldnames, i))) for i in 1:mfa.nfields]
    
#     if !all((fieldname_jl in fieldnames_mat) for fieldname_jl in fieldnames(T))
#         throw(missing_fields_exception(T, fieldnames_mat))
#     end

#     if !all((fieldnamemat in fieldnames(T)) for fieldnamemat in fieldnames_mat)
#         throw(additional_fields_exception(T, fieldnames_mat))
#     end

#     order = (fnjl -> Int64(findfirst(fnmat -> fnmat == fnjl, fieldnames_mat))).(fieldnames(T))
    
#     mfadata = reinterpret(Ptr{Ptr{MATFrostArray}}, mfa.data)
    
#     mfafields = (or -> unsafe_load(unsafe_load(mfadata, or))).(order)

#     convert_to_julia(T, mfafields)
# end

# function convert_to_julia(::Type{T}, mfa::MATFrostArray) where {T<:Array}
#     if is_empty_array(mfa)
#         return empty_array(T)
#     end
#     if !array_dimensions_compatible(T, mfa)
#         throw(incompatible_array_dimensions_exception(T, mfa))
#     end
#     if !type_compatible(T, mfa)
#         throw(incompatible_datatypes_exception(T, mfa))
#     end
    
#     fieldnames_mat = [Symbol(unsafe_string(unsafe_load(mfa.fieldnames, i))) for i in 1:mfa.nfields]

#     if !all((fieldname_jl in fieldnames_mat) for fieldname_jl in fieldnames(eltype(T)))
#         throw(missing_fields_exception(eltype(T), fieldnames_mat))
#     end

#     if !all((fieldnamemat in fieldnames(eltype(T))) for fieldnamemat in fieldnames_mat)
#         throw(additional_fields_exception(eltype(T), fieldnames_mat))
#     end
    
#     arr = new_array(T, mfa.dims, mfa.ndims) 
    

#     order = (fnjl -> Int64(findfirst(fnmat -> fnmat == fnjl, fieldnames_mat))).(fieldnames(eltype(T)))
#     mfadata = reinterpret(Ptr{Ptr{MATFrostArray}}, mfa.data)
    
#     for j in eachindex(arr)  
#         mfafields = (or -> unsafe_load(unsafe_load(mfadata, (j-1)*mfa.nfields + or))).(order)
#         arr[j] = convert_to_julia(eltype(T), mfafields)
#     end
#     arr
# end

# function incompatible_tuple_shape(::Type{T}, mfa::MATFrostArray) where {T <: Tuple}
#     actual_shape = join((string(unsafe_load(mfa.dims, i)) for i in 1:mfa.ndims), ", ")
    
#     actual_numdims = maximum(ifelse(unsafe_load(mfa.dims, i) != 1, i, 0) for i in 1:mfa.ndims; init=0)

#     MATFrostException(
#         "matfrostjulia:conversion:incompatibleArrayDimensions",
# """
# Converting to: $(string(T)) 

# Array dimensions incompatible:
#     Actual array dimensions:   numdims=$(string(actual_numdims)); dimensions=($(actual_shape))
#     Expected array dimensions: numdims=1 (column-vector); ($(length(fieldnames(T))), 1)
# """)
# end

# function convert_to_julia(::Type{T}, mfa::MATFrostArray) where {T <: Tuple}
#     if !type_compatible(T, mfa)
#         throw(incompatible_datatypes_exception(T, mfa))
#     end
#     if !(ifelse(mfa.ndims >= 1, unsafe_load(mfa.dims,1) == length(fieldnames(T)), false) && all(unsafe_load(mfa.dims, i) == 1 for i in 2:mfa.ndims))
#         throw(incompatible_tuple_shape(T, mfa))
#     end
#     mfadata = reinterpret(Ptr{Ptr{MATFrostArray}}, mfa.data)
#     convert_to_julia.(
#         fieldtypes(T), 
#         ntuple(i-> unsafe_load(unsafe_load(mfadata, i)), Val(length(fieldnames(T))))
#     )
# end


end