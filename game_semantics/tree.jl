include("../game_syntax/game.jl")
include("../essential_definitions/iliases.jl")
include("../game_semantics/configuration.jl")

struct Node
    parent::Union{Node, Nothing}
    reaching_trigger::Union{Constraint, Nothing}
    reaching_decision::Union{Pair{Agent, Action}, Nothing}
    config::Configuration
    global_clock::Float64
    node_properties::Set{Constraint}
    children::Vector{Node}
end

function str(node::Node)::String
    return "⟨ $(str(node.config)) , $(node.global_clock), childern = $(length(node.children))⟩"
end

function count_nodes(root::Node, level::Int = 0)::Int
    println("Level: ", level, " - Location ", root.config.location.name, " - Valuation: ",  root.config.valuation)
    @match root begin
        Node(_, _, _, _, _, _, []) => 1
        Node(_, _, _, _, _, _, children) => 1 + sum(count_nodes(child, level + 1) for child in children)
    end
end

function depth_of_tree(root::Node, level::Int = 1)::Int
    @match root begin
        Node(_, _, _, _, _, _, []) => level
        Node(_, _, _, _, _, _, children) => maximum(depth_of_tree(child, level + 1) for child in children)
    end
end

struct TriggerPath
    trigger::Constraint
    valuation::Valuation
    time::Float64
    path_properties::Dict{Float64, Pair{Valuation, Set{Constraint}}} # time => (valuation, satisfied_properties)
end