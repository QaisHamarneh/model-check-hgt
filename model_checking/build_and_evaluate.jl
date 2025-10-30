include("node.jl")
include("../game_tree/time_to_trigger.jl")


struct TriggerPathOnDemand
    trigger::Constraint
    end_valuation::Valuation
    ttt::Float64
    path_to_trigger::Vector{Configuration}
end

function check_termination_on_demand(node::NodeOnDemand, total_steps::Int, termination_conditions):: Bool
    
    if node.config.global_clock >= termination_conditions["time-bound"] || 
        total_steps >= termination_conditions["max-steps"] ||
        evaluate_state(termination_conditions["state-formula"], node)
        return true
    else
        return false
    end
    
end

# function build_game_tree(game::Game, termination_conditions, queries::Vector{Strategy_Formula}):: Node
#     constraints = get_all_constraints(queries ∪ State_Formula[termination_conditions["state-formula"]])
#     return build_game_tree_on_demand(game, constraints, termination_conditions)
# end

function build_children!(game::Game, constraints::Set{Constraint}, node::NodeOnDemand, termination_conditions, total_steps::Int)
    remaining_time = termination_conditions["time-bound"] - node.config.global_clock
    _, location_invariant, _ = time_to_trigger(node.config, Not(node.config.location.invariant), Set{Constraint}(), remaining_time)

    triggers_valuations::Dict{Agent, Vector{TriggerPathOnDemand}} = Dict{Agent, Vector{TriggerPath}}()
    for agent in game.agents
        triggers_valuations[agent] = TriggerPathOnDemand[]
        for trigger in game.triggers[agent]
            new_valuation, ttt, path_to_trigger = time_to_trigger(node.config, trigger, constraints, location_invariant)
            if ttt <= remaining_time && ttt < location_invariant
                trigger_path = TriggerPathOnDemand(trigger, new_valuation, ttt, path_to_trigger)
                push!(triggers_valuations[agent], trigger_path)
            end
        end
    end

    for agent in game.agents
        for trigger_path in triggers_valuations[agent]
            config_after_trigger = Configuration(node.config.location, trigger_path.end_valuation, node.config.global_clock + trigger_path.ttt)
            for action in enabled_actions(config_after_trigger, agent)
                for edge in select_edges(game, config_after_trigger, agent => action)
                    config_after_edge = discrete_transition(config_after_trigger, edge)
                    path_node = node
                    for path_config in trigger_path.path_to_trigger
                        child_node = NodeOnDemand(path_node, agent => action, true, path_config, 
                                false, [], true)
                        child_node.terminal_node = check_termination_on_demand(child_node, total_steps, termination_conditions)
                        push!(path_node.children, child_node)
                        path_node = child_node
                    end
                    child_node = NodeOnDemand(path_node, agent => action, false, config_after_edge, 
                                false, [], false)
                    child_node.terminal_node = check_termination_on_demand(child_node, total_steps + 1, termination_conditions)
                    push!(path_node.children, child_node)
                end
            end
        end
    end 
    node.children_built = true
end


function evaluate_state(formula::State_Formula, node::NodeOnDemand)::Bool
    @match formula begin
        State_Location(loc) => loc == node.config.location
        State_Constraint(constraint) => evaluate(constraint, node.config.valuation)
        State_And(left, right) => evaluate_state(left, node.config) && evaluate_state(right, node.config)
        State_Or(left, right) => evaluate_state(left, node.config) || evaluate_state(right, node.config)
        State_Not(f) => ! evaluate_state(f, node.config)
        State_Imply(left, right) => ! evaluate_state(left, node.config) || evaluate_state(right, node.config)
        State_Deadlock() => ! node.terminal_node && length(node.children) == 0
    end
end

function evaluate_and_build!(game::Game, constraints::Set{Constraint}, formula::Strategy_Formula, node::NodeOnDemand, total_steps::Int)::Bool
    @match formula begin
        Strategy_to_State(f) => begin
            if node.children_built == false
                build_children!(game, constraints, node, termination_conditions, total_steps)
            end
            return evaluate_state(f, node)
        end
        All_Always(agents, f) => ! evaluate_and_build!(game, constraints, Exist_Eventually(setdiff(game.agents, agents), Strategy_Not(f)), node, total_steps)
        All_Eventually(agents, f) => ! evaluate_and_build!(game, constraints, Exist_Always(setdiff(game.agents, agents), Strategy_Not(f)), node, total_steps)
        Strategy_And(left, right) => evaluate_and_build!(game, constraints, left, node, total_steps) && evaluate_and_build!(game, constraints, right, node, total_steps)
        Strategy_Or(left, right) => evaluate_and_build!(game, constraints, left, node, total_steps) || evaluate_and_build!(game, constraints, right, node, total_steps)
        Strategy_Not(f) => ! evaluate_and_build!(game, constraints, f, node, total_steps)
        Strategy_Imply(left, right) => ! evaluate_and_build!(game, constraints, left, node, total_steps) || evaluate_and_build!(game, constraints, right, node, total_steps)
        Exist_Always(agents, f) => begin
            if ! evaluate_and_build!(game, constraints, f, node, total_steps)
                return false
            end
            if node.children_built == false
                build_children!(game, constraints, node, termination_conditions, total_steps)
            end
            if length(node.children) == 0 || node.terminal_node
                return true
            end
            if node.passive_node
                return evaluate_and_build!(game, constraints, formula, node.children[1], total_steps)
            end
            children = sort_children_by_clock_agent_on_demand(node, agents)
            # agents_children = Vector{NodeOnDemand}()
            # other_agents_children = Vector{NodeOnDemand}()
            for child in children
                if child.reaching_decision.first in agents
                    if evaluate_and_build!(game, constraints, formula, child, total_steps + 1)
                        return true
                    end
                    # push!(agents_children, child)
                else 
                    if ! evaluate_and_build!(game, constraints, formula, child, total_steps + 1)
                        return false
                    end
                    # push!(other_agents_children, child)
                end
            end
            # if length(agents_children) > 0 && (length(other_agents_children) == 0 || last(agents_children).global_clock < last(other_agents_children).global_clock)
            #     return false
            # else
            return true
            # end
        end
        Exist_Eventually(agents, f) => begin
            if evaluate_and_build!(game, constraints, f, node, total_steps)
                return true
            end
            if node.children_built == false
                build_children!(game, constraints, node, termination_conditions, total_steps)
            end
            if length(node.children) == 0 || node.terminal_node
                return false
            end
            if node.passive_node
                return evaluate_and_build!(game, constraints, formula, node.children[1], total_steps)
            end
            children = sort_children_by_clock_agent_on_demand(node, agents)
            # agents_children = Vector{NodeOnDemand}()
            # other_agents_children = Vector{NodeOnDemand}()
            for child in children
                if child.reaching_decision.first in agents
                    if evaluate_and_build!(game, constraints, formula, child, total_steps + 1)
                        return true
                    end
                    # push!(agents_children, child)
                else 
                    if ! evaluate_and_build!(game, constraints, formula, child, total_steps + 1)
                        return false
                    end
                    # push!(other_agents_children, child)
                end
            end
            # if length(agents_children) > 0 && (length(other_agents_children) == 0 || last(agents_children).global_clock < last(other_agents_children).global_clock)
            #     return false
            # else
            return true
            # end
        end
    end
end


function evaluate_queries(game::Game, termination_conditions, queries::Vector{Strategy_Formula}) #::(Vector{Bool}, NodeOnDemand)
    initial_config = initial_configuration(game)
    root = NodeOnDemand(nothing, nothing, false, initial_config, false, [], false)
    constraints = get_all_constraints(queries ∪ State_Formula[termination_conditions["state-formula"]])

    results = Vector{Bool}()
    for formula in queries
        push!(results, evaluate_and_build!(game, constraints, formula, root, 0))
    end
    return results, root
end