
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
    println("Level: ", level)
    println("Location ", root.config.location.name, " Valuation: ", root.config.valuation)
    println("Time: ", root.global_clock)
    println("----------------------")
    @match root begin
        Node(config, _, []) => 1
        Node(_, _, children) => 1 + sum(count_nodes(child, level + 1) for child in children)
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
    current_node = Node(current_config, global_clock, [])
    if global_clock >= max_time || total_steps >= max_steps
        return current_node
    end

    # _, location_invariant_max = time_to_trigger(current_config, ExprLike[trigger], max_time - global_clock)

    println("----------------------")
    println("Step: ", total_steps)
    triggers_valuations::Dict = Dict()
    for trigger in game.triggers
        new_valuation, ttt = time_to_trigger(current_config, ExprLike[trigger], max_time - global_clock)
        if ttt <= max_time - global_clock
            triggers_valuations[trigger] = (Configuration(current_config.location, new_valuation), ttt)
        end
        println("ttt: ", ttt, " for trigger: ", str(trigger))
    end
    for agent in game.agents
        for (_, (new_config, ttt)) in triggers_valuations
            if evaluate(current_config.location.invariant, new_config.valuation)
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
    end          

    return current_node
end


# function build_triggers_game_tree_iterative(game::Game; 
#                                             current_config::Union{Configuration,Nothing} = nothing, 
#                                             max_time::Float64, 
#                                             global_clock::Float64 = 0.0,
#                                             max_steps::Int64,
#                                             total_steps::Int64 = 0)::Node

#     if current_config === nothing
#         current_config = initial_configuration(game)
#     end

#     root = Node(current_config, global_clock, [])
#     stack = [(root, current_config, global_clock, total_steps)]

#     while !isempty(stack)
#         node, cfg, clock, steps = pop!(stack)

#         if clock >= max_time || steps >= max_steps
#             continue
#         end

#         agents_enabled_triggers = Vector{Vector}()
#         triggers_valuations = Dict()
#         for trigger in game.triggers
#             new_valuation, ttt = time_to_trigger(cfg, ExprLike[trigger], max_time - clock)
#             if ttt <= max_time - clock
#                 triggers_valuations[trigger] = (new_valuation, ttt)
#             end
#         end

#         for agent in game.agents
#             triggers = Vector()
#             for (trigger, (new_valuation, ttt)) in triggers_valuations
#                 if evaluate(cfg.location.invariant, new_valuation)
#                     actions = enabled_actions(cfg, agent)
#                     for action in actions
#                         push!(triggers, (agent, trigger, ttt, action, new_valuation))
#                     end
#                 end
#             end
#             if !isempty(triggers)
#                 push!(agents_enabled_triggers, triggers)
#             end
#         end

#         decisions = product(agents_enabled_triggers...)

#         for decision_tuple in decisions
#             if isempty(decision_tuple)
#                 continue
#             end

#             decision = Dict{Symbol, Symbol}()
#             fastest_time = Inf
#             new_valuation = nothing
#             fastest_trigger = nothing

#             for trigger_time_action in decision_tuple
#                 if trigger_time_action[3] <= fastest_time
#                     fastest_trigger = trigger_time_action[2]
#                     fastest_time = trigger_time_action[3]
#                     new_valuation = trigger_time_action[5]
#                 end
#             end

#             for trigger_time_action in decision_tuple
#                 if round3(trigger_time_action[3]) == round3(fastest_time)
#                     decision[trigger_time_action[1]] = trigger_time_action[4]
#                 end
#             end

#             config_after_trigger = Configuration(cfg.location, new_valuation)
#             edge = select_edge(game, config_after_trigger, decision)
#             config_after_action = discrete_transition(config_after_trigger, edge)

#             child_node = Node(config_after_action, clock + fastest_time, [])
#             push!(node.children, child_node)
#             push!(stack, (child_node, config_after_action, clock + fastest_time, steps + 1))
#         end
#     end

#     return root
# end