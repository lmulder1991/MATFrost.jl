

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
