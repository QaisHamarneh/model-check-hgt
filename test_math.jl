# using DifferentialEquations
# # using Plots; gr()


# f(u,p,t) = 0.98u
# u0 = 1.0
# tspan = (0.0,1.0)
# prob = ODEProblem(f,u0,tspan)

# sol = solve(prob)
# sol
# plot(sol)


using DifferentialEquations
# using Plots; gr()

# Define the ODE system
function car_dynamics!(du, u, p, t)
    pos, spd = u
    du[1] = spd      # pos' = spd
    du[2] = 5.0      # spd' = constant acceleration 5
end

# Initial state: pos=0, spd=0
u0 = [0.0, 0.0]
tspan = (0.0, 10.0)  # Large enough time span

prob = ODEProblem(car_dynamics!, u0, tspan)

# # Define the condition for F: pos >= 10000 or spd >= 100
# function condition(u, t, integrator)
#     # return u[2] - 100
#     return max(u[1] - 10000, u[2] - 100)  # triggers when either crosses threshold
# end

# # What to do when F is satisfied (stop integration)
# function affect!(integrator)
#     println("Formula F satisfied at time t = ", integrator.t)
#     terminate!(integrator)  # stop solving
# end

# cb = ContinuousCallback(condition, affect!)

# # Solve with callback
# sol = solve(prob, callback=cb, abstol=1e-8, reltol=1e-8)
sol = solve(prob, abstol=1e-8, reltol=1e-8)
sol[end]
# plot(sol)