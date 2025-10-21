using Test
using MATFrost._ConvertToMATLAB: convert, CELL

# Helper function: Verify that all pointers in an array are non-null.
function all_valid_pointers(ptrs::Vector{Ptr{T}}) where T
    all(ptr -> ptr != C_NULL, ptrs)
end

@testset "Convert Vector{NamedTuple} to MATLAB struct cell array" begin
    # Create a test input: a vector of NamedTuples.
    nt1 = (a = 1, b = "foo")
    nt2 = (a = 2, b = "bar")
    input_vec = [nt1, nt2]

    # Call the conversion method.
    result = convert(input_vec)

    # Verify that result is a MATFrostArrayMemory configured as a cell array.
    @test result.matfrostarray.type == CELL
    @test result.dims == (Csize_t(length(input_vec)),)

    # Extract the internal data for testing.
    # result.data is a tuple: (pointer array, converted subarrays).
    ptrs, subarrays = result.data

    # Check that the number of pointers equals the number of input elements.
    @test length(ptrs) == length(input_vec)
    # Check that all pointers are valid (i.e., non-null).
    @test all_valid_pointers(ptrs)
    # Ensure that the number of converted objects matches the number of input NamedTuples.
    @test length(subarrays) == length(input_vec)

    # (Optional) If an accessor function is available to extract field values,
    # further tests can be added.
    for (i, nt_conv) in enumerate(subarrays)
        # nt_conv is the MATFrostArrayMemory representing the converted NamedTuple.
        # Its data field holds a tuple: (pointers, fields) where "fields" are converted individually.
        field_ptrs, fields = nt_conv.data
        # fields[2] corresponds to the converted "b" field.
        # The convert(String) method stores data as (Cstring(pointer(s)), s); so we take index 2.
        b_val = fields[2].data[2]
        if i == 1
            @test b_val == "foo"
        elseif i == 2
            @test b_val == "bar"
        end
    end
end