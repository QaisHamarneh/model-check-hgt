include("../game_syntax/game.jl")
include("../game_semantics/configuration.jl")


mutable struct Node
    parent::Union{Node, Nothing}
    reaching_decision::Union{Pair{Agent, Action}, Nothing}
    passive_node::Bool
    config::Configuration
    terminal_node::Bool
    children::Vector{Node}
end

function count_nodes(root::Node)::Int
    # println("Level: ", level, " - Location ", root.config.location.name, " - Valuation: ",  root.config.valuation)
    @match root begin
        Node(_, _, _, _, true, _) => 1
        Node(_, _, _, _, _, []) => 1
        Node(_, _, _, _, _, children) => 1 + sum(count_nodes(child) for child in children)
    end
end

function count_passive_nodes(root::Node)::Int
    # println("Level: ", level, " - Location ", root.config.location.name, " - Valuation: ",  root.config.valuation)
    @match root begin
        Node(_, _, passive, _, true, _) => Int(passive)
        Node(_, _, passive, _, _, []) => Int(passive)
        Node(_, _, passive, _, _, children) => Int(passive) + sum(count_passive_nodes(child) for child in children)
    end
end

function depth_of_tree(root::Node, level::Int = 1)::Int
    @match root begin
        Node(_, _, _, _, _, []) => level
        Node(_, _, passive, _, _, children) => maximum(depth_of_tree(child, level + Int(!passive)) for child in children)
    end
end

function child_time(child::Node)::Float64
    if child.passive_node && ! child.terminal_node
        return child_time(child.children[1])
    else
        return child.config.global_clock
    end
end

function sort_children_by_clock!(root::Node)
    # sorts children by global clock, and if two children have the same clock, the one with the agent's decision comes last
    sort!(root.children, by = child -> child_time(child))
end

function sort_children_by_clock_agent(root::Node, agents::Set{Agent})
    # sorts children by global clock, and if two children have the same clock, the one with the agent's decision comes last
    sort(root.children, by = child -> (child_time(child), child.reaching_decision.first in agents))
end