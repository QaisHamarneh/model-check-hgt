include("../essential_definitions/constraint.jl")
include("../game_semantics/configuration.jl")
include("../game_tree/tree.jl")
using Match
using DataStructures

abstract type Logic_Formula end


struct Truth_Formula <: Logic_Formula
    value::Bool
end

struct Location_Formula <: Logic_Formula
    proposition::Symbol
end

struct Constraint_Formula <: Logic_Formula
    constraint::Constraint
end

struct Not_Formula <: Logic_Formula
    formula::Logic_Formula
end

struct And_Formula <: Logic_Formula
    left::Logic_Formula
    right::Logic_Formula
end

struct Or_Formula <: Logic_Formula
    left::Logic_Formula
    right::Logic_Formula
end

struct Imply_Formula <: Logic_Formula
    left::Logic_Formula
    right::Logic_Formula
end

struct Until <: Logic_Formula
    right::Logic_Formula
    left::Logic_Formula
end

struct Eventually <: Logic_Formula
    formula::Logic_Formula
end

struct Globally <: Logic_Formula
    formula::Logic_Formula
end

struct Exist_Strategy <: Logic_Formula
    agents::Set{Agent}
    formula::Logic_Formula
end

struct Forall_Strategy <: Logic_Formula
    agents::Set{Agent}
    formula::Logic_Formula
end

function get_all_properties(formula::Logic_Formula)::Set{Constraint}
    @match formula begin
        Truth_Formula(_) => Set{Constraint}()
        Location_Formula(_) => Set{Constraint}()
        Constraint_Formula(constraint) => Set([constraint, Not(constraint)])
        Not_Formula(f) => get_all_properties(f)
        And_Formula(left, right) => get_all_properties(left) ∪ get_all_properties(right)
        Or_Formula(left, right) => get_all_properties(left) ∪ get_all_properties(right)
        Imply_Formula(left, right) => get_all_properties(left) ∪ get_all_properties(right)
        Until(left, right) => get_all_properties(left) ∪ get_all_properties(right)
        Eventually(f) => get_all_properties(f)
        Globally(f) => get_all_properties(f)
        Exist_Strategy(_, f) => get_all_properties(f)
        Forall_Strategy(_, f) => get_all_properties(f)
    end
end


function get_all_properties(formulae::Vector{Logic_Formula})::Set{Constraint}
    props = Set{Constraint}()
    for formula in formulae
        props = props ∪ get_all_properties(formula)
    end
    return props
end


# function evaluate(formula::State_Formula, config::Configuration)::Bool
#     @match formula begin
#         State_Truth(value) => value
#         State_Location(loc) => loc == config.location
#         State_Constraint(constraint) => evaluate(constraint, config.valuation)
#         State_And(left, right) => evaluate(left, config) && evaluate(right, config)
#         State_Or(left, right) => evaluate(left, config) || evaluate(right, config)
#         State_Not(f) => ! evaluate(f, config)
#         State_Imply(left, right) => ! evaluate(left, config) || evaluate(right, config)
#     end
# end

# function evaluate(formula::Strategy_Formula, node::Node, all_agents::Set{Agent})::Bool
#     @match formula begin
#         Strategy_to_State(f) => evaluate(f, node.config)
#         Exist_Always(agents, f) => begin
#             if ! evaluate(f, node, all_agents)
#                 return false
#             end
#             if length(node.children) == 0 || node.terminal_node
#                 return true
#             end
#             if node.passive_node
#                 return evaluate(formula, node.children[1], all_agents)
#             end
#             children = sort_children_by_clock_agent(node, agents)
#             agents_children = Vector{Node}()
#             other_agents_children = Vector{Node}()
#             for child in children
#                 if child.reaching_decision.first in agents
#                     if evaluate(formula, child, all_agents)
#                         return true
#                     end
#                     push!(agents_children, child)
#                 else 
#                     if ! evaluate(formula, child, all_agents)
#                         return false
#                     end
#                     push!(other_agents_children, child)
#                 end
#             end
#             if length(agents_children) > 0 && (length(other_agents_children) == 0 || last(agents_children).global_clock < last(other_agents_children).global_clock)
#                 return false
#             else
#                 return true
#             end
#         end
#         Exist_Eventually(agents, f) => begin
#             if evaluate(f, node, all_agents)
#                 return true
#             end
#             if length(node.children) == 0 || node.terminal_node
#                 return false
#             end
#             if node.passive_node
#                 return evaluate(formula, node.children[1], all_agents)
#             end
#             children = sort_children_by_clock_agent(node, agents)
#             agents_children = Vector{Node}()
#             other_agents_children = Vector{Node}()
#             for child in children
#                 if child.reaching_decision.first in agents
#                     if evaluate(formula, child, all_agents)
#                         return true
#                     end
#                     push!(agents_children, child)
#                 else 
#                     if ! evaluate(formula, child, all_agents)
#                         return false
#                     end
#                     push!(other_agents_children, child)
#                 end
#             end
#             if length(agents_children) > 0 && (length(other_agents_children) == 0 || last(agents_children).global_clock < last(other_agents_children).global_clock)
#                 return false
#             else
#                 return true
#             end
#         end
#         All_Always(agents, f) => ! evaluate(Exist_Eventually(setdiff(all_agents, agents), State_Not(f)), node, all_agents)
#         All_Eventually(agents, f) => ! evaluate(Exist_Always(setdiff(all_agents, agents), State_Not(f)), node, all_agents)
#         Strategy_And(left, right) => evaluate(left, node) && evaluate(right, node)
#         Strategy_Or(left, right) => evaluate(left, node) || evaluate(right, node)
#         Strategy_Not(f) => ! evaluate(f, node)
#         Strategy_Imply(left, right) => ! evaluate(left, node) || evaluate(right, node)
#     end
# end


# function evaluate(formulae::Vector{Strategy_Formula}, node::Node, all_agents::Set{Agent})::Vector{Bool}
#     results = Vector{Bool}()
#     for formula in formulae
#         push!(results, evaluate(formula, node, all_agents))
#     end
#     return results
# end