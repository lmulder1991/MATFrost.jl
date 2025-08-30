
# stream = MATFrost._Stream.BufferedStream(C_NULL, Vector{UInt8}(undef, 2 << 16), 0, 0)




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
        @test read_matfrostarray!(stream, pt[1]).x.x == pt[2]
        @test stream.available - stream.position == 20
    end

    @testset "Read-Vector" begin
        _clearbuffer!(stream)
        arr = pt[1][pt[2], pt[2]+1, pt[2]+2]
        _writebuffermatfrostarray!(stream, arr)
        stream.available += 20
        @test read_matfrostarray!(stream, Vector{pt[1]}).x.x == arr
        @test stream.available - stream.position == 20
        
    end


    @testset "Read-Matrix" begin
        _clearbuffer!(stream)
        arr = Matrix{pt[1]}(undef, (3,3))
        for i in eachindex(arr)
            arr[i] = pt[2] + pt[1](i)
        end
        _writebuffermatfrostarray!(stream, arr)
        stream.available += 20
        @test read_matfrostarray!(stream, Matrix{pt[1]}).x.x == arr
        @test stream.available - stream.position == 20
        
    end
    

end

# @testset "Primitives-JET-Opt" begin
#     @testset "JET-Opt" begin
#         @test_opt read_matfrostarray!(stream, Int64)
#     end
    
#     @testset "JET-Call" begin
#         @test_call read_matfrostarray!(stream, Int64)
#     end

# end