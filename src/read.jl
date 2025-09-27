module _Read

import ..MATFrost._Stream: read!, write!, flush!, BufferedStream, discard!
using ..MATFrost: _MATFrostException as MATFrostException
using .._Constants


struct Ok{T}
    x::T
    Ok(x::T) where {T} = new{T}(x)
end

struct Err{E}
    x::E
    Err(x::E) where {E} = new{E}(x)
end

struct Result{O, E}
    x::Union{Ok{O}, Err{E}}

    # Suppress the unparameterized constuctor
    # Result{O, E}(x::Union{Ok{O}, Err{E}}) where {O, E} = new{O, E}(x)
    Result{O,E}(x::O) where {O,E} = new{O,E}(Ok(x))
    Result{O,E}(x::E) where {O,E} = new{O,E}(Err(x))
end

const MATFrostResult{T} = Result{T, MATFrostException}




struct MATFrostArrayHeader
    type :: Int32
    dims :: Vector{Int64}
end





function array_dims(header::MATFrostArrayHeader, ::Val{N}) where N
    ntuple(Val{N}()) do i
        if 1 <= length(header.dims)
            header.dims[i]
        else
            1
        end
    end
end


@noinline function read_matfrostarray!(io::BufferedStream, ::Type{T}) where {T <: Union{Number, Array{<:Number}, String, Array{String}}}
    result = read_and_validate_matfrostarray_header!(io, T).x
    if isa(result, Ok)
        read_matfrostarray!(io, T, result.x)
    else
        MATFrostResult{T}(result.x)
    end
    
end


@generated function read_matfrostarray!(io::BufferedStream, ::Type{T}) where {T}
    quote
        result = read_and_validate_matfrostarray_header!(io, T).x
        if isa(result, Ok)           
            read_matfrostarray!(io, T, result.x)
        else
            MATFrostResult{T}(result.x)
        end
    end
end





function read_matfrostarray!(io::BufferedStream, ::Type{T}, header::MATFrostArrayHeader) where {T <: Number}
    v = read!(io, T)
    MATFrostResult{T}(v)
end

function read_matfrostarray!(io::BufferedStream, ::Type{Array{T,N}}, header::MATFrostArrayHeader) where {N, T <: Number}
    dims = array_dims(header, Val{N}())
    arr = Array{T,N}(undef, dims)
    read!(io, arr)
    MATFrostResult{Array{T,N}}(arr)
end


function read_matfrostarray!(io::BufferedStream, ::Type{String}, header::MATFrostArrayHeader)
    s = read_string!(io)
    MATFrostResult{String}(s)
end


function read_matfrostarray!(io::BufferedStream, ::Type{Array{String,N}}, header::MATFrostArrayHeader) where {N}
    dims = array_dims(header, Val{N}())
    arr = Array{String, N}(undef, dims)
    for i in eachindex(arr)
        arr[i] = read_string!(io)
    end
    MATFrostResult{Array{String,N}}(arr)
end



@generated function read_matfrostarray!(io::BufferedStream, ::Type{Array{T,N}}, header::MATFrostArrayHeader) where {T <: Union{Array, Tuple}, N}
    return quote
        dims = array_dims(header, Val{N}())
        arr = Array{T, N}(undef, dims)
        for i in eachindex(arr)
            result = (@noinline read_matfrostarray!(io, T)).x
            if result isa Ok
                arr[i] = result.x
            else
                discard_matfrostarray!(io, length(arr) - i)
                return MATFrostResult{Array{T, N}}(result.x)
            end
        end
        MATFrostResult{Array{T, N}}(arr)
    end
end



"""
Read a tuple object.
"""
@generated function read_matfrostarray!(io::BufferedStream, ::Type{T}, header::MATFrostArrayHeader) where {T <: Tuple}
    return quote
        $((
            quote
                result = (@noinline read_matfrostarray!(io, $(fieldtypes(T)[i]))).x

                if result isa Err
                    discard_matfrostarray!(io, $(fieldcount(T)-i))
                    return MATFrostResult{T}(result.x)
                end

                $(Symbol(:v, i)) = result.x

            end for i in eachindex(fieldtypes(T))
        )...)

        return MATFrostResult{T}(($((
            Symbol(:v, i) for i in eachindex(fieldtypes(T))
        )...),))

    end
end


"""
Read scalar struct object from MATFrostArray
"""
@generated function read_matfrostarray!(io::BufferedStream, ::Type{T}, header::MATFrostArrayHeader) where {T}
    if !isstructtype(T)
        return quote
            discard_matfrostarray_body!(io, header)
            MATFrostResult{T}(MATFrostException("", "Type not supported $(_typename(T))"))
        end
    end

    return quote

        result = (@noinline read_and_validate_matrfrostarray_struct_header!(io, fieldnames(T), header)).x
        if result isa Err
            return MATFrostResult{T}(result.x)
        end
        fieldnames_mat = result.x


        @noinline read_matfrostarray_struct_object!(io, fieldnames_mat, T)

    end

end

"""
Read array of struct objects from MATFrostArray
"""
@generated function read_matfrostarray!(io::BufferedStream, ::Type{Array{T,N}}, header::MATFrostArrayHeader) where {T,N}
    if !isstructtype(T)
        return quote
            discard_matfrostarray!(io, header)
            MATFrostResult{Array{T,N}}(MATFrostException("", "Type not supported $(_typename(Array{T,N}))"))
        end
    end


    return quote
        dims = array_dims(header, Val{N}())

        nel = prod(dims; init=1)

        if nel == 0 
            # Special behavior for empty arrays. 
            # The matfrostarray object has already been cleared in read_matfrostarray_header!
            return MATFrostResult{Array{T,N}}(Array{T,N}(undef, dims))
        end
        
        result = (@noinline read_and_validate_matrfrostarray_struct_header!(io, fieldnames(T), header)).x
        if result isa Err
            return MATFrostResult{Array{T,N}}(result.x)
        end
        fieldnames_mat = result.x


        arr = Array{T,N}(undef, dims)
        
        for eli in eachindex(arr)
            result = (@noinline read_matfrostarray_struct_object!(io, fieldnames_mat, T)).x
            if result isa Ok
                arr[eli] = result.x
            else
                discard_matfrostarray!(io, (nel-eli)*length(fieldnames_mat))
                return MATFrostResult{Array{T,N}}(result.x)
            end

        end
        MATFrostResult{Array{T,N}}(arr)
    end

end



@noinline function read_and_validate_matrfrostarray_struct_header!(io::BufferedStream, expected_fieldnames::NTuple{N, Symbol}, header::MATFrostArrayHeader) where {N}
    nel = prod(header.dims; init=1)

    numfields_mat = read!(io, Int64)
    fieldnames_mat = Vector{Symbol}(undef, numfields_mat)
    fieldname_in_type = Vector{Bool}(undef, numfields_mat)
    for i in eachindex(fieldnames_mat)
        fieldnames_mat[i] = Symbol(read_string!(io))
        fieldname_in_type[i] = fieldnames_mat[i] in expected_fieldnames
    end
    
    if (numfields_mat != N || !all(fieldname_in_type))
        discard_matfrostarray!(io, nel*numfields_mat)

        
        return MATFrostResult{Vector{Symbol}}(MATFrostException(
            "",
            "Fieldnames do not match: \nExpected: $(expected_fieldnames...)" *
            "\nRecieved: $(fieldnames_mat...)"
        ))
    end

    return MATFrostResult{Vector{Symbol}}(fieldnames_mat)
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
        for fn_i in eachindex(fieldnames_mat)
            fn_mat = fieldnames_mat[fn_i]

            $((
            quote

            if (fn_mat == fieldnames(T)[$(i)])
                result = (@noinline read_matfrostarray!(io, $(fieldtypes(T)[i]))).x

                if result isa Ok    
                    $(Symbol(:_lfv_, fieldnames(T)[i])) = result.x
                else
                    discard_matfrostarray!(io, length(fieldnames_mat) - fn_i)
                    return MATFrostResult{T}(result.x)
                end
                
                continue
            end

            end for i in eachindex(fieldnames(T))
            )...)

            discard_matfrostarray!(io, 1)

        end

        # Check if all values are given value
        if $((x = :(false) ; for fn in fieldnames(T) ; x = :(($(Symbol(:_lfv_, fn)) isa Nothing) || $(x)) ; end ; x))
            return MATFrostResult{T}(MATFrostException("", "Value not initalized"))
        else
            # Construct new struct
            v = $(
                if (T <: NamedTuple)
                    :(T(($((Symbol(:_lfv_, fn) for fn in fieldnames(T))...),)))
                else    
                    :(T($((Symbol(:_lfv_, fn) for fn in fieldnames(T))...)))
                end
            )

            return MATFrostResult{T}(v)
        end       

        
    end
end






function read_and_validate_matfrostarray_header!(io::BufferedStream, ::Type{T}) :: MATFrostResult{MATFrostArrayHeader} where {T}

    header = read_matfrostarray_header!(io)

    expected_type = mapped_matlab_type(T)
    nel = prod(header.dims; init=1)
    if (nel != 1)
        discard_matfrostarray_body!(io, header)
        return MATFrostResult{MATFrostArrayHeader}(not_scalar_value_exception(T, header.dims))
    elseif (header.type != expected_type)
        discard_matfrostarray_body!(io, header)
        return MATFrostResult{MATFrostArrayHeader}(incompatible_datatypes_exception(T, header.type))
    end
    MATFrostResult{MATFrostArrayHeader}(header)
end


function read_and_validate_matfrostarray_header!(io::BufferedStream, ::Type{Array{T,N}}) :: MATFrostResult{MATFrostArrayHeader} where {T,N}
    header = read_matfrostarray_header!(io)

    expected_type = mapped_matlab_type(Array{T,N})
    
    nel = prod(header.dims; init=1)

    neljl = 1
    for i = 1:min(N, length(header.dims))
        neljl *= @inbounds header.dims[i]
    end

    if (nel != neljl)
        discard_matfrostarray_body!(io, header)
        return MATFrostResult{MATFrostArrayHeader}(incompatible_array_dimensions_exception(Array{T,N}, header.dims))
    elseif (nel == 0)
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
        return MATFrostResult{MATFrostArrayHeader}(incompatible_datatypes_exception(Array{T,N}, header.type))
    end

    return MATFrostResult{MATFrostArrayHeader}(header)

end


function read_and_validate_matfrostarray_header!(io::BufferedStream, ::Type{T}) where {T<:Tuple}
    header = read_matfrostarray_header!(io)
    
    expected_type = mapped_matlab_type(T)

    nel = prod(header.dims; init=1)

    if ((nel != fieldcount(T)) || (header.dims[1] != nel))
        discard_matfrostarray_body!(io, header)
        return MATFrostResult{MATFrostArrayHeader}(MATFrostException("","Tuple error size does not match"))
    elseif (header.type != expected_type)
        discard_matfrostarray_body!(io, header)
        return MATFrostResult{MATFrostArrayHeader}(incompatible_datatypes_exception(T, header.type))
    end

    return MATFrostResult{MATFrostArrayHeader}(header)

end



function read_string!(io::BufferedStream) :: String
    sarr = Vector{UInt8}(undef, read!(io, Int64))
    read!(io, sarr)
    transcode(String, sarr)
end




"""
This function will read a specified number of matfrostarray objects from stream and discard the data.
Used in cases of errors to keep the connection state correct.
"""
@noinline function discard_matfrostarray!(io::BufferedStream, numobjects::Int64 = 1)
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
            nb = nel * sizeof_matlab_primitive(type)
            discard!(io, nb)
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
@noinline function discard_matfrostarray_body!(io::BufferedStream, type::Int32, nel::Int64)
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
        nb = nel * sizeof_matlab_primitive(type)
        discard!(io, nb)
    end
    nothing
end

function discard_matfrostarray_body!(io::BufferedStream, header::MATFrostArrayHeader) 
    discard_matfrostarray_body!(io, header.type, prod(header.dims; init=1))
end


function read_matfrostarray_header!(io::BufferedStream) :: MATFrostArrayHeader
    type = read!(io, Int32)
   
    ndims = read!(io, Int64)

    dims = Int64[read!(io, Int64) for _ in 1:ndims]

    MATFrostArrayHeader(type, dims)

end

"""
Pre-generated typenames used in error messages. As `string` is not type-stable.
"""
@generated function _typename(::Type{T}) where T
    :($(string(T)))
end

"""
Pre-generated typenames used in error messages. As `string` is not type-stable.
"""
@generated function _fieldtypenames(::Type{T}) where T
    :(String[$((:(_typename($(ft))) for ft in fieldtypes(T))...)])
end


@noinline function incompatible_datatypes_exception(typename::String, expectedmatlabtypename::String, matlabtype::Int32)
    MATFrostException(
        "matfrostjulia:conversion:incompatibleDatatypes",
"""
Converting to: $(typename) 

Incompatible datatypes conversion:
    Actual MATLAB type:   $(matlab_type_name(matlabtype))[]
    Expected MATLAB type: $(expectedmatlabtypename)[]
""")
end

@noinline function incompatible_datatypes_exception(::Type{T}, matlabtype::Int32) where {T}
    typename = _typename(T)
    expectedmatlabtypename = matlab_type_name(mapped_matlab_type(T))

    incompatible_datatypes_exception(typename, expectedmatlabtypename, matlabtype)
end






@noinline function incompatible_array_dimensions_exception(typename::String, expectednumdims::Int64, dims::Vector{Int64})
    dimsprint = ("$(dim), " for dim in dims)

    MATFrostException(
        "matfrostjulia:conversion:incompatibleArrayDimensions",
"""
Converting to: $(typename) 

Array dimensions incompatible:
    Actual array numel:        $(prod(dims; init=1))
    Actual array dimensions:   numdims=$(length(dims)); dimensions=($(dimsprint...))
    Expected array dimensions: numdims=$(expectednumdims)
""")
end


@noinline function incompatible_array_dimensions_exception(::Type{Array{T,N}}, dims::Vector{Int64}) where {T,N}
    typename = _typename(Array{T,N})
    incompatible_array_dimensions_exception(typename, N, dims)
end






@noinline function not_scalar_value_exception(typename::String, dims::Vector{Int64})
    # actual_shape = join((string(unsafe_load(mfa.dims, i)) for i in 1:mfa.ndims), ", ")
        dimsprint = ((string(dim) * ", ") for dim in dims)

    MATFrostException(
        "matfrostjulia:conversion:notScalarValue",
"""
Converting to: $(typename) 

Not scalar value:
    Actual array numel:        $(prod(dims; init=1))
    Actual array dimensions:   ($(dimsprint...)) 
    Expected array dimensions: (1, 1)
""")
end

@noinline function not_scalar_value_exception(::Type{T}, dims::Vector{Int64}) where T
    typename = _typename(T)
    not_scalar_value_exception(typename, dims)
end



@noinline function missing_fields_exception(typename::String, fieldnames::Vector{Symbol}, fieldtypenames::Vector{String}, fieldnames_mat::Vector{Symbol})
    missingfields  = ("    $(fn)\n" for fn in fieldnames if !(fn in fieldnames_mat))
    actualfields   = ("    $(fn)\n"  for fn in fieldnames_mat)
    expectedfields = ("    $(fn)::$(ftn)\n" for (fn, ftn)  in zip(fieldnames, fieldtypenames))

  MATFrostException(
        "matfrostjulia:conversion:missingFields",
"""
Converting to: $(typename)

Input MATLAB struct value is missing fields.
    
Missing fields: 
$(missingfields...)

Actual fields:
$(actualfields...)

Expected fields:
$(expectedfields...)
"""
    )
end


@noinline function missing_fields_exception(::Type{T}, fieldnames_mat::Vector{Symbol}) where T
    typename = _typename(T)
    _fieldnames = Symbol[fieldnames(T)...]
    fieldtypenames = _fieldtypenames(T)
    
    missing_fields_exception(typename, _fieldnames, fieldtypenames, fieldnames_mat)

end




@noinline function additional_fields_exception(typename::String, fieldnames::Vector{Symbol}, fieldtypenames::Vector{String}, fieldnames_mat::Vector{Symbol})
    additionalfields = ("    $(fn)\n"  for fn in fieldnames_mat if !(fn in fieldnames))
    actualfields =     ("    $(fn)\n"  for fn in fieldnames_mat)
    expectedfields =   ("    $(fn)::$(ftn)\n" for (fn, ftn)  in zip(fieldnames, fieldtypenames))

    MATFrostException(
        "matfrostjulia:conversion:additionalFields",
"""
Converting to: $(typename)

Input MATLAB struct value has additional fields.

Additional fields: 
$(additionalfields...)

Actual fields:
$(actualfields...)

Expected fields:
$(expectedfields...)
"""
    )
end 

@noinline function additional_fields_exception(::Type{T}, fieldnames_mat::Vector{Symbol}) where T
   typename = _typename(T)
    _fieldnames = Symbol[fieldnames(T)...]
    fieldtypenames = _fieldtypenames(T)
    
    additional_fields_exception(typename, _fieldnames, fieldtypenames, fieldnames_mat)

end


   
@noinline function incompatible_tuple_shape(typename::String, tuplelength::Int64, header::MATFrostArrayHeader)
actualshape = 1

    MATFrostException(
        "matfrostjulia:conversion:incompatibleArrayDimensions",
"""
Converting to: $(typename) 

Array dimensions incompatible:
    Actual array dimensions:   numdims=$(length(header.dims)); dimensions=($(actualshape))
    Expected array dimensions: numdims=1 (column-vector); dimensions=($(tuplelength), 1)
""")
end



function incompatible_struct_exception(::Type{T}, fieldnames_mat) where {T}
    typename = string(T)
    fieldnames_jl = collect(string.(fieldnames(T)))
    fieldtypes_names = collect(string.(fieldtypes(T)))

    
    missing_fields_exception(typename, fieldnames_jl, fieldtypes_names, fieldnames_mat)
end




function validate_matfrostarray_type_and_size(io::BufferedStream, ::Type{T}, header::MATFrostArrayHeader) where {T}
    expected_type = mapped_matlab_type(T)

    if (header.nel != 1)
        discard_matfrostarray_body!(io, header)
        throw(not_scalar_value_exception(T, header.dims))
    elseif (header.type != expected_type)
        discard_matfrostarray_body!(io, header)
        throw(incompatible_datatypes_exception(T, header.type))
    end

    nothing
end

function validate_matfrostarray_type_and_size(io::BufferedStream, ::Type{T}, header::MATFrostArrayHeader) where {T<:Array}
    expected_type = mapped_matlab_type(T)

    if (prod(header.dims1; init=1) != header.nel)
        discard_matfrostarray_body!(io, header)
        throw(incompatible_array_dimensions_exception(T, header.dims))
    elseif ((header.nel != 0) & (header.type != expected_type))
        discard_matfrostarray_body!(io, header)
        throw(incompatible_datatypes_exception(T, header.type))
    end

    nothing
end




end