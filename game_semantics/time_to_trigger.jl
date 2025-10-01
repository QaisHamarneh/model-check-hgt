using DifferentialEquations
include("../parsers/parse_constraint.jl")
include("../essential_definitions/evolution.jl")
include("configuration.jl")
include("tree.jl")



function time_to_trigger(config::Configuration, trigger::Constraint, properties::Set{Constraint}, max_time::Float64)
    unsatisfied_properties = unsatisfied_constraints(properties, config.valuation)
    zero_properties::Vector{ExprLike} = union_safe([get_zero(prop) for prop in unsatisfied_properties])
    zero_triggers = get_zero(trigger)
    path_to_node::Vector{Configuration} = Vector() # time => (valuation, satisfied_properties)
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
        for (i, zero_prop) in enumerate(zero_properties ∪ zero_triggers)
            out[i] = evaluate(zero_prop, valuation_from_vector(config.valuation, u))
        end
    end

    function affect!(integrator, idx)
        if integrator.t < 1e-5
            return # No need to affect the valuation if the trigger is not active
        end
        current_valuation = round5(valuation_from_vector(config.valuation, integrator.u))
        if evaluate(trigger, current_valuation)
            # println("Terminated")
            terminate!(integrator) # Stop the integration when the condition is met
            return
        end
        if any(zero_prop -> evaluate(zero_prop, current_valuation) == 0.0, zero_properties) && any(prop -> evaluate(prop, current_valuation), unsatisfied_properties)
            push!(path_to_node, Configuration(config.location, current_valuation, config.global_clock + integrator.t))
            unsatisfied_properties = unsatisfied_constraints(properties, current_valuation)
            zero_properties = union_safe([get_zero(prop) for prop in unsatisfied_properties])
            # time = round5(integrator.t)
            # if !haskey(path_to_node, time)
            #     path_to_node[time] = Pair(current_valuation, Set{Constraint}())
            # end
            # for prop in unsatisfied_properties
            #     if evaluate(prop, current_valuation)
            #         push!(path_to_node[time].second, prop)
            #     end
            # end
        end
    end

    cbv = VectorContinuousCallback(condition, affect!, length(zero_properties ∪ zero_triggers)) #, save_positions = false)

    u0 = collect(values(config.valuation))
    tspan = (0.0, max_time + 1e-5)  # Add a small buffer to ensure we capture the trigger time
    prob = ODEProblem(flowODE!, u0, tspan)
    # sol = solve(prob, callback = cbv, dt = 1e-3, adaptive = false)
    sol = solve(prob, Tsit5(), callback = cbv, abstol=1e-6, reltol=1e-6)
    
    final_valuation = valuation_from_vector(config.valuation, sol[end])
    return round5(final_valuation), round5(sol.t[end]), path_to_node
end


# t1 = time();

# valuation = OrderedDict(:x => -5, :y => 5, :dir_x => -5.0, :dir_y => -5.0, :spd_A => 0.1, :spd_B => 0.2, :spd_C => 0.4)
# flow = Dict(:x => parse_expression("spd_A * dir_x"), :y => parse_expression("spd_A * dir_y"))
# config = Configuration( 
#     Location(:r_r, 
#              parse_constraint("x <= 100 && y <= 100"), 
#              flow), 
#     valuation,
#     0.0
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