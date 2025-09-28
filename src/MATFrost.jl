module MATFrost

export @matfrostserve

using Artifacts
using TOML


function _read! end
function _write! end

macro matfrostserve end



include("types.jl")
include("constants.jl")

include("stream.jl")

include("read.jl")
include("convert.jl")
include("read_old.jl")
include("write.jl")
include("install.jl")

include("server.jl")



end
