using DifferentialEquations


function continuous_evolution(valuation::Dict{String, Real}, flow!, time::Real)::Dict{String, Real}
    u0 = [valuation["x"], valuation["y"]]
    tspan = (0.0, time)
    prob = ODEProblem(flow!, u0, tspan)
    sol = solve(prob, abstol=1e-8, reltol=1e-8)
    new_valuation = Dict("x" => sol[end][1], "y" => sol[end][2])
    return new_valuation
end

# function continuous_evolution(valuation::Dict{String, Real}, 
#                               flow::Dict{String, Real}, 
#                               time::Real)::Dict{String, Real}
#     new_valuation::Dict{String, Real} = Dict()
#     for (var, value) in valuation
#         if haskey(flow, var)
#             new_valuation[var] = value + time * flow[var]
#         else
#             new_valuation[var] = value
#         end
#     end
#     new_valuation
# end

function discrete_evolution(valuation::Dict{String, Real}, 
                            jump::Dict{String, Real})::Dict{String, Real}
    new_valuation::Dict{String, Real} = Dict()
    for (var, value) in valuation
        if haskey(jump, var)
            new_valuation[var] = value + jump[var]
        else
            new_valuation[var] = value
        end
    end
    new_valuation
end