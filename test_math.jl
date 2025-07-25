using DifferentialEquations
# using Plots; gr()

function f(du, u, p, t)
    du[1] = u[2]
    du[2] = -p
    du[3] = u[4]
    du[4] = 0.0
end

function condition(out, u, t, integrator) # Event when condition(out,u,t,integrator) == 0
    out[1] = u[1]
    out[2] = (u[3] - 10.0)u[3]
end

function affect!(integrator, idx)
    if idx == 1
        integrator.u[2] = -0.9integrator.u[2]
    elseif idx == 2
        integrator.u[4] = -0.9integrator.u[4]
    end
end

cb = VectorContinuousCallback(condition, affect!, 2)

u0 = [50.0, 0.0, 0.0, 2.0]
tspan = (0.0, 15.0)
p = 9.8
prob = ODEProblem(f, u0, tspan, p)
sol = solve(prob, Tsit5(), callback = cb, dt = 1e-3, adaptive = false)

println("Time of first event: ", sol.t[findfirst(t -> t >= 10.0, sol.t)])
println("End of solution: ", sol[end])
