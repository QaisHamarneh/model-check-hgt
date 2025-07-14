using DifferentialEquations
include("expression.jl")


# function continuous_evolution(valuation::Dict{String, Real}, flow!, time::Real)::Dict{String, Real}

#     function flowODE!(du, u, p, t)
        
#         x, y = u
#         du[1] = y      # pos' = spd
#         du[2] = 2.0      # spd' = constant acceleration 5
#     end
#     u0 = [valuation["x"], valuation["y"]]
#     tspan = (0.0, time)
#     prob = ODEProblem(flow!, u0, tspan)
#     sol = solve(prob, abstol=1e-8, reltol=1e-8)
#     new_valuation = Dict("x" => sol[end][1], "y" => sol[end][2])
#     return new_valuation
# end

function continuous_evolution(valuation::Dict{String, Real}, 
                              flow::Dict{String, ExprLike}, 
                              time::Real)::Dict{String, Real}
    new_valuation::Dict{String, Real} = copy(valuation)
    for (var, value) in valuation
        if haskey(flow, var)
            new_valuation[var] = value + time * evaluate(flow[var], valuation)
        else
            new_valuation[var] = value
        end
    end
    new_valuation
end

function discrete_evolution(valuation::Dict{String, Real}, 
                            jump::Dict{String, ExprLike})::Dict{String, Real}
    new_valuation::Dict{String, Real} = copy(valuation)
    for (var, value) in valuation
        if haskey(jump, var)
            new_valuation[var] = evaluate(jump[var], new_valuation)
        else
            new_valuation[var] = value
        end
    end
    new_valuation
end