include("time_to_trigger.jl")
include("discrete_transitions.jl")
include("continuous_transitions.jl")
include("tree.jl")

using IterTools
using Match


function build_triggers_game_tree(game::Game,
                        properties::Set{Constraint};
                        current_config::Union{Configuration,Nothing} = nothing, 
                        parent::Union{Node, Nothing} = nothing,
                        reaching_trigger::Union{Constraint, Nothing} = nothing,
                        reaching_decision::Union{Pair{Agent, Action}, Nothing} = nothing,
                        max_time::Float64, 
                        global_clock::Float64 = 0.0,
                        max_steps::Int64,
                        total_steps::Int64 = 0):: Node
    if current_config === nothing
        current_config = initial_configuration(game)
        parent = nothing
        reaching_trigger = nothing
        reaching_decision = nothing
    end
    remaining_time = max_time - global_clock
    sat_props = satisfied_constraints(properties, current_config.valuation)
    current_node = Node(parent, reaching_trigger, reaching_decision, current_config, global_clock, sat_props, [])

    if global_clock >= max_time || total_steps >= max_steps
        return current_node
    end

    _, location_invariant, _ = time_to_trigger(current_config, Not(current_config.location.invariant), Set{Constraint}(), remaining_time)

    triggers_valuations::Dict = Dict()
    for trigger in game.triggers
        new_valuation, ttt, path_properties = time_to_trigger(current_config, trigger, Set{Constraint}([parse_constraint("y > 5")]), location_invariant)
        if ttt <= remaining_time && ttt < location_invariant
            triggers_valuations[trigger] = (Configuration(current_config.location, new_valuation), ttt)

            if length(path_properties) > 0
                println("current_valuation: ", current_config.valuation)
                println("Path properties: ", path_properties)
                println("new_valuation: ", new_valuation)
            end
        end
    end
    for agent in game.agents
        for (trigger, (config_after_trigger, ttt)) in triggers_valuations
            actions = enabled_actions(config_after_trigger, agent)
            for action in actions
                edge = select_edge(game, config_after_trigger, Dict(agent => action))
                config_after_edge = discrete_transition(config_after_trigger, edge)
                push!(current_node.children, 
                    build_triggers_game_tree(game, 
                            properties,
                            parent=current_node,
                            reaching_trigger=trigger,
                            reaching_decision=Pair(agent, action),
                            current_config=config_after_edge,
                            max_time=max_time,
                            global_clock=global_clock + ttt,
                            max_steps=max_steps,
                            total_steps=total_steps + 1
                    )
                )
            end
        end
    end 
    sort!(current_node.children, by = child -> child.global_clock)
    return current_node
end


