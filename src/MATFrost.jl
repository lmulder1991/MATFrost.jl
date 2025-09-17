module MATFrost

export @matfrostserve

using Artifacts
using TOML


function _read! end
function _write! end

macro matfrostserve end

struct _MATFrostException <: Exception 
    id::String
    message::String
end


include("constants.jl")

include("stream.jl")

include("read.jl")
include("write.jl")
include("install.jl")
include("register.jl")

include("server.jl")



end
