using DifferentialEquations
include("../parsers/parse_constraint.jl")
include("../essential_definitions/evolution.jl")
include("configuration.jl")



function time_to_trigger(config::Configuration, triggers::Vector{<:ExprLike}, max_time::Float64)
    function flowODE!(du, u, p, t)
        current_valuation = valuation_from_vector(config.valuation, u)
        for (i, (var, _)) in enumerate(config.valuation)
            if haskey(config.location.flow, var)
                # Evaluate the flow for the variable
                du[i] = evaluate(config.location.flow[var], current_valuation)
            else
                du[i] = 0.0  # If no flow is defined, assume no change
            end
        end
    end

    function condition(out, u, t, integrator) # Event when condition(out,u,t,integrator) == 0
        for (i, trigger) in enumerate(triggers)
            out[i] = evaluate(trigger, valuation_from_vector(config.valuation, u))
        end
    end

    function affect!(integrator, idx)
        terminate!(integrator) # Stop the integration when the condition is met
    end

    cbv = VectorContinuousCallback(condition, affect!, length(triggers))

    u0 = collect(values(config.valuation))
    tspan = (0.0, max_time)
    prob = ODEProblem(flowODE!, u0, tspan)
    sol = solve(prob, Tsit5(), callback = cbv, dt = 1e-3, adaptive = false)
    
    return valuation_from_vector(config.valuation, sol[end]), sol.t[end]
end


# t1 = time();
# config = Configuration( 
#     Location(:r_r, 
#              parse_constraint("x1 <= 100 && x1 >= -100 && x2 <= 100 && x2 >= -100"), 
#              Dict(:x1 => parse_expression("2"), :x2 => parse_expression("1"))), 
#     OrderedDict(:x1 => -50.0, :x2 => 50.0)
# )

# ttt = time_to_trigger(config, 
#                       [parse_expression("x2 - 90"), parse_expression("x2 - x1")], 
#                       100.0)
# t2 = time();

# println("ttt = $ttt")
# println("Time = $(t2 - t1)")
# println("*************************")