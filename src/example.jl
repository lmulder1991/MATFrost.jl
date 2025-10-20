module Example


multiply_f64(x::Float64, y::Float64) = x*y
multiply_i64(x::Int64, y::Int64) = x*y

multiply_scalar_vector_f64(x::Float64, y::Vector{Float64}) = x .* y


end
