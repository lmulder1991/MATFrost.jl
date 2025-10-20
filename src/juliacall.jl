module _JuliaCall
    using ..MATFrost: _MATFrostArray as MATFrostArray

    using ..MATFrost: _ConvertToJulia
    
    using ..MATFrost: _ConvertToMATLAB

    using ..MATFrost: _MATFrostException as MATFrostException

    struct MATFrostInput
        package::String
        func::String
        args::Any
    end

    struct MATFrostOutput
        value::Any
        exception::Bool
    end   

    const MATFROSTMEMORY = Dict{MATFrostArray, Any}()

    function juliacall(mfa::MATFrostArray)

        try
            fns = [Symbol(unsafe_string(unsafe_load(mfa.fieldnames, i))) for i in 1:mfa.nfields]

            if !(:package in fns && :func in fns && :args in fns)
                throw(MATFrostException("matfrostjulia:incorrectInputSignature", "Missing either field: 'package', 'func' or 'args'."))
            end

            package_i  = findfirst(fn -> fn == :package, fns)
            func_i     = findfirst(fn -> fn == :func, fns)
            args_i     = findfirst(fn -> fn == :args, fns)

            println( package_i, func_i, args_i)
            mfadata = reinterpret(Ptr{Ptr{MATFrostArray}}, mfa.data)
            
            package_sym = Symbol(_ConvertToJulia.convert_to_julia(String, unsafe_load(unsafe_load(mfadata, package_i))))
            func_signature = _ConvertToJulia.convert_to_julia(String, unsafe_load(unsafe_load(mfadata, func_i)));
            if occursin("(", func_signature)
                a = findfirst('(', func_signature)
                b = findfirst(')', func_signature)
                if b === nothing
                    throw(MATFrostException("matfrostjulia:invalidFunctionSignature", "Missing closing ')' in function signature."))
                end
                func_input = strip(func_signature[a+1:b-1])
                func_sym = Symbol(strip(func_signature[1:a-1]))
            else
                func_sym = Symbol(func_signature)
            end

            try 
                Main.eval(:(import $(package_sym)))
            catch e
                throw(MATFrostException("matfrostjulia:packageDoesNotExist", """
                Package does not exist.
                
                $(sprint(showerror, e, catch_backtrace()))
                """
                ))
            end

            func = try 
                getproperty(getproperty(Main, package_sym), func_sym)
            catch e
                throw(MATFrostException("matfrostjulia:functionDoesNotExist", """
                Function does not exist.

                $(sprint(showerror, e, catch_backtrace()))
                """
                )) 
            end
            index = 1
            if (length(methods(func)) != 1)
                if @isdefined func_input
                    pattern = Regex("$func_sym\\((.*?)\\)")
                    index = findfirst(m -> first(match(pattern, string(m))) == func_input, methods(func))
                    if index == nothing
                        throw(MATFrostException("matfrostjulia:functionSignatureDoesNotExist", """
                        No method matching the provided function signature.
                        available methods: $(methods(func)),
                        while you provided: $func_input [$index]
                        """
                        )) 
                    end
                else
                    throw(MATFrostException("matfrostjulia:multipleMethodDefinitions", """
                    Function contains multiple method implementations:

                    $(methods(func))
                    Please specify the function signature. -> e.g. func(args::Int64, moreargs::String)
                    """
                    )) 
                end
            end

            argstypes = Tuple{(methods(func)[index].sig.types[2:end]...,)...}

            args_mfa = unsafe_load(unsafe_load(mfadata, args_i))
            
            args = _ConvertToJulia.convert_to_julia(argstypes, args_mfa)

            # The main Julia call
            vo = func(args...)
            
            vom = _ConvertToMATLAB.convert(MATFrostOutput(vo, false))
            MATFROSTMEMORY[vom.matfrostarray] = vom
            return vom.matfrostarray
        catch e
            if isa(e, MATFrostException)
                mfe = _ConvertToMATLAB.convert(MATFrostOutput(e, true))
                MATFROSTMEMORY[mfe.matfrostarray] = mfe
                return mfe.matfrostarray
            else
                mfe = _ConvertToMATLAB.convert(MATFrostOutput(MATFrostException("matfrostjulia:crashed", sprint(showerror, e, catch_backtrace())), true))
                MATFROSTMEMORY[mfe.matfrostarray] = mfe
                return mfe.matfrostarray
            end
        end

    end    

    function freematfrostmemory(mfa::MATFrostArray)
        delete!(MATFROSTMEMORY, mfa)
        return nothing
    end
    

end
