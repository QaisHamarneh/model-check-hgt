include("../game_syntax/game.jl")
include("../game_semantics/configuration.jl")


struct Node
    parent::Union{Node, Nothing}
    reaching_decision::Union{Pair{Agent, Action}, Nothing}
    path_to_node::Union{Vector{Configuration}, Nothing}
    config::Configuration
    children::Vector{Node}
end

function count_nodes(root::Node, level::Int = 0)::Int
    # println("Level: ", level, " - Location ", root.config.location.name, " - Valuation: ",  root.config.valuation)
    @match root begin
        Node(_, _, _, _, []) => 1
        Node(_, _, _, _, children) => 1 + sum(count_nodes(child, level + 1) for child in children)
    end
end

function depth_of_tree(root::Node, level::Int = 1)::Int
    @match root begin
        Node(_, _, _, _, []) => level
        Node(_, _, _, _, children) => maximum(depth_of_tree(child, level + 1) for child in children)
    end
end

function sort_children_by_clock_agent(root::Node, agents::Set{Agent})
    # sorts children by global clock, and if two children have the same clock, the one with the agent's decision comes last
    sort(root.children, by = child -> (child.config.global_clock, child.reaching_decision.first in agents))
end