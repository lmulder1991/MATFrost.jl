using Test
using MATFrost

names = [
    "MATFrost._Server.connect",
    "MATFrost._Convert.convert_matfrostarray",
    "MATFrost._Convert.convert_matfrostarray(::Type{String}, marr::MATFrost._Types.MATFrostArrayAbstract)"
]

@testset "MATFrost._Server.getMethod" begin
    # Test: function with one method
    f = MATFrost._Server.getMethod(MATFrost._Server.CallMeta(names[1]))
    @test isa(f, Method)

    # Test: function with multiple methods should throw ambiguity error
    @test_throws ErrorException MATFrost._Server.getMethod(MATFrost._Server.CallMeta(names[2]))

    # Test: lower level function with many methods, specific signature
    f = MATFrost._Server.getMethod(MATFrost._Server.CallMeta(names[3]))
    @test isa(f, Method)
end