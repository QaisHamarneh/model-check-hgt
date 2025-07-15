include("../essential_definitions/constraint.jl")

struct Location
    name::Symbol
    invariant::Constraint
    flow::OrderedDict{Symbol, ExprLike}
end

function str(location::Location)::String
    return "Location: $(location.name)"
    
end

function enabled_actions(game, location::Location, valuation::OrderedDict{Symbol, Float64}, agent::Symbol)::Vector{Symbol}
    actions::Vector{Symbol} = []
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
