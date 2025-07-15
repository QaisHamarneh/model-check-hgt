include("expression.jl")

using DifferentialEquations
using DataStructures

function continuous_evolution(valuation::OrderedDict{Symbol, Float64}, 
                              flow::OrderedDict{Symbol, <:ExprLike},
                              time::Float64)::OrderedDict{Symbol, Float64}
    function flowODE!(du, u, p, t)
        # temp_valuation::OrderedDict{Symbol, Real} = Dict()
        temp_valuation::OrderedDict{Symbol, Float64} = Dict()
        for (i, (var, _)) in enumerate(valuation)
            temp_valuation[var] = u[i]
        end
        for (i, (var, _)) in enumerate(valuation)
            du[i] = evaluate(flow[var], temp_valuation)
        end
    end
    u0 = values(valuation) |> collect
    tspan = (0.0, time)
    prob = ODEProblem(flowODE!, u0, tspan)
    sol = solve(prob, abstol=1e-8, reltol=1e-8)
    # new_valuation::OrderedDict{Symbol, Real} = OrderedDict()
    new_valuation::OrderedDict{Symbol, Float64} = OrderedDict()
    for (i, (var, _)) in enumerate(valuation)
        new_valuation[var] = sol.u[end][i]
    end
    return new_valuation
end

function discrete_evolution(valuation::OrderedDict{Symbol, Float64}, 
                            jump::OrderedDict{Symbol, <:ExprLike})::OrderedDict{Symbol, Float64}
    # new_valuation::OrderedDict{Symbol, Real} = copy(valuation)
    new_valuation::OrderedDict{Symbol, Float64} = copy(valuation)
    for (var, expr) in jump
        new_valuation[var] = evaluate(expr, new_valuation)
    end
    new_valuation
end


# discrete_evolution(OrderedDict(:x => 1.0, :y => 2.0), 
#                    OrderedDict(:x => Var(:x), :y => Mul(Add(Const(5), Var(:x)), Var(:y))))

# continuous_evolution(OrderedDict(:x => 1.0, :y => 0.0), OrderedDict(:x => Var(:x), :y => Const(2.0)), 4.0)
# continuous_evolution(OrderedDict(:x => 0.0, :y => 0.0), OrderedDict(:x => Var(:y), :y => Const(2.0)), 4.0)