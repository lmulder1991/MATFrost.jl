using Test
using MATFrost

@testset "MATFrost._Server.CallMeta" begin
        name = "MATFrost._Convert.convert_matfrostarray"
        callMeta = MATFrost._Server.CallMeta(name)
        @test callMeta.fully_qualified_name == name
        @test callMeta.signature === ""

        signature = "(:Type{String}, marr::MATFrost._Types.MATFrostArrayAbstract)"
        callMeta = MATFrost._Server.CallMeta(name,signature)
        @test callMeta.fully_qualified_name == name
        @test callMeta.signature == signature

end
@testset "MATFrost._Server.getMethod" begin
    # Test: function with one method
    callMeta = MATFrost._Server.CallMeta("MATFrost._Server.getMethod")
    (f,m) = MATFrost._Server.getMethod(callMeta)
    @test isa(f, Function)
    @test isa(m, Method)

    # Test: function with multiple methods should throw ambiguity error
    callMeta = MATFrost._Server.CallMeta("MATFrost._ConvertToJulia.convert_matfrostarray")
    @test_throws MATFrost._Types.MATFrostException MATFrost._Server.getMethod(callMeta)

    # Test: lower level function with many methods, specific signature
    callMeta = MATFrost._Server.CallMeta("MATFrost._ConvertToJulia.convert_matfrostarray","::Type{String}, marr::MATFrost._Types.MATFrostArrayAbstract")
    (f,m) = MATFrost._Server.getMethod(callMeta)
    @test isa(f, Function)
    @test isa(m, Method)

    # Test: non-existing function should throw error
    callMeta = MATFrost._Server.CallMeta("MATFrost.nonExistentFunction")
    @test_throws ErrorException MATFrost._Server.getMethod(callMeta)
        try
        MATFrost._Server.getMethod(callMeta)
    catch e
        @test occursin("Function MATFrost.nonExistentFunction not found", e.msg)
    end

    # Test: non-existing package should throw error
    callMeta = MATFrost._Server.CallMeta("NonExistentPackage.nonExistentFunction")
    try
        MATFrost._Server.getMethod(callMeta)
    catch e
        @test occursin("Package NonExistentPackage not found", e.msg)
    end
end