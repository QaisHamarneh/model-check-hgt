include("location.jl")

struct Edge
    name::String
    start_location::Location
    target_location::Location
    guard::Constraint
    decision::Dict{String, String}
    jump::Dict{String, ExprLike}
end

function str(edge::Edge)::String
    return "Edge: $(edge.name) from $(edge.start_location.name) to $(edge.target_location.name) with decision: $(edge.decision)"
end

function enabled(edge::Edge, valuation::Dict{String, Real})::Bool
    return evaluate(edge.guard, valuation) && evaluate(edge.target_location.invariant, discrete_evolution(valuation, edge.jump))
end

function select_edge(game, start_location, valuation, decision)::Edge
    for edge in location_edges[start_location]
        if enabled(edge, valuation)
            correct_edge = true
            for agent in game.agents
                if haskey(decision, agent) && haskey(edge.decision, agent) &&
                   edge.decision[agent] != decision[agent]
                    correct_edge = false
                end
            end
            if correct_edge
                return edge
            end
        end
    end
    println("No edge found for decision: $(decision) at location: $(start_location.name)")
    nothing_decision = Dict(agent => "nothing" for agent in game.agents)
    return Edge("nothing", start_location, start_location, Truth(true), nothing_decision, Dict("x" => Const(0), "y" => Const(0)))
end