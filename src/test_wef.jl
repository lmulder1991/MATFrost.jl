

s1 = "julia"
s2 = "julia +1.11 -e 'println(4)'"


s1 = raw"C:\Users\jbelier\.julia\juliaup\julia-1.12.0-rc1+0.x64.w64.mingw32\bin\julia.exe"

s2 = raw"julia -e 'println(4)'"
r1 = Ref{NTuple{20, Int64}}()
r2 = Ref{NTuple{20, Int64}}()


@ccall "kernel32".CreateProcessW(
    pointer(s1)::Cstring,
    pointer(s2)::Cstring,
    C_NULL::Ptr{UInt8},
    C_NULL::Ptr{UInt8},
    false::Bool,
    Int32(0)::Cint,
    C_NULL::Ptr{UInt8},
    C_NULL::Ptr{UInt8},
    r1::Ref{NTuple{20, Int64}},
    r2::Ref{NTuple{20, Int64}})::Cint




    
s1 = raw"C:\Users\jbelier\.julia\juliaup\julia-1.12.0-rc1+0.x64.w64.mingw32\bin\julia.exe"

s2 = raw"\"C:\Users\jbelier\.julia\juliaup\julia-1.12.0-rc1+0.x64.w64.mingw32\bin\julia.exe\" \"C:\Users\jbelier\testscript.jl\""

# s2 = "\"$(s1)\" -e 'println(4)'"

r1 = Ref{NTuple{40, Int32}}((Int32(104), ntuple(_ -> Int32(0), 39)...))
r2 = Ref{NTuple{20, Int64}}()


@ccall "kernel32".CreateProcessA(
    C_NULL::Cstring,
    pointer(s2)::Cstring,
    C_NULL::Ptr{UInt8},
    C_NULL::Ptr{UInt8},
    UInt8(0)::UInt8,
    Int32(0)::Cint,
    C_NULL::Ptr{UInt8},
    C_NULL::Ptr{UInt8},
    r1::Ref{NTuple{40, Int32}},
    r2::Ref{NTuple{20, Int64}})::Cint



    
    
s2 = raw"julia.exe \"C:\Users\jbelier\testscript.jl\""

# s2 = "\"$(s1)\" -e 'println(4)'"

r1 = Ref{NTuple{40, Int32}}((Int32(104), ntuple(_ -> Int32(0), 39)...))
r2 = Ref{NTuple{20, Int64}}()


@ccall "kernel32".CreateProcessA(
    C_NULL::Cstring,
    pointer(s2)::Cstring,
    C_NULL::Ptr{UInt8},
    C_NULL::Ptr{UInt8},
    UInt8(0)::UInt8,
    Int32(0)::Cint,
    C_NULL::Ptr{UInt8},
    C_NULL::Ptr{UInt8},
    r1::Ref{NTuple{40, Int32}},
    r2::Ref{NTuple{20, Int64}})::Cint