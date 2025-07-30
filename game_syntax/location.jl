include("../essential_definitions/constraint.jl")

struct Location
    name::Symbol
    invariant::Constraint
    flow::Dict{Symbol, ExprLike}
    edges::Vector
end

function Location(name::Symbol,
                  invariant::Constraint,
                  flow::Dict{Symbol, <:ExprLike})::Location
    location = Location(name, invariant, flow, [])
    return location
end

function str(location::Location)::String
    return "Location: $(location.name)"
end

function enabled_actions(config, agent::Symbol)::Vector{Symbol}
    # Change to filter
    actions::Vector{Symbol} = []
    for edge in config.location.edges
        if enabled(edge, config.valuation) && haskey(edge.decision, agent) && ! (edge.decision[agent] in actions)
            push!(actions, edge.decision[agent])
        end
    end
    actions
end
