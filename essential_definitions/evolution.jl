include("expression.jl")
include("helper_functions.jl")

using DifferentialEquations
using DataStructures


function continuous_evolution(valuation::OrderedDict{Symbol, Float64}, 
                              flow::Dict{Symbol, <:ExprLike},
                              time::Float64)::OrderedDict{Symbol, Float64}
    function flowODE!(du, u, p, t)
        current_valuation::OrderedDict{Symbol, Float64} = valuation_from_vector(valuation, u)
        for (i, (var, _)) in enumerate(valuation)
            du[i] = evaluate(flow[var], current_valuation)
        end
    end
    u0 = values(valuation) |> collect
    tspan = (0.0, time)
    prob = ODEProblem(flowODE!, u0, tspan)
    sol = solve(prob, abstol=1e-8, reltol=1e-8)
    new_valuation::OrderedDict{Symbol, Float64} = valuation_from_vector(valuation, sol.u[end])
    return round3(new_valuation)
end

function discrete_evolution(valuation::OrderedDict{Symbol, Float64}, 
                            jump::OrderedDict{Symbol, <:ExprLike})::OrderedDict{Symbol, Float64}
    new_valuation::OrderedDict{Symbol, Float64} = copy(valuation)
    for (var, expr) in jump
        new_valuation[var] = evaluate(expr, new_valuation)
    end
    return round3(new_valuation)
end


# discrete_evolution(OrderedDict(:x => 1.0, :y => 2.0), 
#                    OrderedDict(:x => Var(:x), :y => Mul(Add(Const(5), Var(:x)), Var(:y))))

# continuous_evolution(OrderedDict(:x => 1.0, :y => 0.0), Dict(:x => Var(:x), :y => Const(2.0)), 4.0)
# continuous_evolution(OrderedDict(:x => 0.0, :y => 0.0), Dict(:x => Var(:y), :y => Const(2.0)), 4.0)