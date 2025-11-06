using Test
using MATFrost._Server

@testset "MATFrost._Server.CallMeta" begin
        name = "MATFrost._Convert.convert_matfrostarray"
        callMeta = MATFrost._Server.CallMeta(name)
        @test callMeta.fully_qualified_name == name
        @test callMeta.signature === nothing

        signature = "(:Type{String}, marr::MATFrost._Types.MATFrostArrayAbstract)"
        callMeta = MATFrost._Server.CallMeta(name,signature)
        @test callMeta.fully_qualified_name == name
        @test callMeta.signature == signature

end
@testset "MATFrost._Server.getMethod" begin
    # Test: function with one method
    callMeta = MATFrost._Server.CallMeta("MATFrost._Server.getMethod")
    f = MATFrost._Server.getMethod(callMeta)
    @test isa(f, Method)

    # Test: function with multiple methods should throw ambiguity error
    callMeta = MATFrost._Server.CallMeta("MATFrost._Convert.convert_matfrostarray")
    @test_throws MATFrost._Server.AmbiguityError MATFrost._Server.getMethod(callMeta)


    # Test: lower level function with many methods, specific signature
    callMeta = MATFrost._Server.CallMeta("MATFrost._Convert.convert_matfrostarray","(::Type{String}, marr::MATFrost._Types.MATFrostArrayAbstract)")
    f = MATFrost._Server.getMethod(callMeta)
    @test isa(f, Method)
end