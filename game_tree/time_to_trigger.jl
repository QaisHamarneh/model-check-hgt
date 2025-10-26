using DifferentialEquations
include("../essential_definitions/evolution.jl")
include("../game_semantics/configuration.jl")
include("tree.jl")



function time_to_trigger(config::Configuration, trigger::Constraint, constraints::Set{Constraint}, max_time::Float64)
    unsatisfied_constraints = get_unsatisfied_constraints(constraints, config.valuation)
    zero_constraints::Vector{ExprLike} = union_safe([get_zero(constr) for constr in unsatisfied_constraints])
    zero_triggers = get_zero(trigger)
    path_to_trigger::Vector{Configuration} = Vector()
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
        for (i, zero_constr) in enumerate(zero_constraints ∪ zero_triggers)
            out[i] = evaluate(zero_constr, valuation_from_vector(config.valuation, u))
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
        if any(zero_constr -> evaluate(zero_constr, current_valuation) == 0.0, zero_constraints) && any(constr -> evaluate(constr, current_valuation), unsatisfied_constraints)
            push!(path_to_trigger, Configuration(config.location, current_valuation, config.global_clock + integrator.t))
            unsatisfied_constraints = get_unsatisfied_constraints(constraints, current_valuation)
            for i in eachindex(zero_constraints)
                pop!(zero_constraints)
            end
            for constr in unsatisfied_constraints
                for zero_constr in get_zero(constr)
                    if !(zero_constr in zero_constraints)
                        push!(zero_constraints, zero_constr)
                    end
                end
            end
        end
    end

    cbv = VectorContinuousCallback(condition, affect!, length(zero_constraints ∪ zero_triggers)) #, save_positions = false)

    u0 = collect(values(config.valuation))
    tspan = (0.0, max_time + 1e-5)  # Add a small buffer to ensure we capture the trigger time
    prob = ODEProblem(flowODE!, u0, tspan)
    # sol = solve(prob, callback = cbv, dt = 1e-3, adaptive = false)
    sol = solve(prob, Tsit5(), callback = cbv, abstol=1e-6, reltol=1e-6)
    
    final_valuation = valuation_from_vector(config.valuation, sol[end])
    return round5(final_valuation), round5(sol.t[end]), path_to_trigger
end
