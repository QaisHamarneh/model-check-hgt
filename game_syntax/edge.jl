include("location.jl")

struct Edge
    name::Symbol
    start_location::Location
    target_location::Location
    guard::Constraint
    decision::Decision
    jump::ReAssignment
end

function enabled(edge::Edge, valuation::Valuation)::Bool
    return evaluate(edge.guard, valuation) && evaluate(edge.target_location.invariant, discrete_evolution(valuation, edge.jump))
end

function select_edges(game, config, decision::Decision)::Vector{Edge}
    selected_edges = Edge[]
    for edge in config.location.edges
        if enabled(edge, config.valuation) && edge.decision == decision
            push!(selected_edges, edge)
        end
    end
    return selected_edges
end