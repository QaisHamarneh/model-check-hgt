"""
    AST Nodes

This file contains all definitions needed to parse tokens to an AST.

# Types:
- `ASTNode`: abstract type for all nodes
- `VariableList`: node for variable lists
- `AgentList`: node for agent lists
- `StrategyNode`: abstract type for strategy nodes
- `Quantifier`: node for quantified strategies
- `StrategyUnaryOperation`: node for unary operations on strategies
- `StrategyBinaryOperation`: node for binary operations on strategies
- `StateNode`: abstract type for state nodes
- `StateUnaryOperation`: node for unary operations on states
- `StateBinaryOperation`: node for binary operations on states
- `ConstraintNode`: abstract type for constraint nodes
- `ConstraintConstant`: node for boolean constants
- `ConstraintUnaryOperation`: node for unary operations on constraints
- `ConstraintBinaryOperation`: node for binary operations on constraints
- `ExpressionNode`: abstract type for expression nodes
- `VariableNode`: node for user-defined variables
- `ExpressionConstant`: node for numerical constants
- `ExpressionUnaryOperation`: node for unary operations on expressions
- `ExpressionBinaryOperation`: node for binary operations on expressions

The types are hierarchically ordered as follows:
    ASTNode
    |-- VariableList
    |-- AgentList
    |-- StrategyNode
    |   |-- Quantifier
    |   |-- StrategyUnaryOperation
    |   |-- StrategyBinaryOperation
    |   |-- StateNode
    |       |-- StateUnaryOperation
    |       |-- StateBinaryOperation
    |       |-- ConstraintNode
    |           |-- ConstraintConstant
    |           |-- ConstraintUnaryOperation
    |           |-- ConstraintBinaryOperation
    |-- ExpressionNode
        |-- VariableNode
        |-- ExpressionConstant
        |-- ExpressionUnaryOperation
        |-- ExpressionBinaryOperation
"""

# abstract type for all nodes
abstract type ASTNode
end

# abstract type for all expression nodes
abstract type ExpressionNode <: ASTNode
end

"""
    ExpressionConstant <: ExpressionNode

AST Node for numerical constants.

    ExpressionConstant(value::Real)

Create a ExpressionConstant with value `value`.
"""
struct ExpressionConstant <: ExpressionNode
    value::Real
end

"""
    VariableNode <: ExpressionNode

AST Node for user defined variables.

    VariableNode(name::String)

Create a VariableNode for a variable with name `name`.
"""
struct VariableNode <: ExpressionNode
    name::String
end

"""
    ExpressionUnaryOperation <: ExpressionNode

AST Node for unary operations on expressions.

    ExpressionUnaryOperation(unary_operation::String, child::Union{ExpressionNode, VariableNode})

Create a ExpressionUnaryOperation of type `unary_operation` on expression `child`.
"""
struct ExpressionUnaryOperation <: ExpressionNode
    unary_operation::String
    child::Union{ExpressionNode, VariableNode}
end

"""
    ExpressionBinaryOperation <: ExpressionNode

AST Node for binary operations on expressions.

    ExpressionBinaryOperation(binary_operation::String, Left_child::Union{ExpressionNode, VariableNode}, right_child::Union{ExpressionNode, VariableNode})

Create a ExpressionBinaryOperation of type `binary_operation` on expressions `left_child`, `right_child`.
"""
struct ExpressionBinaryOperation <: ExpressionNode
    binary_operation::String
    left_child::Union{ExpressionNode, VariableNode}
    right_child::Union{ExpressionNode, VariableNode}
end

# abstract type for all strategy nodes
abstract type StrategyNode <: ASTNode
end

"""
    StrategyUnaryOperation <: StrategyNode

AST Node for unary operations on strategies.

    StrategyUnaryOperation(unary_operation::String, child::StrategyNode)

Create a StrategyUnaryOperation of type `unary_operation` on strategy `child`.
"""
struct StrategyUnaryOperation <: StrategyNode
    unary_operation::String
    child::StrategyNode
end

# redefine comparison
Base.:(==)(x::StrategyUnaryOperation, y::StrategyUnaryOperation) = (
    x.unary_operation == y.unary_operation 
    && x.child == y.child
)

"""
    StrategyBinaryOperation <: StrategyNode

AST Node for binary operations on strategies.

    StrategyBinaryOperation(binary_operation::String, left_child::StrategyNode, right_child::StrategyNode)

Create a StrategyBinaryOperation of type `binary_operation` on strategies `left_child`, `right_child`.
"""
struct StrategyBinaryOperation <: StrategyNode
    binary_operation::String
    left_child::StrategyNode
    right_child::StrategyNode
end

# redefine comparison
Base.:(==)(x::StrategyBinaryOperation, y::StrategyBinaryOperation) = (
    x.binary_operation == y.binary_operation 
    && x.left_child == y.left_child 
    && x.right_child == y.right_child
)

# abstract type for all state nodes
abstract type StateNode <: StrategyNode
end

"""
    StateUnaryOperation <: StateNode

AST Node for unary operations on states.

    StateUnaryOperation(unary_operation::String, child::Union{StateNode, VariableNode})

Create a StateUnaryOperation of type `unary_operation` on state `child`.
"""
struct StateUnaryOperation <: StateNode
    unary_operation::String
    child::Union{StateNode, VariableNode}
end

"""
    StateBinaryOperation <: StateNode

AST Node for binary operations on states.

    StateBinaryOperation(unary_operation::String, left_child::Union{StateNode, VariableNode}, right_child::Union{StateNode, VariableNode})

Create a StateBinaryOperation of type `binary_operation` on states `left_child`, `right_child`.
"""
struct StateBinaryOperation <: StateNode
    binary_operation::String
    left_child::Union{StateNode, VariableNode}
    right_child::Union{StateNode, VariableNode}
end

# abstract type for all constraint nodes
abstract type ConstraintNode <: StateNode
end

"""
    ConstraintConstant <: ConstraintNode

AST Node for boolean constants.

    ConstraintConstant(value::Bool)

Create a ConstraintConstant with value `value`.
"""
struct ConstraintConstant <: ConstraintNode
    value::Bool
end

"""
    ConstraintUnaryOperation <: ConstraintNode

AST Node for unary operations on constraints.

    ConstraintUnaryOperation(unary_operation::String, child::Union{ConstraintNode, ExpressionNode})

Create a ConstraintUnaryOperation of type `unary_operation` on constraint or expression `child`.
"""
struct ConstraintUnaryOperation <: ConstraintNode
    unary_operation::String
    child::Union{ConstraintNode, ExpressionNode}
end

"""
    ConstraintBinaryOperation <: ConstraintNode

AST Node for binary operations on constraints.

    ConstraintBinaryOperation(binary_operation::String, left_child::Union{ConstraintNode, ExpressionNode}, right_child::Union{ConstraintNode, ExpressionNode})

Create a ConstraintBinaryOperation of type `binary_operation` on constraints or expressions `left_child`, `right_child`.
"""
struct ConstraintBinaryOperation <: ConstraintNode
    binary_operation::String
    left_child::Union{ConstraintNode, ExpressionNode}
    right_child::Union{ConstraintNode, ExpressionNode}
end

"""
    VariableList <: ASTNode

AST Node for lists of variables.

    VariableList(variables::Vector{VariableNode})

Create a VariableList of variables `variables`.
"""
struct VariableList <: ASTNode
    variables::Vector{VariableNode}
end

# redefine comparison
Base.:(==)(x::VariableList, y::VariableList) = x.variables == y.variables

"""
    AgentList <: ASTNode

AST Node for lists of agents.

    AgentList(for_all::Bool, agents::VariableList)

Create a AgentList of agents `agents` and if quantifier is `for_all`.
"""
struct AgentList <: ASTNode
    for_all::Bool
    agents::VariableList
end

# redefine comparison
Base.:(==)(x::AgentList, y::AgentList) = x.for_all == y.for_all && x.agents == y.agents

"""
    Quantifier <: StrategyNode

AST Node for quantified strategies.

    Quantifier(for_all::Bool, always::Bool, agent_list::AgentList, child::StrategyNode)

Create a Quantifier on strategy `child` for agents `agent_list`, if quantifier is `for_all` and if strategy must `always` be true.
"""
struct Quantifier <: StrategyNode
    for_all::Bool
    always::Bool
    agent_list::AgentList
    child::StrategyNode
end

# redefine comparison
Base.:(==)(x::Quantifier, y::Quantifier) = (
    x.for_all == y.for_all
    && x.always == y.always
    && x.agent_list == y.agent_list
    && x.child == y.child
)
