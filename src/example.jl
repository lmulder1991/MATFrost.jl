module Example

hello_world() = "Hello Julia :)"

multiply_f64(x::Float64, y::Float64) = x*y
multiply_i64(x::Int64, y::Int64) = x*y

multiply_scalar_vector_f64(x::Float64, y::Vector{Float64}) = x .* y

function multiply_f64_logging_30s(x::Float64, y::Float64)

    for i in 1:30
        println(string(i))
        sleep(1)
    end

    x*y
end

end
