
include("time_to_trigger.jl")
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
    triggers_valuations::Dict = Dict()
    for trigger in game.triggers
        new_valuation, ttt = time_to_trigger(current_config, ExprLike[trigger], max_time - global_clock)
        if ttt <= max_time - global_clock
            triggers_valuations[trigger] = (new_valuation, ttt)
        end
    end
    for agent in game.agents
        triggers = Vector()
        for (trigger, (new_valuation, ttt)) in triggers_valuations
            if evaluate(current_config.location.invariant, new_valuation)
                actions = enabled_actions(current_config.location, new_valuation, agent)
                for action in actions
                    push!(triggers, (agent, trigger, ttt, action, new_valuation))
                end
            end
        end
        if ! isempty(triggers)
            push!(agents_enabled_triggers, triggers)
        end
    end
    decisions = product(agents_enabled_triggers...) 
    for decision_tuple in decisions
        if !isempty(decision_tuple)
            decision::Dict{Symbol, Symbol} = Dict()
            fastest_time = Inf64
            new_valuation = nothing
            fastest_trigger = nothing

            for trigger_time_action in decision_tuple
                if trigger_time_action[3] <= fastest_time
                    fastest_trigger = trigger_time_action[2]
                    fastest_time = trigger_time_action[3]
                    new_valuation = trigger_time_action[5] 
                end
            end
            for trigger_time_action in decision_tuple
                if round5(trigger_time_action[3]) == round5(fastest_time)
                    decision[trigger_time_action[1]] = trigger_time_action[4]
                end
            end
            config_after_trigger = Configuration(current_config.location, 
                                                new_valuation)
            edge = select_edge(game, current_config.location, new_valuation, decision)
            config_after_action = discrete_transition(config_after_trigger, edge)
            push!(current_node.children, 
                build__triggers_game_tree(game, 
                                current_config=config_after_action,
                                max_time=max_time,
                                global_clock=global_clock + fastest_time,
                                max_steps=max_steps,
                                total_steps=total_steps + 1
                                )
                )
        end
    end
        

                      

    return current_node
end
