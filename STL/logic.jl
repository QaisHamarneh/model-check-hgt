include("../essential_definitions/constraint.jl")
include("../game_semantics/configuration.jl")
include("../game_semantics/tree.jl")
using Match
using DataStructures

abstract type Strategy_Formula end
abstract type State_Formula  end


struct Strategy_to_State <: Strategy_Formula
    formula::State_Formula
end

struct Exist_Always <: Strategy_Formula
    agents::Set{Symbol}
    formula::State_Formula
end

struct Exist_Eventually <: Strategy_Formula
    agents::Set{Symbol}
    formula::State_Formula
end

struct All_Always <: Strategy_Formula
    agents::Set{Symbol}
    formula::State_Formula
end

struct All_Eventually <: Strategy_Formula
    agents::Set{Symbol}
    formula::State_Formula
end

struct Strategy_And <: Strategy_Formula
    left::Strategy_Formula
    right::Strategy_Formula
end

struct Strategy_Or <: Strategy_Formula
    left::Strategy_Formula
    right::Strategy_Formula
end

struct Strategy_Not <: Strategy_Formula
    formula::Strategy_Formula
end

struct Strategy_Imply <: Strategy_Formula
    left::Strategy_Formula
    right::Strategy_Formula
end

struct State_Truth <: State_Formula
    value::Bool
end

struct State_Location <: State_Formula
    proposition::Symbol
end

struct State_Constraint <: State_Formula
    constraint::Constraint
end

struct State_And <: State_Formula
    left::State_Formula
    right::State_Formula
end

struct State_Or <: State_Formula
    left::State_Formula
    right::State_Formula
end

struct State_Not <: State_Formula
    formula::State_Formula
end

struct State_Imply <: State_Formula
    left::State_Formula
    right::State_Formula
end


function get_all_properties(formula::State_Formula)::Set{Constraint}
    @match formula begin
        State_Truth(_) => Set{State_Formula}()
        State_Location(_) => Set{State_Formula}()
        State_Constraint(constraint) => Set([constraint, Not(constraint)])
        State_And(left, right) => get_all_properties(left) ∪ get_all_properties(right)
        State_Or(left, right) => get_all_properties(left) ∪ get_all_properties(right)
        State_Not(f) => get_all_properties(f)
        State_Imply(left, right) => get_all_properties(left) ∪ get_all_properties(right)
    end
end

function get_all_properties(formula::Strategy_Formula)::Set{Constraint}
    @match formula begin
        Strategy_to_State(f) => get_all_properties(f)
        Exist_Always(_, f) => get_all_properties(f)
        Exist_Eventually(_, f) => get_all_properties(f)
        All_Always(_, f) => get_all_properties(f)
        All_Eventually(_, f) => get_all_properties(f)
        Strategy_And(left, right) => get_all_properties(left) ∪ get_all_properties(right)
        Strategy_Or(left, right) => get_all_properties(left) ∪ get_all_properties(right)
        Strategy_Not(f) => get_all_properties(f)
        Strategy_Imply(left, right) => get_all_properties(left) ∪ get_all_properties(right)
    end
end

function get_all_properties(formulae::Vector{Strategy_Formula})::Set{Constraint}
    props = Set{Constraint}()
    for formula in formulae
        props = props ∪ get_all_properties(formula)
    end
    return props
end

function evaluate(formula::State_Formula, config::Configuration)::Bool
    @match formula begin
        State_Truth(value) => value
        State_Location(loc) => loc == config.location
        State_Constraint(constraint) => evaluate(constraint, config.valuation)
        State_And(left, right) => evaluate(left, config) && evaluate(right, config)
        State_Or(left, right) => evaluate(left, config) || evaluate(right, config)
        State_Not(f) => ! evaluate(f, config)
        State_Imply(left, right) => ! evaluate(left, config) || evaluate(right, config)
    end
end

function evaluate(formula::Strategy_Formula, node::Node, all_agents::Set{Agent})::Bool
    @match formula begin
        Strategy_to_State(f) => evaluate(f, node.config)
        Exist_Always(agents, f) => begin
            if ! evaluate(f, node.config)
                return false
            end
            if length(node.children) == 0
                return true
            end
            children = sort_children_by_clock_agent(node, agents)
            agents_children = Vector{Node}()
            other_agents_children = Vector{Node}()
            for child in children
                if child.reaching_decision.first in agents
                    if all(config -> evaluate(f, config), child.path_to_node) && evaluate(formula, child, all_agents)
                        return true
                    end
                    push!(agents_children, child)
                else 
                    if any(config -> ! evaluate(f, config), child.path_to_node) || ! evaluate(formula, child, all_agents)
                        return false
                    end
                    push!(other_agents_children, child)
                end
            end
            if length(agents_children) > 0 && (length(other_agents_children) == 0 || last(agents_children).global_clock < last(other_agents_children).global_clock)
                return false
            else
                return true
            end
        end
        Exist_Eventually(agents, f) => begin
            if evaluate(f, node.config)
                return true
            end
            if length(node.children) == 0
                return false
            end
            children = sort_children_by_clock_agent(node, agents)
            agents_children = Vector{Node}()
            other_agents_children = Vector{Node}()
            for child in children
                if child.reaching_decision.first in agents
                    if any(config -> evaluate(f, config), child.path_to_node) || evaluate(formula, child, all_agents)
                        return true
                    end
                    push!(agents_children, child)
                else 
                    if all(config -> ! evaluate(f, config), child.path_to_node) && ! evaluate(formula, child, all_agents)
                        return false
                    end
                    push!(other_agents_children, child)
                end
            end
            if length(agents_children) > 0 && (length(other_agents_children) == 0 || last(agents_children).global_clock < last(other_agents_children).global_clock)
                return false
            else
                return true
            end
        end
        All_Always(agents, f) => ! evaluate(Exist_Eventually(setdiff(all_agents, agents), State_Not(f)), node, all_agents)
        All_Eventually(agents, f) => ! evaluate(Exist_Always(setdiff(all_agents, agents), State_Not(f)), node, all_agents)
        Strategy_And(left, right) => evaluate(left, node) && evaluate(right, node)
        Strategy_Or(left, right) => evaluate(left, node) || evaluate(right, node)
        Strategy_Not(f) => ! evaluate(f, node)
        Strategy_Imply(left, right) => ! evaluate(left, node) || evaluate(right, node)
    end
end


function evaluate(formulae::Vector{Strategy_Formula}, node::Node, all_agents::Set{Agent})::Vector{Bool}
    results = Vector{Bool}()
    for formula in formulae
        push!(results, evaluate(formula, node, all_agents))
    end
    return results
end