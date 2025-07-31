using DifferentialEquations
include("../parsers/parse_constraint.jl")
include("../essential_definitions/evolution.jl")
include("configuration.jl")



function time_to_trigger(config::Configuration, triggers::Constraint, max_time::Float64)
    atomic_triggers = geq_zero(triggers)
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
        for (i, trigger) in enumerate(atomic_triggers)
            out[i] = evaluate(trigger, valuation_from_vector(config.valuation, u))
        end
    end

    function affect!(integrator, idx)
        if round3(integrator.t) == 0.0
            return # No need to affect the valuation if the trigger is not active
        else
            terminate!(integrator) # Stop the integration when the condition is met
            return 5, 5
        end
    end

    cbv = VectorContinuousCallback(condition, affect!, length(atomic_triggers)) #, save_positions = false)

    u0 = collect(values(config.valuation))
    tspan = (0.0, max_time + 1e-3)  # Add a small buffer to ensure we capture the trigger time
    prob = ODEProblem(flowODE!, u0, tspan)
    # sol = solve(prob, callback = cbv, dt = 1e-3, adaptive = false)
    sol = solve(prob, Tsit5(), callback = cbv, abstol=1e-6, reltol=1e-6)
    
    final_valuation = valuation_from_vector(config.valuation, sol[end])
    return round3(final_valuation), round3(sol.t[end])
end


t1 = time();
config = Configuration( 
    Location(:r_r, 
             parse_constraint("x <= 100 && y <= 100"), 
             Dict(:x => parse_expression("4"), :y => parse_expression("1"))
    ), 
    OrderedDict(:x => -10, :y => 0, :dir_x => 19.5, :dir_y => -0.5, :spd_A => 0.1, :spd_B => 0.2, :spd_C => 0.4)
)

println("Valution = ", evaluate(parse_expression("(((10 - 10.0)^2.0 + 0^2.0) - 0.5)"), OrderedDict(:x => -9.5, :y => 0.5, :dir_x => 19.5, :dir_y => -0.5, :spd_A => 0.1, :spd_B => 0.2, :spd_C => 0.4)))
valuation, ttt = time_to_trigger(config, 
                      parse_constraint("(x - 10.0) + (y - 5) >= 10 && y - 3 >= 3"), 
                      20.0)
t2 = time();

println("valuation = $valuation")
println("ttt = $ttt")
println("Time = $(t2 - t1)")
println("*************************")