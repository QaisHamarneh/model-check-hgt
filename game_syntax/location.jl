include("../essential_definitions/constraint.jl")

struct Location
    name::Symbol
    invariant::Constraint
    flow::ReAssignment
    edges::Vector
end

function Location(name::Symbol,
                  invariant::Constraint,
                  flow::ReAssignment)::Location
    location = Location(name, invariant, flow, [])
    return location
end

function enabled_actions(config, agent::Agent)::Vector{Action}
    # Change to filter
    actions::Vector{Action} = []
    for edge in config.location.edges
        if enabled(edge, config.valuation) && edge.decision.first == agent && ! (edge.decision.second in actions)
            push!(actions, edge.decision.second)
        end
    end
    actions
end
