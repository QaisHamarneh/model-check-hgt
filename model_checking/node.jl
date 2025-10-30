include("../game_syntax/game.jl")
include("../game_semantics/configuration.jl")


mutable struct NodeOnDemand
    parent::Union{NodeOnDemand, Nothing}
    reaching_decision::Union{Pair{Agent, Action}, Nothing}
    passive_node::Bool
    config::Configuration
    terminal_node::Bool
    children::Vector{NodeOnDemand}
    children_built::Bool
end

function count_nodes_on_demand(root::NodeOnDemand)::Int
    # println("Level: ", level, " - Location ", root.config.location.name, " - Valuation: ",  root.config.valuation)
    @match root begin
        NodeOnDemand(_, _, _, _, true, _, _) => 1
        NodeOnDemand(_, _, _, _, _, [], _) => 1
        NodeOnDemand(_, _, _, _, _, children, _) => 1 + sum(count_nodes_on_demand(child) for child in children)
    end
end

function count_passive_nodes_on_demand(root::NodeOnDemand)::Int
    # println("Level: ", level, " - Location ", root.config.location.name, " - Valuation: ",  root.config.valuation)
    @match root begin
        NodeOnDemand(_, _, passive, _, true, _, _) => Int(passive)
        NodeOnDemand(_, _, passive, _, _, [], _) => Int(passive)
        NodeOnDemand(_, _, passive, _, _, children, _) => Int(passive) + sum(count_passive_nodes_on_demand(child) for child in children)
    end
end

function depth_of_tree_on_demand(root::NodeOnDemand, level::Int = 1)::Int
    @match root begin
        NodeOnDemand(_, _, _, _, _, [], _) => level
        NodeOnDemand(_, _, passive, _, _, children, _) => maximum(depth_of_tree_on_demand(child, level + Int(!passive)) for child in children)
    end
end

function child_time_on_demand(child::NodeOnDemand)::Float64
    if child.passive_node && ! child.terminal_node
        return child_time_on_demand(child.children[1])
    else
        return child.config.global_clock
    end
end

function sort_children_by_clock_on_demand!(root::NodeOnDemand)
    # sorts children by global clock, and if two children have the same clock, the one with the agent's decision comes last
    sort!(root.children, by = child -> child_time_on_demand(child))
end

function sort_children_by_clock_agent_on_demand(root::NodeOnDemand, agents::Set{Agent})
    # sorts children by global clock, and if two children have the same clock, the one with the agent's decision comes last
    sort(root.children, by = child -> (child_time_on_demand(child), child.reaching_decision.first in agents))
end