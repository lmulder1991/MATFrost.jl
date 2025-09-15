# try
#     using MATFrost
# catch _
#     import Pkg
#     Pkg.instantiate()
#     try
#         using MATFrost
#     catch _
#         Pkg.add("MATFrost")
#         using MATFrost
#     end
# end

# @matfrostserve

open(raw"C:\Users\jbelier\Documents\GitHub\MATFrost.jl\src\matfrostjuliacall\testfile1234.txt", "w") do io
    println(io, "WEFWEF")
    println(io, ARGS[1])
    println(io, ARGS[2])
    
end