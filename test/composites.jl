

struct StructTest1
    a::Float64
    b::Int64
    d::String
end

struct StructTest2
    a::Complex{Float64}
    b::Complex{Int64}
end

struct StructTest3
    nest_scalar::StructTest1
    nest_vector::Vector{StructTest1}
    nest_matrix::Matrix{StructTest1}
    struct2::StructTest2
end


struct StructTest4
    tup_scalar::Tuple{String, Int64, Float64}
    tup_vector::Vector{Tuple{String, Int64, Float64}}
    namedtup_scalar::@NamedTuple{v1::Float64, v2::String}
    namedtup_vector::Vector{@NamedTuple{v1::Float64, v2::String}}
    nest_vector::Vector{StructTest3}

end


stream = BufferedStream(C_NULL, Vector{UInt8}(undef, 2 << 20), 0, 0)

"""
Scalar: Number, String
Array: Number, String
"""
function deepequal(a::T, b::T) where {T<:Union{Number, String, Array{<:Number}, Array{String}}} 
    return a==b
end

"""
Array: Structs, NamedTuple, Tuple
"""
function deepequal(a::Array, b::Array)
    typeof(a) == typeof(b) || return false
    size(a) == size(b)     || return false
    for i in eachindex(a)
        deepequal(a[i], b[i]) || return false
    end
    return true
end

"""
Scalar: Structs, NamedTuple, Tuple
"""
function deepequal(a, b)
    typeof(a) == typeof(b) || return false
    N = fieldcount(typeof(a))
    for i in 1:N
        deepequal(getfield(a, i), getfield(b, i)) || return false
    end
    return true
end

@testset "Simple struct" begin
    _clearbuffer!(stream)
    v = StructTest1(3.0, 3, "Test1234")
    _writebuffermatfrostarray!(stream, v)
    stream.available += 20
    @test read_matfrostarray!(stream, StructTest1).x.x == v
    @test stream.available - stream.position == 20
end


@testset "Vector of structs" begin
    _clearbuffer!(stream)
    v1 = StructTest1(3.0, 3, "Test1234")
    v2 = StructTest1(5.0, 1, "Test4321")
    v3 = StructTest1(27.5, 133, "Test1111")

    arr = StructTest1[v1, v2, v3, v1, v3, v2]
    _writebuffermatfrostarray!(stream, arr)
    stream.available += 20
    @test read_matfrostarray!(stream, Vector{StructTest1}).x.x == arr
    @test stream.available - stream.position == 20
end



@testset "Simple Tuple" begin
    _clearbuffer!(stream)
    v = (3223,3.0,3,"EWFW")
    _writebuffermatfrostarray!(stream, v)
    stream.available += 20
    @test read_matfrostarray!(stream, Tuple{Int64, Float64, Int64, String}).x.x == v
    @test stream.available - stream.position == 20
end

@testset "Vector of tuple" begin
    _clearbuffer!(stream)
    v1 = (3223,3.0,5,"12Test34")
    v2 = (544,632.0,23,"44Test44")
    v3 = (345,-6851.0,43,"1111")

    arr = Tuple{Int64, Float64, Int64, String}[v1, v2, v3, v1, v3, v2]
    _writebuffermatfrostarray!(stream, arr)
    stream.available += 20
    @test read_matfrostarray!(stream, Vector{Tuple{Int64, Float64, Int64, String}}).x.x == arr
    @test stream.available - stream.position == 20
end


@testset "Simple NamedTuple" begin
    _clearbuffer!(stream)
    NT = NamedTuple{(:v1, :v2, :v3, :v4), Tuple{Int64, Float64, Int64, String}}
    v = NT((3223,3.0,3,"EWFW"))
    _writebuffermatfrostarray!(stream, v)
    stream.available += 20
    @test read_matfrostarray!(stream, NT).x.x == v
    @test stream.available - stream.position == 20
end

@testset "Vector of NamedTuple" begin
    _clearbuffer!(stream)
    NT = NamedTuple{(:v1, :v2, :v3, :v4), Tuple{Int64, Float64, Int64, String}}
    v1 = NT((3223,3.0,5,"12Test34"))
    v2 = NT((544,632.0,23,"44Test44"))
    v3 = NT((345,-6851.0,43,"1111"))

    arr = NT[v1, v2, v3, v1, v3, v2]
    _writebuffermatfrostarray!(stream, arr)
    stream.available += 20
    @test read_matfrostarray!(stream, Vector{NT}).x.x == arr
    @test stream.available - stream.position == 20
end



@testset "Nested struct" begin
    _clearbuffer!(stream)
    v1 = StructTest1(3.0, 3, "Test1234")
    v2 = StructTest1(5.0, 1, "Test4321")
    v3 = StructTest1(27.5, 133, "Test1111")

    v4 = StructTest2(Complex{Float64}(3.0,4.3), Complex{Int64}(3,4))

    nest = StructTest3(
        v1,
        StructTest1[v1,v2,v3,v1],
        StructTest1[v1 v2 v3 v2; v3 v1 v3 v2],
        v4
    )


    _writebuffermatfrostarray!(stream, nest)
    stream.available += 20
    presult = read_matfrostarray!(stream, StructTest3).x.x
    @test deepequal(presult, nest)
    @test stream.available - stream.position == 20
end
