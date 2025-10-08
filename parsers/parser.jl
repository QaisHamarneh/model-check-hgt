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

struct GrammarRule
    left_tokens::Vector{Union{Token, Type}}
    right_tokens::Vector{Union{Token, Type}}
    parse::Function
end

function _parse_numeric_expression(left_tokens::Vector{Union{Token, ExpressionNode}}, token::NumericToken, right_tokens::Vector{Union{Token, ExpressionNode}})::ExpressionNode
    _check_token_count(0, 0, length(left_tokens), length(right_tokens))
    return ExpressionConstant(Real(parse(Float64, token.type)))
end

function _parse_custom_expression(left_tokens::Vector{Union{Token, ExpressionNode}}, token::CustomToken, right_tokens::Vector{Union{Token, ExpressionNode}})::ExpressionNode
    _check_token_count(0, 0, length(left_tokens), length(right_tokens))
    return VariableNode(token.type)
end

function _parse_unary_expression(left_tokens::Vector{Union{Token, ExpressionNode}}, token::ExpressionUnaryOperatorToken, right_tokens::Vector{Union{Token, ExpressionNode}})::ExpressionNode
    _check_token_count(0, 3, length(left_tokens), length(right_tokens))
    return ExpressionUnaryOperation(token.type, right_tokens[2])
end

function _parse_binary_expression(left_tokens::Vector{Union{Token, ExpressionNode}}, token::ExpressionBinaryOperatorToken, right_tokens::Vector{Union{Token, ExpressionNode}})::ExpressionNode
    _check_token_count(1, 1, length(left_tokens), length(right_tokens))
    return ExpressionBinaryOperation(token.type, left_tokens[1], right_tokens[1])
end

expression_grammar::Dict{Type, Vector{GrammarRule}} = Dict([
    (NumericToken, [GrammarRule([], [], _parse_numeric_expression)]),
    (CustomToken, [GrammarRule([], [], _parse_custom_expression)]),
    (ExpressionUnaryOperatorToken, [GrammarRule([], [SeparatorToken("("), ExpressionNode, SeparatorToken(")")], _parse_unary_expression)]),
    (ExpressionBinaryOperatorToken, [GrammarRule([ExpressionNode], [ExpressionNode], _parse_binary_expression)])
])

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

        if haskey(expression_grammar, typeof(tokens[i]))
            rules::Vector{GrammarRule} = get(expression_grammar, typeof(tokens[i]), [])
            matched::Bool = false
            for rule in rules
                if _match_grammar_rule(rule, Vector{Union{Token, StrategyNode}}(expression_tokens), Vector{Union{Token, StrategyNode}}(tokens[i + 1:end]))
                    left_tokens::Vector{Union{Token, ExpressionNode}} = expression_tokens[end - length(rule.left_tokens) + 1:end]
                    expression_tokens = expression_tokens[1:end - length(rule.left_tokens)]
                    right_tokens::Vector{Union{Token, ExpressionNode}} = tokens[i + 1:i + length(rule.right_tokens)]
                    push!(expression_tokens, rule.parse(left_tokens, tokens[i], right_tokens))
                    skips += length(rule.right_tokens)
                    parsed_expression = true
                    matched = true
                    break
                end
            end
            if !matched
                push!(expression_tokens, tokens[i])
            end
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

function _match_grammar_rule(rule::GrammarRule, left_tokens::Vector{Union{Token, StrategyNode}}, right_tokens::Vector{Union{Token, StrategyNode}})::Bool
    if length(rule.left_tokens) > length(left_tokens) || length(rule.right_tokens) > length(right_tokens)
        return false
    end
    left_tokens = left_tokens
    return _match_tokens(rule.left_tokens, left_tokens[end - length(rule.left_tokens) + 1:end]) && _match_tokens(rule.right_tokens, right_tokens[1:length(rule.right_tokens)])
end

function _match_tokens(rule::Vector{Union{Token, Type}}, tokens::Vector{Union{Token, StrategyNode}})::Bool
    if length(rule) != length(tokens)
        throw(ArgumentError("Argument counts not matching."))
    end
    for i in 1:length(rule)
        if rule[i] isa Token && tokens[i] != rule[i]
            return false
        elseif rule[i] isa Type && !(tokens[i] isa rule[i])
            return false
        end
    end
    return true
end

function _check_token_count(l::Int, r::Int, provided_l::Int, provided_r::Int)
    if l != provided_l || r != provided_r
        throw(ParseError("Invalid amount of left or right tokens. Required: $l left, $r right. Provided: $(provided_l), $(provided_r)."))
    end
    return
end

struct ParseError <: Exception
    msg::AbstractString
end
