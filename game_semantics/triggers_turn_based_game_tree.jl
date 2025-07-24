
include("time_to_trigger.jl")
include("discrete_transitions.jl")
include("continuous_transitions.jl")

using IterTools
using Match

struct PathNode
    config::Configuration
    global_clock::Float64
    agent::Symbol
    action::Symbol
    trigger::ExprLike
end

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
    println("Node: ", root.global_clock)
    @match root begin
        Node(config, _, []) => 1
        Node(_, _, children) => 1 + sum(count_nodes(child) for child in children)
    end
end


function build__triggers_game_tree(game::Game; 
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


    agents_enabled_triggers::Vector = []
    for agent in game.agents
        triggers = Vector()
        for trigger in game.triggers[agent]
            if round(evaluate(trigger, current_config.valuation)) == 0
                continue
            end
            # println("Evaluating trigger: ", trigger, " for agent: ", agent)
            new_valuation, ttt = time_to_trigger(current_config, ExprLike[trigger], max_time - global_clock)
            if evaluate(current_config.location.invariant, new_valuation)
                # println("New Valuation: ", new_valuation, " ttt: ", ttt)
                actions = enabled_actions(current_config.location, new_valuation, agent)
                # println("Enabled Actions: ", actions)
                for action in actions
                    push!(triggers, (trigger, ttt, action, new_valuation))
                end
            end
        end
        # if ! isempty(triggers)
        push!(agents_enabled_triggers, triggers)
        # end
    end
    # for (i, agent) in enumerate(game.agents)
    #     println("Agent: ", agent, " enabled triggers:")
    #     for trigger_time_action in agents_enabled_triggers[i]
    #         println("  Trigger: ", trigger_time_action[1], 
    #                 ", Time to trigger: ", trigger_time_action[2],
    #                 ", Actions: ", trigger_time_action[3])
    #     end
    # end
    for decision_tuple in product(agents_enabled_triggers...)
        decision::Dict{Symbol, Symbol} = Dict()
        fastest_time = Inf64
        fastest_agent = nothing
        fastest_trigger = nothing
        fastest_action = nothing
        new_valuation = nothing

        for (agent, trigger_time_action) in zip(game.agents, decision_tuple)
            ttt = trigger_time_action[2]
            if ttt < fastest_time
                fastest_time = ttt
                fastest_agent = agent 
                fastest_trigger = trigger_time_action[1] 
                fastest_action = trigger_time_action[3] 
                new_valuation = trigger_time_action[4] 
            end
        end
        decision[fastest_agent] = fastest_action
        new_config = Configuration(current_config.location, 
                                            new_valuation)
        edge = select_edge(game, current_config.location, current_config.valuation, decision)
        push!(current_node.children, 
            build__triggers_game_tree(game, 
                            current_config=discrete_transition(new_config, edge),
                            max_time=max_time,
                            global_clock=global_clock + fastest_time,
                            max_steps=max_steps,
                            total_steps=total_steps + 1
                            # path=[path; [PathNode(current_config, global_clock, fastest_agent, fastest_action, fastest_trigger)]]
                            )
             )
    end
        

                      

    return current_node
end