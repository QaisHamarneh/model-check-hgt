
include("time_to_trigger.jl")
include("discrete_transitions.jl")
include("continuous_transitions.jl")
include("tree.jl")

using IterTools
using Match

struct Trigger
    trigger::ExprLike
    agent::Symbol
    action::Symbol
    ttt::Float64
    valuation::OrderedDict{Symbol, Float64}
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

    _, location_invariant, _ = time_to_trigger(current_config, Not(current_config.location.invariant), Set{Constraint}(), remaining_time)

    triggers_valuations::Dict = Dict()
    for trigger in game.triggers
        new_valuation, ttt, path_properties = time_to_trigger(current_config, trigger, Set{Constraint}([parse_constraint("y > 5")]), location_invariant)
        if length(path_properties) > 0
            println("current_valuation: ", current_config.valuation)
            println("Path properties: ", path_properties)
            println("new_valuation: ", new_valuation)
        end
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


