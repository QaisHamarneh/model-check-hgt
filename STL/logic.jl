include("../essential_definitions/constraint.jl")
include("../game_semantics/configuration.jl")
include("../game_semantics/tree.jl")
using Match
using DataStructures

abstract type Logic_Formula end

abstract type Strategy_Formula <: Logic_Formula end
abstract type State_Formula <: Logic_Formula end


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

struct State_Truth <: State_Formula
    value::Bool
end

struct Location_Prop <: State_Formula
    proposition::Symbol
end

struct Constraint_Prop <: State_Formula
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



function get_state_formulae(formula::Strategy_Formula)::Set{State_Formula}
    @match formula begin
        Strategy_to_State(f) => Set([f])
        Exist_Always(_, f) => Set([f])
        Exist_Eventually(_, f) => Set([f])
        All_Always(_, f) => Set([f])
        All_Eventually(_, f) => Set([f])
        Strategy_And(left, right) => get_state_formulae(left) ∪ get_state_formulae(right)
        Strategy_Or(left, right) => get_state_formulae(left) ∪ get_state_formulae(right)
        Strategy_Not(f) => get_state_formulae(f)
    end
end



function get_all_formulae(formula::Strategy_Formula)::Set{Logic_Formula}
    @match formula begin
        Strategy_to_State(f) => Set([formula]) ∪ get_all_formulae(f)
        Exist_Always(_, f) => Set([formula]) ∪ get_all_formulae(f)
        Exist_Eventually(_, f) => Set([formula]) ∪ get_all_formulae(f)
        All_Always(_, f) => Set([formula]) ∪ get_all_formulae(f)
        All_Eventually(_, f) => Set([formula]) ∪ get_all_formulae(f)
        Strategy_And(left, right) => Set([formula]) ∪ get_all_formulae(left) ∪ get_all_formulae(right)
        Strategy_Or(left, right) => Set([formula]) ∪ get_all_formulae(left) ∪ get_all_formulae(right)
        Strategy_Not(f) => Set([formula]) ∪ get_all_formulae(f)
    end
end

function evaluate(formula::State_Formula, config::Configuration)::Bool
    @match formula begin
        State_Truth(value) => value
        Location_Prop(loc) => loc == config.location
        Constraint_Prop(constraint) => evaluate(constraint, config.valuation)
        State_And(left, right) => evaluate(left, config) && evaluate(right, config)
        State_Or(left, right) => evaluate(left, config) || evaluate(right, config)
        State_Not(f) => ! evaluate(f, config)
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
            agents_children = Vector{Node}()
            other_agents_children = Vector{Node}()
            for child in node.children
                if child.reaching_decision.first in agents
                    if evaluate(formula, child, all_agents)
                        return true
                    end
                    push!(agents_children, child)
                else 
                    if ! evaluate(formula, child, all_agents)
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
            agents_children = Vector{Node}()
            other_agents_children = Vector{Node}()
            for child in node.children
                if child.reaching_decision.first in agents
                    if evaluate(formula, child, all_agents)
                        return true
                    end
                    push!(agents_children, child)
                else 
                    if ! evaluate(formula, child, all_agents)
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
    end
end