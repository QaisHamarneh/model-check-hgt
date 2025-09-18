include("../game_syntax/game.jl")

struct Node
    config::Configuration
    global_clock::Float64
    children::Vector{Node}
end

function str(node::Node)::String
    return "⟨ $(str(node.config)) , $(node.global_clock), childern = $(length(node.children))⟩"
end

function count_nodes(root::Node, level::Int = 0)::Int
    println("Level: ", level, " - Location ", root.config.location.name, " - Valuation: ",  root.config.valuation)
    @match root begin
        Node(config, _, []) => 1
        Node(_, _, children) => 1 + sum(count_nodes(child, level + 1) for child in children)
    end
end

function depth_of_tree(root::Node, level::Int = 1)::Int
    @match root begin
        Node(_, _, []) => level
        Node(_, _, children) => maximum(depth_of_tree(child, level + 1) for child in children)
    end
end




function binary(root::Node)::Bool
    @match root begin
        Node(_, _, []) =>  true
        Node(_, _, children) => 
            if length(children) == 2
                return all(binary(child) for child in children)
            else
                return false
            end
    end
end