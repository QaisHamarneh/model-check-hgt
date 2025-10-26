include("syntax_parsers/ast_nodes.jl")
include("../hybrid_atl/logic.jl")
using Match


function to_logic(node::ConstantOperation)::Union{State_Location, State_Deadlock, Truth, Const, Var}
    @match node begin
        LocationNode(value) => State_Location(Symbol(value))
        StateConstant(value) => State_Deadlock()
        ConstraintConstant(value) => Truth(value)
        ExpressionConstant(value) => Const(value)
        VariableNode(value) => Var(Symbol(value))
    end
end

function to_logic(node::ExpressionUnaryOperation)::ExprLike
    @match node.unary_operation begin
        "-" => Neg(to_logic(node.child))
        "sin" => Sin(to_logic(node.child))
        "cos" => CoSin(to_logic(node.child))
        "tan" => Tan(to_logic(node.child))
        "cot" => CoTan(to_logic(node.child))
    end
end

function to_logic(node::ExpressionBinaryOperation)::ExprLike
    @match node.binary_operation begin
        "+" => Add(to_logic(node.left_child), to_logic(node.right_child))
        "-" => Sub(to_logic(node.left_child), to_logic(node.right_child))
        "*" => Mul(to_logic(node.left_child), to_logic(node.right_child))
        "/" => Div(to_logic(node.left_child), to_logic(node.right_child))
        "^" => Expon(to_logic(node.left_child), to_logic(node.right_child))
    end
end

function to_logic(node::ConstraintUnaryOperation)::Constraint
    @match node.unary_operation begin
        "!" => Not(to_logic(node.child))
    end
end

function to_logic(node::ConstraintBinaryOperation)::Constraint
    @match node.binary_operation begin
        "<" => Less(to_logic(node.left_child), to_logic(node.right_child))
        "<=" => LeQ(to_logic(node.left_child), to_logic(node.right_child))
        ">" => Greater(to_logic(node.left_child), to_logic(node.right_child))
        ">=" => GeQ(to_logic(node.left_child), to_logic(node.right_child))
        "==" => Equal(to_logic(node.left_child), to_logic(node.right_child))
        "!=" => NotEqual(to_logic(node.left_child), to_logic(node.right_child))
        "&&" => And(to_logic(node.left_child), to_logic(node.right_child))
        "||" => Or(to_logic(node.left_child), to_logic(node.right_child))
        "->" => Imply(to_logic(node.left_child), to_logic(node.right_child))
    end
end

function to_logic(node::StateUnaryOperation)::State_Formula
    @match node.unary_operation begin
        "!" => State_Not(to_logic(node.child))
    end
end

function to_logic(node::StateUnaryOperation)::State_Formula
    child = to_logic(node.child)
    if child isa Constraint
        child = State_Constraint(child)
    end
    @match node.unary_operation begin
        "!" => State_Not(child)
    end
end

function to_logic(node::StateBinaryOperation)::State_Formula
    left_child = to_logic(node.left_child)
    if left_child isa Constraint
        left_child = State_Constraint(left_child)
    end
    right_child = to_logic(node.right_child)
    if right_child isa Constraint
        right_child = State_Constraint(right_child)
    end
    @match node.binary_operation begin
        "&&" => State_And(left_child, right_child)
        "||" => State_Or(left_child, right_child)
        "->" => State_Imply(left_child, right_child)
    end
end

function to_logic(node::StrategyUnaryOperation)::Strategy_Formula
    child = to_logic(node.child)
    if child isa Constraint
        child = State_Constraint(child)
    end
    if child isa State_Formula
        child = Strategy_to_State(child)
    end
    @match node.unary_operation begin
        "not" => Strategy_Not(child)
    end
end

function to_logic(node::StrategyBinaryOperation)::Strategy_Formula
    left_child = to_logic(node.left_child)
    if left_child isa Constraint
        left_child = State_Constraint(left_child)
    end
    if left_child isa State_Formula
        left_child = Strategy_to_State(left_child)
    end
    right_child = to_logic(node.right_child)
    if right_child isa Constraint
        right_child = State_Constraint(right_child)
    end
    if right_child isa State_Formula
        right_child = Strategy_to_State(right_child)
    end
    @match node.binary_operation begin
        "and" => Strategy_And(left_child, right_child)
        "or" => Strategy_Or(left_child, right_child)
        "imply" => Strategy_Imply(left_child, right_child)
    end
end

function to_logic(node::Quantifier)::Strategy_Formula
    child = to_logic(node.child)
    if child isa Constraint
        child = State_Constraint(child)
    end
    if child isa State_Formula
        child = Strategy_to_State(child)
    end
    if node.always
        if node.for_all
            return All_Always(to_logic(node.agents), child)
        else
            return Exist_Always(to_logic(node.agents), child)
        end
    else
        if node.for_all
            return All_Eventually(to_logic(node.agents), child)
        else
            return Exist_Eventually(to_logic(node.agents), child)
        end
    end
end

function to_logic(node::Agents)::Set{Agent}
    return to_logic(node.agents)
end

function to_logic(node::AgentList)::Set{Agent}
    agents::Set{Agent} = Set([])
    for agent in node.agents
        push!(agents, Agent(Symbol(agent)))
    end
    return agents
end
