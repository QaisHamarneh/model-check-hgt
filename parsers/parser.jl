include("tokenizer.jl")

abstract type StrategyNode
end

struct StrategyUnaryOperation <: StrategyNode
    unary_operation::String
    child::StrategyNode
end

struct StrategyBinaryOperation <: StrategyNode
    binary_operation::String
    left_child::StrategyNode
    right_child::StrategyNode
end

abstract type StateNode <: StrategyNode
end

struct StateUnaryOperation <: StateNode
    unary_operation::String
    child::StateNode
end

struct StateBinaryOperation <: StateNode
    binary_operation::String
    left_child::StateNode
    right_child::StateNode
end

abstract type ConstraintNode <: StateNode
end

struct ConstraintConstant <: ConstraintNode
    value::Bool
end

struct ConstraintUnaryOperation <: ConstraintNode
    unary_operation::String
    child::ConstraintNode
end

struct ConstraintBinaryOperation <: ConstraintNode
    binary_operation::String
    left_child::ConstraintNode
    right_child::ConstraintNode
end

abstract type ExpressionNode <: StateNode
end

struct ExpressionConstant <: ExpressionNode
    value::Real
end

struct VariableNode <: ExpressionNode
    name::String
end

struct AgentList <: StrategyNode
    agents::Set{VariableNode}
end

struct Quantifier <: StrategyNode
    for_all::Union{Bool, Nothing}
    always::Bool
    agent_list::Union{AgentList, Nothing}
    child::Union{StrategyNode, Nothing}
end

struct ExpressionUnaryOperation <: ExpressionNode
    unary_operation::String
    child::ExpressionNode
end

struct ExpressionBinaryOperation <: ExpressionNode
    binary_operation::String
    left_child::ExpressionNode
    right_child::ExpressionNode
end

function parse_tokens(tokens::Vector{Token})::StrategyNode
    expression_tokens::Vector{Union{Token, ExpressionNode}} = _parse_expressions(Vector{Union{Token, ExpressionNode}}(tokens))
    return expression_tokens
end

function _parse_expressions(tokens::Vector{Union{Token, ExpressionNode}})::Vector{Union{Token, ExpressionNode}}
    expression_tokens::Vector{Union{Token, ExpressionNode}} = Vector{Union{Token, ExpressionNode}}(undef, 0)
    parsed_expression::Bool = false
    skips::Int = 0
    for i in 1:length(tokens)
        if skips > 0
            skips -= 1
            continue
        end

        if tokens[i] isa NumericToken
            push!(expression_tokens, ExpressionConstant(Real(parse(Float64, tokens[i].type))))
            parsed_expression = true
        elseif tokens[i] isa CustomToken
            push!(expression_tokens, VariableNode(tokens[i].type))
            parsed_expression = true
        elseif (tokens[i] isa ExpressionUnaryOperatorToken
                && tokens[i + 1].type == "(" 
                && tokens[i + 2] isa ExpressionNode
                && tokens[i + 3].type == ")")
            push!(expression_tokens, ExpressionUnaryOperation(tokens[i].type, tokens[i + 2]))
            skips += 3
            parsed_expression = true
        elseif (tokens[i] isa ExpressionBinaryOperatorToken
                && last(expression_tokens) isa ExpressionNode
                && tokens[i + 1] isa ExpressionNode)
            left_child_node::ExpressionNode = pop!(expression_tokens)
            right_child_node::ExpressionNode = tokens[i + 1]
            push!(expression_tokens, ExpressionBinaryOperation(tokens[i].type, left_child_node, right_child_node))
            skips += 1
            parsed_expression = true
        else
            push!(expression_tokens, tokens[i])
        end
    end

    if skips > 0
        throw(ParseError("Missing argument."))
    end

    if parsed_expression
        return _parse_expressions(expression_tokens)
    end
    return expression_tokens
end

struct ParseError <: Exception
    msg::AbstractString
end
