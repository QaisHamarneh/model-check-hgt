
include("time_to_trigger.jl")
include("discrete_transitions.jl")
include("continuous_transitions.jl")

using IterTools
using Match

struct Trigger
    trigger::ExprLike
    agent::Symbol
    action::Symbol
    ttt::Float64
    valuation::OrderedDict{Symbol, Float64}
end

struct Node
    config::Configuration
    global_clock::Float64
    children::Vector{Node}
end

function str(node::Node)::String
    return "⟨ $(str(node.config)) , $(node.global_clock), childern = $(length(node.children))⟩"
end

function count_nodes(root::Node, level::Int = 0)::Int
    # println("Level: ", level)
    # println("Location ", root.config.location.name, " children: ", length(root.children))
    # println("Time: ", root.global_clock, " Valuation: ", root.config.valuation)
    # println("----------------------")
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

function build_triggers_game_tree(game::Game; 
                        current_config::Union{Configuration,Nothing} = nothing, 
                        max_time::Float64, 
                        global_clock::Float64 = 0.0,
                        max_steps::Int64,
                        total_steps::Int64 = 0):: Node
    if current_config === nothing
        current_config = initial_configuration(game)
    end
    remaining_time = max_time - global_clock
    current_node = Node(current_config, global_clock, [])
    if global_clock >= max_time || total_steps >= max_steps
        return current_node
    end

    _, location_invariant::Float64 = time_to_trigger(current_config, Not(current_config.location.invariant), remaining_time)

    triggers_valuations::Dict = Dict()
    for trigger in game.triggers
        new_valuation, ttt = time_to_trigger(current_config, trigger, remaining_time)
        if ttt <= remaining_time && ttt < location_invariant
            triggers_valuations[trigger] = (Configuration(current_config.location, new_valuation), ttt)
        end
    end
    for agent in game.agents
        for (_, (new_config, ttt)) in triggers_valuations
            actions = enabled_actions(new_config, agent)
            for action in actions
                edge = select_edge(game, new_config, Dict(agent => action))
                config_after_action = discrete_transition(new_config, edge)
                push!(current_node.children, 
                    build_triggers_game_tree(game, 
                            current_config=config_after_action,
                            max_time=max_time,
                            global_clock=global_clock + ttt,
                            max_steps=max_steps,
                            total_steps=total_steps + 1
                            )
                )
            end
        end
    end 

    return current_node
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