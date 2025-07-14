include("../essential_definitions/constraint.jl")

struct Location
    name::String
    invariant::Constraint
    flow::Dict{String, ExprLike}
end

function str(location::Location)::String
    return "Location: $(location.name)"
    
end

function enabled_actions(game, location::Location, valuation::Dict{String, Real}, agent::String)::Vector{String}
    actions::Vector{String} = []
    for edge in game.edges
        if edge.start_location == location
            if enabled(edge, valuation) && 
                ! (edge.decision[agent] in actions)
                push!(actions, edge.decision[agent])
            end
        end
    end
    actions
end
