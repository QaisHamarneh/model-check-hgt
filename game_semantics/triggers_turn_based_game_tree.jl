include("time_to_trigger.jl")
include("transitions.jl")
include("tree.jl")
include("../STL/logic.jl")

using IterTools
using Match


struct TriggerPath
    trigger::Constraint
    end_valuation::Valuation
    ttt::Float64
    path_to_node::Vector{Configuration} # time => (valuation, satisfied_properties)
end

function build_triggers_game_tree(game::Game,
                        properties::Set{Constraint},
                        termination_conditions;
                        current_config::Union{Configuration,Nothing} = nothing, 
                        parent::Union{Node, Nothing} = nothing,
                        reaching_decision::Union{Pair{Agent, Action}, Nothing} = nothing,
                        path_to_node::Union{Vector{Configuration}, Nothing}  = nothing,
                        global_clock::Float64 = 0.0,
                        total_steps::Int64 = 0):: Node
    if current_config === nothing
        current_config = initial_configuration(game)
    end
    remaining_time = termination_conditions["time-bound"] - global_clock
    current_node = Node(parent, reaching_decision, path_to_node, current_config, [])

    if global_clock >= termination_conditions["time-bound"] || 
        total_steps >= termination_conditions["max-steps"] #||
        # evaluate(termination_conditions["state_formula"], current_config)
        return current_node
    end

    _, location_invariant, _ = time_to_trigger(current_config, Not(current_config.location.invariant), Set{Constraint}(), remaining_time)

    triggers_valuations::Vector{TriggerPath} = []
    for trigger in game.triggers
        new_valuation, ttt, path_to_node = time_to_trigger(current_config, trigger, properties, location_invariant)
        if ttt <= remaining_time && ttt < location_invariant
            trigger_path = TriggerPath(trigger, new_valuation, ttt, path_to_node)
            push!(triggers_valuations, trigger_path)
        end
    end
    for agent in game.agents
        for trigger_path in triggers_valuations
            config_after_trigger = Configuration(current_config.location, trigger_path.end_valuation, global_clock + trigger_path.ttt)
            for action in enabled_actions(config_after_trigger, agent)
                edge = select_edge(game, config_after_trigger, Dict(agent => action))
                config_after_edge = discrete_transition(config_after_trigger, edge)
                push!(current_node.children, 
                    build_triggers_game_tree(game, 
                            properties,
                            termination_conditions,
                            parent=current_node,
                            reaching_decision=Pair(agent, action),
                            path_to_node=trigger_path.path_to_node,
                            current_config=config_after_edge,
                            global_clock=global_clock + trigger_path.ttt,
                            total_steps=total_steps + 1
                    )
                )
            end
        end
    end 
    sort!(current_node.children, by = child -> child.config.global_clock)
    return current_node
end


