"""
    AST Nodes

This file contains all definitions needed to parse tokens to an AST.

# Functions:
- `to_string(node::ASTNode)::String`: convert a node to a string

# Types:
- `ASTNode`: abstract type for all nodes
- `AgentList`: node for agent lists
- `Agents`: node for agent lists
- `StrategyNode`: abstract type for strategy nodes
- `Quantifier`: node for quantified strategies
- `StrategyUnaryOperation`: node for unary operations on strategies
- `StrategyBinaryOperation`: node for binary operations on strategies
- `StateNode`: abstract type for state nodes
- `LocationNode`: node for locations
- `StateConstant`: node for deadlocks
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
    |-- AgentList
    |-- Agents
    |-- StrategyNode
    |   |-- Quantifier
    |   |-- StrategyUnaryOperation
    |   |-- StrategyBinaryOperation
    |   |-- StateNode
    |       |-- LocationNode
    |       |-- StateConstant
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

    VariableNode(value::String)

Create a VariableNode for a variable with name `value`.
"""
struct VariableNode <: ExpressionNode
    value::String
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
    LocationNode <: StateNode

AST Node for locations.

    LocationNode(value::String)

Create a LocationNode for a location with name `value`.
"""
struct LocationNode <: StateNode
    value::String
end

"""
    StateConstant <: StateNode

AST Node for deadlocks.

    StateConstant(value::String)

Create a StateConstant with value `value`.
"""
struct StateConstant <: StateNode
    value::String
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
    AgentList <: ASTNode

AST Node for lists of agents.

    AgentList(agents::Vector{String})

Create an AgentList of agents `agents`.
"""
struct AgentList <: ASTNode
    agents::Vector{String}
end

# redefine comparison
Base.:(==)(x::AgentList, y::AgentList) = x.agents == y.agents

"""
    Agents <: ASTNode

AST Node for sets of agents.

    Agents(for_all::Bool, agents::AgentList)

Create an Agents node of agents `agents` and if quantifier is `for_all`.
"""
struct Agents <: ASTNode
    for_all::Bool
    agents::AgentList
end

# redefine comparison
Base.:(==)(x::Agents, y::Agents) = x.for_all == y.for_all && x.agents == y.agents

"""
    Quantifier <: StrategyNode

AST Node for quantified strategies.

    Quantifier(for_all::Bool, always::Bool, agents::Agents, child::StrategyNode)

Create a Quantifier on strategy `child` for agents `agents`, if quantifier is `for_all` and if strategy must `always` be true.
"""
struct Quantifier <: StrategyNode
    for_all::Bool
    always::Bool
    agents::Agents
    child::StrategyNode
end

# redefine comparison
Base.:(==)(x::Quantifier, y::Quantifier) = (
    x.for_all == y.for_all
    && x.always == y.always
    && x.agents == y.agents
    && x.child == y.child
)

# group operation types
const ConstantOperation = Union{LocationNode, StateConstant, ConstraintConstant, ExpressionConstant, VariableNode}
const UnaryOperation = Union{StrategyUnaryOperation, StateUnaryOperation, ConstraintUnaryOperation, ExpressionUnaryOperation}
const BinaryOperation = Union{StrategyBinaryOperation, StateBinaryOperation, ConstraintBinaryOperation, ExpressionBinaryOperation}

"""
    to_string(node::ConstantOperation)::String

Convert a ConstantOperation `node` to a string.

# Arguments
- `node::ConstantOperation`: node to convert.

# Examples
```julia-repl
julia> to_string(ExpressionConstant(10.0))
"10.0"
```
"""
function to_string(node::ConstantOperation)::String
    return "$(node.value)"
end

"""
    to_string(node::UnaryOperation)::String

Convert a UnaryOperation `node` to a string.

# Arguments
- `node::UnaryOperation`: node to convert.

# Examples
```julia-repl
julia> to_string(ExpressionUnaryOperation("-", VariableNode("x")))
"-(x)"
```
"""
function to_string(node::UnaryOperation)::String
    return "$(node.unary_operation)($(to_string(node.child)))"
end

"""
    to_string(node::BinaryOperation)::String

Convert a BinaryOperation `node` to a string.

# Arguments
- `node::BinaryOperation`: node to convert.

# Examples
```julia-repl
julia> to_string(ExpressionBinaryOperation("+", VariableNode("x"), VariableNode("y")))
"(x)+(y)"
```
"""
function to_string(node::BinaryOperation)::String
    return "($(to_string(node.left_child)))$(node.binary_operation)($(to_string(node.right_child)))"
end

"""
    to_string(node::AgentList)::String

Convert a AgentList `node` to a string.

# Arguments
- `node::AgentList`: node to convert.

# Examples
```julia-repl
julia> to_string(AgentList(["x", "y"]))
"x,y"
```
"""
function to_string(node::AgentList)::String
    if length(node.agents) == 0
        return ""
    end
    output::String = node.agents[1]
    for i in 2:length(node.agents)
        output = output * ",$(node.agents[i])"
    end
    return output
end

"""
    to_string(node::Agents)::String

Convert an Agents node `node` to a string.

# Arguments
- `node::Agents`: node to convert.

# Examples
```julia-repl
julia> to_string(Agents(true, AgentList(["x", "y"])))
"[[x,y]]"
```
"""
function to_string(node::Agents)::String
    if node.for_all
        return "[[$(to_string(node.agents))]]"
    end
    return "<<$(to_string(node.agents))>>"
end

"""
    to_string(node::Quantifier)::String

Convert a Quantifier `node` to a string.

# Arguments
- `node::Quantifier`: node to convert.

# Examples
```julia-repl
julia> to_string(Quantifier(true, true, Agents(true, AgentList([VariableNode("x"), VariableNode("y")])), LocationNode("loc")))
"[[x,y]]G(loc)"
```
"""
function to_string(node::Quantifier)::String
    if node.always
        return "$(to_string(node.agents))G($(to_string(node.child)))"
    end
    return "$(to_string(node.agents))F($(to_string(node.child)))"
end
