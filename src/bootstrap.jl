"""
This bootstrap script starts the matfrostserver and is supposed to while spwaning the Julia process.
"""

try
    using MATFrost
catch _
    import Pkg
    Pkg.instantiate()
    try
        using MATFrost
    catch _
        Pkg.add("MATFrost")
        using MATFrost
    end
end

const matfrostin = reinterpret(Ptr{Cvoid},  parse(UInt64, ARGS[1]))
const matfrostout = reinterpret(Ptr{Cvoid}, parse(UInt64, ARGS[2]))


@matfrostserve(matfrostin, matfrostout)
