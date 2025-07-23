using DifferentialEquations
using Plots # For visualization, optional

# 1. Define the system of differential equations (in-place for performance)
function system_of_odes!(du, u, p, t)
    x, y, z = u
    du = y          # dx/dt = y
    du = -0.5*y - 10.0*x # dy/dt = -0.5y - 10x (damped oscillator)
    du = -0.1*z     # dz/dt = -0.1z (exponential decay)
end

# 2. Define initial conditions and time span
u0 = [1.0, 0.0, 10.0] # Initial values for x, y, z
tspan = (0.0, 100.0)  # Time span for the simulation

# Initialize a mutable container to store the event details
# This will be updated inside the affect! function
mutable struct EventResult
    time::Float64
    state::Vector{Float64}
    triggered_constraint_idx::Int
    found::Bool
end
event_data = EventResult(0.0, zeros(length(u0)), 0, false)

# 3. Define the condition function for VectorContinuousCallback
# This function writes the values of the constraint functions into the 'out' array.
# An event triggers when any out[i] hits zero.
function constraints_condition(out, u, t, integrator)
    x, y, z = u
    
    # Constraint 1: x crosses zero from above (x <= 0)
    # We want to detect when x becomes <= 0. So the condition function is x.
    # We will use affect_pos! = nothing to trigger only when x goes from positive to negative/zero.
    out = x

    # Constraint 2: z drops below 2.0 (z <= 2.0)
    # Condition function is z - 2.0. We want to detect when it goes from positive to negative/zero.
    out = z - 2.0

    # Constraint 3: y becomes positive (y > 0)
    # Condition function is y. We want to detect when it goes from negative to positive/zero.
    # We will use affect_neg! = nothing to trigger only on up-crossing.
    out = y
end

# 4. Define the affect! function for VectorContinuousCallback
# This function is executed when a condition is met.
# It stores the event data and terminates the integration.
function constraints_affect!(integrator, event_index)
    # Store the exact time and state at which the event occurred
    event_data.time = integrator.t
    event_data.state = copy(integrator.u) # Copy to avoid mutation issues later
    event_data.triggered_constraint_idx = event_index
    event_data.found = true
    
    # Terminate the integration immediately upon the first event
    terminate!(integrator)[11, 13, 14]
end

# 5. Create the VectorContinuousCallback
# 'len' is the number of conditions being monitored.
# 'save_positions=(true,true)' ensures data fidelity at the event point.
# 'affect_pos!' and 'affect_neg!' are used for directional crossings.
# For out (x <= 0), we want a down-crossing (positive to negative/zero), so affect_pos! = nothing is not used, but affect_neg! is implicitly used.
# For out (z <= 2.0), we want a down-crossing (positive to negative/zero), so affect_pos! = nothing is not used, but affect_neg! is implicitly used.
# For out (y > 0), we want an up-crossing (negative to positive/zero), so affect_neg! = nothing.
cb = VectorContinuousCallback(
    constraints_condition,
    constraints_affect!,
    3, # len = 3 conditions
    save_positions=(true,true), # Save state exactly at event time [5, 15]
    affect_pos! = [nothing, nothing, constraints_affect!], # Only affect for positive crossing of y (index 3)
    affect_neg! = [constraints_affect!, constraints_affect!, nothing] # Only affect for negative crossing of x (index 1) and z-2.0 (index 2)
)

# 6. Construct the ODEProblem
prob = ODEProblem(system_of_odes!, u0, tspan) [1, 2]

# 7. Solve the ODE problem with the callback and specified tolerances
# Using Tsit5() for a non-stiff system.
# Setting tight tolerances for "exact" event detection.
sol = solve(prob, Tsit5(), callback=cb, abstol=1e-9, reltol=1e-7) [4, 10]

# 8. Retrieve and display the results
if event_data.found
    println("First constraint satisfied at exact time: $(event_data.time)")
    println("Variable valuations at event: x=$(event_data.state), y=$(event_data.state), z=$(event_data.state)")
    println("Triggered constraint index: $(event_data.triggered_constraint_idx)")
    
    # Optional: Plot the solution up to the event time
    plot(sol, vars=(1,2,3), label=["x(t)" "y(t)" "z(t)"], title="System Evolution with Event Termination")
    vline!([event_data.time], linestyle=:dash, color=:red, label="Event Time")
else
    println("No constraint was satisfied within the given time span.")
end

# Example of accessing the final state from the solution object (if terminated by callback)
if sol.retcode == :Terminated
    println("\nSolver terminated by callback.")
    println("Time from sol object: $(sol.t[end])")
    println("State from sol object: $(sol.u[end])")
end