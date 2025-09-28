module ReadTest

using Test
using JET

using ..Types
using ..BufferPrimitives

using MATFrost: MATFrost
using MATFrost._Read: read_matfrostarray!
using MATFrost._Stream: BufferedStream
using MATFrost._Types


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


stream = BufferedStream(C_NULL, Vector{UInt8}(undef, 2 << 16), 0, 0)


primitive_tests = (
    (Float32, Float32(4321)),
    (Float64, 4321.4321),

    (Int8,  Int8(-21)),
    (UInt8,  UInt8(21)),
    (Int16,  Int16(-4321)),
    (UInt16, UInt16(4321)),
    (Int32,  Int32(-433421)),
    (UInt32, UInt32(43321)),
    (Int64,  Int64(-4323421)),
    (UInt64, UInt64(4323421)),
    
    
)

@testset "Primitives-Behavior-$(pt[1])" for pt in primitive_tests 
    
    @testset "Read-Scalar" begin
        _clearbuffer!(stream)
        _writebuffermatfrostarray!(stream, pt[2])
        stream.available += 20
        v_act = read_matfrostarray!(stream)
        v_exp = MATFrostArrayPrimitive{pt[1]}([1], [pt[2]])

        println(v_act)
        println(v_exp)
        @test deepequal(v_act, v_exp) == true
        @test stream.available - stream.position == 20
    end

    @testset "Read-ComplexScalar" begin
        _clearbuffer!(stream)
        v = Complex{pt[1]}(pt[2], pt[1](2) * pt[2])
        _writebuffermatfrostarray!(stream, v)
        stream.available += 20

        v_act = read_matfrostarray!(stream)
        v_exp = MATFrostArrayPrimitive{Complex{pt[1]}}([1], [v])
        iseq = deepequal(v_act, v_exp)
        @test iseq
        @test stream.available - stream.position == 20
    end

    @testset "Read-Vector" begin
        _clearbuffer!(stream)
        arr = pt[1][pt[2], pt[2]+1, pt[2]+2]
        _writebuffermatfrostarray!(stream, arr)
        stream.available += 20

        
        v_act = read_matfrostarray!(stream)
        v_exp = MATFrostArrayPrimitive{pt[1]}([3], arr)
        iseq = deepequal(v_act, v_exp)
        @test iseq
        @test stream.available - stream.position == 20

    end

    @testset "Read-ComplexVector" begin
        _clearbuffer!(stream)
        v = Complex{pt[1]}(pt[2], pt[1](2) * pt[2])
        arr= Complex{pt[1]}[v + 1, v+2, v+3]
        _writebuffermatfrostarray!(stream, arr)
        stream.available += 20

        
        v_act = read_matfrostarray!(stream)
        v_exp = MATFrostArrayPrimitive{Complex{pt[1]}}([3], arr)
        iseq = deepequal(v_act, v_exp)
        @test iseq
        @test stream.available - stream.position == 20

    end

    @testset "Read-Matrix" begin
        _clearbuffer!(stream)
        arr = Matrix{pt[1]}(undef, (7,5))
        for i in eachindex(arr)
            arr[i] = pt[2] + pt[1](i)
        end
        _writebuffermatfrostarray!(stream, arr)
        stream.available += 20

        
        v_act = read_matfrostarray!(stream)
        v_exp = MATFrostArrayPrimitive{pt[1]}([7, 5], vec(arr))
        iseq = deepequal(v_act, v_exp)
        @test iseq
        @test stream.available - stream.position == 20
        
    end

    @testset "Read-ComplexMatrix" begin
        _clearbuffer!(stream)
        arr = Matrix{Complex{pt[1]}}(undef, (5,7))
        for i in eachindex(arr)
            arr[i] = Complex{pt[1]}(pt[2], pt[1](i)+3)
        end
        _writebuffermatfrostarray!(stream, arr)
        stream.available += 20

        
        v_act = read_matfrostarray!(stream)
        v_exp = MATFrostArrayPrimitive{Complex{pt[1]}}([5, 7], vec(arr))
        iseq = deepequal(v_act, v_exp)
        @test iseq
        @test stream.available - stream.position == 20
        
    end
    

end



# _writebuffermatfrostarray!(stream, Int64[1,2,3])

# v_act = read_matfrostarray!(stream)
# v_exp = MATFrostArrayPrimitive{Int64}(Int64[3], [1,2,3])
# println(v_act)
# println(v_exp)

# println(deepequal(v_act, v_exp))


end