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

@matfrostserve