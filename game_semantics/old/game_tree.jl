include("discrete_transitions.jl")
include("continuous_transitions.jl")

using IterTools
using Match

struct Node
    config::Configuration
    global_clock::Float64
    children::Vector{Node}
end

function str(node::Node)::String
    return "⟨ $(str(node.config)) , $(node.global_clock), childern = $(length(node.children))⟩"
end

function count_nodes(root::Node)
    # println(str(root))
    @match root begin
        Node(_, _, []) => 1
        Node(_, _, children) => 1 + sum(count_nodes(child) for child in children)
    end
end


function build_game_tree(game::Game; 
                        current_config::Union{Configuration,Nothing} = nothing, 
                        max_time::Float64, 
                        global_clock::Float64 = 0.0,
                        max_steps::Int64,
                        total_steps::Int64 = 0,
                        time_transition::Bool = true):: Node
    if current_config === nothing
        current_config = initial_configuration(game)
    end
    current_node = Node(current_config, global_clock, [])
    if global_clock >= max_time || total_steps >= max_steps
        return current_node
    end
    if time_transition 
        transition_time = 1.0
        if evaluate(current_config.location.invariant, 
                    continuous_evolution(current_config.valuation, current_config.location.flow, transition_time))
            push!(current_node.children,
                build_game_tree(game, 
                                current_config=continuous_transition(current_config, transition_time), 
                                max_time=max_time,
                                global_clock=global_clock + transition_time,
                                max_steps=max_steps,
                                total_steps=total_steps + 1,
                                time_transition=false)
                )
        else
            return current_node
        end
        return current_node
    else
        agents_enabled_actions::Vector{Vector{Symbol}} = []
        for agent in game.agents
            actions = enabled_actions(current_config.location, current_node.config.valuation, agent)
            push!(agents_enabled_actions, actions)
        end
        for decision_tuple in product(agents_enabled_actions...)
            decision::Dict{Symbol, Symbol} = Dict()
            for (agent, action) in zip(game.agents, decision_tuple)
                decision[agent] = action
            end
            edge = select_edge(game, current_config.location, current_config.valuation, decision)
            push!(current_node.children, 
                build_game_tree(game, 
                                current_config=discrete_transition(current_config, edge),
                                max_time=max_time,
                                global_clock=global_clock,
                                max_steps=max_steps,
                                total_steps=total_steps + 1,
                                time_transition=true)
            )
        end
        return current_node
    end
end