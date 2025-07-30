include("location.jl")

struct Edge
    name::Symbol
    start_location::Location
    target_location::Location
    guard::Constraint
    decision::Dict{Symbol, Symbol}
    jump::OrderedDict{Symbol, ExprLike}
end

function str(edge::Edge)::Symbol
    return "Edge: $(edge.name) from $(edge.start_location.name) to $(edge.target_location.name) with decision: $(edge.decision)"
end

function enabled(edge::Edge, valuation::OrderedDict{Symbol, Float64})::Bool
    return evaluate(edge.guard, valuation) && evaluate(edge.target_location.invariant, discrete_evolution(valuation, edge.jump))
end

function select_edge(game, config, decision::Dict{Symbol, Symbol})::Edge
    # Clean up and ensure the correct handling of the nothing actions
    for edge in config.location.edges
        if enabled(edge, config.valuation)
            correct_edge = true
            for agent in game.agents
                if haskey(decision, agent) && haskey(edge.decision, agent) &&
                   edge.decision[agent] != decision[agent]
                    correct_edge = false
                    break
                end
            end
            if correct_edge
                return edge
            end
        end
    end
    return location.edges[1]  # Default to the stutter edge if no valid edge is found
end