
import Pkg


Pkg.add("ArtifactUtils")

using MATFrost

MEX_VERSION = if length(ARGS) > 0
    ARGS[1]
else
    "0.5.0-beta.1"
end



using ArtifactUtils
import Pkg

add_artifact!(
    # joinpath(@__FILE__, "..", "..", "..", "Artifacts.toml"), 
    joinpath(pkgdir(MATFrost), "Artifacts.toml"), 
    "matfrost-mex", 
    "https://github.com/ASML-Labs/MATFrost.jl/releases/download/matfrost-mex-v" * MEX_VERSION * "/matfrost-mex-v" * MEX_VERSION * "-win-x64.tar.gz", 
    force=true)
