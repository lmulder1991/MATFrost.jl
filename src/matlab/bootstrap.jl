"""
The bootstrap script for launching the matfrostserver.
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

const socket_path = ARGS[1]

matfrostserve(socket_path)
