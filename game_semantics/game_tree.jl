include("discrete_transitions.jl")
include("continuous_transitions.jl")

using IterTools

struct Node
    config::Configuration
    global_clock::Real
    children::Vector{Node}
end

function str(node::Node)::String
    return "⟨ $(str(node.config)) , $(node.global_clock), childern = $(length(node.children))⟩"
end

function count_nodes(root::Node)
    println(str(root))
    if length(root.children) > 0
        return 1 + sum(count_nodes(child) for child in root.children)
    else
        return 1 # Leaf Node
    end
end


function build_game_tree(game::Game, 
                        max_time::Real, 
                        current_config::Union{Configuration,Nothing} = nothing, 
                        global_clock::Real = 0,
                        time_transition::Bool = true
                        ):: Node
    if current_config === nothing
        current_config = initial_configuration(game)
    end
    current_node = Node(current_config, global_clock, [])
    if global_clock >= max_time
        return current_node
    end
    if time_transition
        transition_time = 1.0
        push!(current_node.children,
            build_game_tree(game, 
                            max_time, 
                            continuous_transition(current_config, transition_time), 
                            global_clock + transition_time, 
                            false)
        )
        return current_node
    else
        agents_enabled_actions::Vector{Vector{String}} = []
        for agent in game.agents
            actions = enabled_actions(game, current_node.config.location, current_node.config.valuation, agent)
            push!(agents_enabled_actions, actions)
        end
        for decision_tuple in product(agents_enabled_actions...)
            decision = Dict()
            for i in 1:length(game.agents)
                decision[game.agents[i]] = decision_tuple[i]
            end
            edge = select_edge(game, current_config.location, current_config.valuation, decision)
            push!(current_node.children, 
                build_game_tree(game, 
                            max_time, 
                            discrete_transition(current_config, edge), 
                            global_clock, 
                            true)
            )
        end
        return current_node
    end
end