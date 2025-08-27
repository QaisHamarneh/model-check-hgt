using DifferentialEquations
include("../parsers/parse_constraint.jl")
include("../essential_definitions/evolution.jl")
include("configuration.jl")



function time_to_trigger(config::Configuration, trigger::Constraint, max_time::Float64)
    zero_triggers::Vector{ExprLike} = geq_zero(trigger)
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
        for (i, zero_trigger) in enumerate(zero_triggers)
            out[i] = evaluate(zero_trigger, valuation_from_vector(config.valuation, u))
        end
    end

    function affect!(integrator, idx)
        if round3(integrator.t) == 0.0
            return # No need to affect the valuation if the trigger is not active
        end
        current_valuation = valuation_from_vector(config.valuation, integrator.u)
        # println("Trigger condition met at time $(integrator.t): $(zero_triggers[idx]) - Valuation: $current_valuation")
        # println("The trigger is: ", trigger)
        if evaluate(trigger, round3(current_valuation))
            # println("Terminated")
            terminate!(integrator) # Stop the integration when the condition is met
        else
            return 
        end
    end

    cbv = VectorContinuousCallback(condition, affect!, length(zero_triggers)) #, save_positions = false)

    u0 = collect(values(config.valuation))
    tspan = (0.0, max_time + 1e-3)  # Add a small buffer to ensure we capture the trigger time
    prob = ODEProblem(flowODE!, u0, tspan)
    # sol = solve(prob, callback = cbv, dt = 1e-3, adaptive = false)
    sol = solve(prob, Tsit5(), callback = cbv, abstol=1e-6, reltol=1e-6)
    
    final_valuation = valuation_from_vector(config.valuation, sol[end])
    return round3(final_valuation), round3(sol.t[end])
end


# t1 = time();

# valuation = OrderedDict(:x => -5, :y => 5, :dir_x => -5.0, :dir_y => -5.0, :spd_A => 0.1, :spd_B => 0.2, :spd_C => 0.4)
# flow = Dict(:x => parse_expression("spd_A * dir_x"), :y => parse_expression("spd_A * dir_y"))
# config = Configuration( 
#     Location(:r_r, 
#              parse_constraint("x <= 100 && y <= 100"), 
#              flow), 
#     valuation
# )

# trigger = And(And(LeQ(Const(-9.5), Var(:x)), LeQ(Var(:x), Const(-10.5))), And(LeQ(Const(-0.5), Var(:y)), LeQ(Var(:y), Const(0.5))))
# new_valuation, ttt = time_to_trigger(config, 
#                       trigger, 
#                       50.0)
# t2 = time();

# println("valuation = $new_valuation")
# println("ttt = $ttt")
# println("Time = $(t2 - t1)")
# println("*************************")


# valuation = OrderedDict(:x => -9.499823194984256, :y => 0.5001768050157437, :dir_x => -5.0, :dir_y => -5.0, :spd_A => 0.1, :spd_B => 0.2, :spd_C => 0.4)
# trigger = And(
#             And(
#                 LeQ(Const(-9.5), Var(:x)), 
#                 LeQ(Var(:x), Const(-10.5))), 
#             And(
#                 LeQ(Const(-0.5), Var(:y)), 
#                 LeQ(Var(:y), Const(0.5)))
#             )
# println(evaluate(trigger, valuation))
# println("*************************")