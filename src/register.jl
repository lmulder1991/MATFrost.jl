module _Register
"""
    @matfrost function factorize(x::Float64, y::Vector{Float64})

    end


    @matfrostserver
"""
macro matfrost(func)

    if func.head != :function || func.head != :(=)
        error("Not function")
    end

    if func.args[1].head != :call
        error("Not function")
    end

    fname = func.args[1].args[1]
    args  = func.args[1].args[2:end]

    argtypes = broadcast(args) do arg
        if !(arg isa Expr)
            error("Not typed")
        end
        if arg.head != :(::)
            error("Not typed")
        end

        arg.args[end]
    end

    f2 = :(
        function $fname(io::MATFrost._Stream.BufferedStream, nargs::Int64)
            #Read
            $((:(
                $(Symbol(:vin, i)) = MATFrost._Read.read_matfrostarray!(io, $(argtypes[i])).x
                if $(Symbol(:vin, i)) isa MATFrost._Read.Err
                    
                end
            ) for i in eachindex(argtypes))...)

            # Call
            vout = $fname($((Symbol(:vin, i).x for i in eachindex(argtypes))...))

            # Write
            MATFrost._Write.write_matfrostarray!(io, vout)
        end

        MATFrost._registered_functions(io::MATFrost._Stream.BufferedStream, nargs::Int64, ::Val{$fname}) = $fname(io, nargs)
    )
    quote
        $(esc(func))
        $(esc(f2))
    end
end


macro matfrostserver()
    quote
        const _MATFROST_FUNCTIONS = ntuple(length(methods(MATFrost._registered_functions))) do i
            fieldtype(methods(MATFrost._registered_functions)[i].sig,4)()
        end
        function matfrostserve()
            MATFrost._matfrostserve(_MATFROST_FUNCTIONS)
        end

        function main(args)

        end

    end
end

end