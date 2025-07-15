using DifferentialEquations
include("expression.jl")

# function evaluate_flow(flow_expr::ExprLike, variables::Vector{String}, valuation::Vector{Real})
#     # simplified_flow = simplify(flow_expr)
#     @match flow_expr begin
#         Const(value) => value
#         Var(name) => valuation[findfirst(==(name), variables)]
#         Neg(expr) => -1 * evaluate_flow(expr, variables, valuation)
#         Add(left, right) => evaluate_flow(left, variables, valuation) + evaluate_flow(right, variables, valuation)
#         Mul(left, right) => evaluate_flow(left, variables, valuation) * evaluate_flow(right, variables, valuation)
#         Sub(left, right) => evaluate_flow(left, variables, valuation) - evaluate_flow(right, variables, valuation)
#         Div(left, right) => evaluate_flow(left, variables, valuation) / evaluate_flow(right, variables, valuation)
#         Expon(base, power) => evaluate_flow(base, variables, valuation) ^ evaluate_flow(power, variables, valuation)
#     end
# end

# function continuous_evolution(valuation::Dict{String, Real}, flow, time::Real)::Dict{String, Real}

#     function flowODE!(du, u, p, t)
#         temp_valuation = Dict()
#         for (i, var) in enumerate(valuation)
#             temp_valuation[var] = sol.u[end][i]
#         end
#         for i in eachindex(variables)
#             var = keys(variables)[i]
#             du[i] = evaluate_flow(flow[var], variables, u)
#         end
#     end
#     u0 = values(valuation) |> collect
#     tspan = (0.0, time)
#     prob = ODEProblem(flowODE!, u0, tspan)
#     sol = solve(prob, abstol=1e-8, reltol=1e-8)
#     new_valuation = Dict()
#     for (i, var) in enumerate(variables)
#         new_valuation[var] = sol.u[end][i]
#     end
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