module _Server

import ..MATFrost as MATFrost

struct CallStruct
    functionname::String
    bindir::String
    project::String
    evaluate::String
end




struct ActionStruct
    functionname::String
    bindir::String
    project::String
    evaluate::String
end


    # function juliacall(mfa::MATFrostArray)

    #     try
    #         fns = [Symbol(unsafe_string(unsafe_load(mfa.fieldnames, i))) for i in 1:mfa.nfields]

    #         if !(:package in fns && :func in fns && :args in fns)
    #             throw(MATFrostException("matfrostjulia:incorrectInputSignature", "Missing either field: 'package', 'func' or 'args'."))
    #         end

    #         package_i  = findfirst(fn -> fn == :package, fns)
    #         func_i     = findfirst(fn -> fn == :func, fns)
    #         args_i     = findfirst(fn -> fn == :args, fns)

            
    #         mfadata = reinterpret(Ptr{Ptr{MATFrostArray}}, mfa.data)
            
    #         package_sym = Symbol(_ConvertToJulia.convert_to_julia(String, unsafe_load(unsafe_load(mfadata, package_i))))
    #         func_sym    = Symbol(_ConvertToJulia.convert_to_julia(String, unsafe_load(unsafe_load(mfadata, func_i))))

    #         try 
    #             Main.eval(:(import $(package_sym)))
    #         catch e
    #             throw(MATFrostException("matfrostjulia:packageDoesNotExist", """
    #             Package does not exist.
                
    #             $(sprint(showerror, e, catch_backtrace()))
    #             """
    #             ))
    #         end


    #         func = try 
    #             getproperty(getproperty(Main, package_sym), func_sym)
    #         catch e
    #             throw(MATFrostException("matfrostjulia:functionDoesNotExist", """
    #             Function does not exist.

    #             $(sprint(showerror, e, catch_backtrace()))
    #             """
    #             )) 
    #         end

    #         if (length(methods(func)) != 1)
    #             throw(MATFrostException("matfrostjulia:multipleMethodDefinitions", """
    #             Function contains multiple method implementations:

    #             $(methods(func))
    #             """
    #             )) 
    #         end

    #         argstypes = Tuple{(methods(func)[1].sig.types[2:end]...,)...}

    #         args_mfa = unsafe_load(unsafe_load(mfadata, args_i))
            
    #         args = _ConvertToJulia.convert_to_julia(argstypes, args_mfa)

    #         # The main Julia call
    #         vo = func(args...)
            
    #         vom = _ConvertToMATLAB.convert(MATFrostOutput(vo, false))
    #         MATFROSTMEMORY[vom.matfrostarray] = vom
    #         return vom.matfrostarray
    #     catch e
    #         # if isa(e, MATFrostException)
    #         #     mfe = _ConvertToMATLAB.convert(MATFrostOutput(e, true))
    #         #     MATFROSTMEMORY[mfe.matfrostarray] = mfe
    #         #     return mfe.matfrostarray
    #         # else
    #         #     mfe = _ConvertToMATLAB.convert(MATfrostOutput(MATFrostException("matfrostjulia:crashed", sprint(showerror, e, catch_backtrace())), true))
    #         #     MATFROSTMEMORY[mfe.matfrostarray] = mfe
    #         #     return mfe.matfrostarray
    #         # end
    #     end

    # end    





macro MATFrost.matfrostserve(matfrostin, matfrostout)
println(matfrostin)
esc(quote
    in_buf = MATFrost._Stream.BufferedStream($(matfrostin), Vector{UInt8}(undef, 2<<13), 0, 0)
    # io = _Stream
    out_buf  = MATFrost._Stream.BufferedStream($(matfrostout), Vector{UInt8}(undef, 2<<13), 0, 0)


    while true  


        # arr = _ConvertToJulia.read_matlab!(in_buf, Vector{Int32})

        # _ConvertToMATLAB.write_matlab!(out_buf, arr)
        try 
        # arr = _ConvertToJulia.read_matlab!(in_buf, Vector{Int32})
        
            arr = MATFrost._Read.read_matfrostarray!(in_buf, Tuple{@NamedTuple{fully_qualified_name::String}, Tuple{Vector{String}}})

            MATFrost._Write.write_matfrostarray!(out_buf, arr)

        catch e
            open(raw"C:\Users\jbelier\Documents\GitHub\MATFrost.jl\src\matfrostjuliacall\juliaerror.txt", "w") do io 
                println(io, e)
                Base.showerror(io, e)
                Base.show_backtrace(io, Base.catch_backtrace())
            end

            MATFrost._Write.write_matfrostarray!(out_buf, string(e))
        end
        MATFrost._Stream.flush!(out_buf)

    end
end)

end





end