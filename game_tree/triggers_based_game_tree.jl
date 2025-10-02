include("time_to_trigger.jl")
include("../game_semantics/transitions.jl")
include("tree.jl")
include("../STL/logic.jl")

using IterTools
using Match


struct TriggerPath
    trigger::Constraint
    end_valuation::Valuation
    ttt::Float64
    path_to_trigger::Vector{Configuration} # time => (valuation, satisfied_properties)
end

function build_triggers_game_tree(game::Game,
                        properties::Set{Constraint},
                        termination_conditions;
                        current_config::Union{Configuration,Nothing} = nothing, 
                        parent::Union{Node, Nothing} = nothing,
                        reaching_decision::Union{Pair{Agent, Action}, Nothing} = nothing,
                        global_clock::Float64 = 0.0,
                        total_steps::Int64 = 0):: Node
    if current_config === nothing
        current_config = initial_configuration(game)
    end

    if global_clock >= termination_conditions["time-bound"] || 
        total_steps >= termination_conditions["max-steps"] #||
        # evaluate(termination_conditions["state_formula"], current_config)
        return Node(parent, reaching_decision, false, current_config, true, [])
    end

    remaining_time = termination_conditions["time-bound"] - global_clock
    current_node = Node(parent, reaching_decision, false, current_config, false, [])

    _, location_invariant, _ = time_to_trigger(current_config, Not(current_config.location.invariant), Set{Constraint}(), remaining_time)

    triggers_valuations::Dict{Agent, Vector{TriggerPath}} = Dict{Agent, Vector{TriggerPath}}()
    for agent in game.agents
        triggers_valuations[agent] = TriggerPath[]
        for trigger in game.triggers[agent]
            new_valuation, ttt, path_to_trigger = time_to_trigger(current_config, trigger, properties, location_invariant)
            if ttt <= remaining_time && ttt < location_invariant
                trigger_path = TriggerPath(trigger, new_valuation, ttt, path_to_trigger)
                push!(triggers_valuations[agent], trigger_path)
            end
        end
    end
    for agent in game.agents
        for trigger_path in triggers_valuations[agent]
            config_after_trigger = Configuration(current_config.location, trigger_path.end_valuation, global_clock + trigger_path.ttt)
            for action in enabled_actions(config_after_trigger, agent)
                for edge in select_edges(game, config_after_trigger, agent => action)
                    config_after_edge = discrete_transition(config_after_trigger, edge)
                    path_node = current_node
                    for path_config in trigger_path.path_to_trigger
                        if global_clock >= termination_conditions["time-bound"] # &&
                            # evaluate(termination_conditions["state_formula"], current_config)
                            child_node = Node(path_node, Pair(agent, action), true, path_config, true, [])
                        else
                            child_node = Node(path_node, Pair(agent, action), true, path_config, false, [])
                        end
                        push!(path_node.children, child_node)
                        path_node = child_node
                    end
                    push!(path_node.children, 
                        build_triggers_game_tree(game, 
                                properties,
                                termination_conditions,
                                parent=current_node,
                                reaching_decision=Pair(agent, action),
                                current_config=config_after_edge,
                                global_clock=global_clock + trigger_path.ttt,
                                total_steps=total_steps + 1
                        )
                    )
                end
            end
        end
    end 
    sort_children_by_clock!(current_node)
    return current_node
end


