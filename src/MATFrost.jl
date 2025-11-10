module MATFrost

using Artifacts
using TOML


function _read! end
function _write! end

function matfrostserve end



include("types.jl")
include("constants.jl")

include("stream.jl")

include("read.jl")
include("converttojulia.jl")
include("converttomatlab.jl")
include("write.jl")

include("server.jl")

include("example.jl")

include("install.jl")

end
