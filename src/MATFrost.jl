module MATFrost

export @matfrostserve, matfrostserve

using Artifacts
using TOML


function _read! end
function _write! end

macro matfrostserve end
function matfrostserve end



include("types.jl")
include("constants.jl")

include("stream.jl")

include("read.jl")
include("convert.jl")
include("write.jl")
include("install.jl")

include("server.jl")

include("example.jl")



end
