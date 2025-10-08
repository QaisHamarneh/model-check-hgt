include("tokenizer.jl")

# AST definition

abstract type ASTNode
end

abstract type ExpressionNode <: ASTNode
end

struct ExpressionConstant <: ExpressionNode
    value::Real
end

struct VariableNode <: ExpressionNode
    name::String
end

struct ExpressionUnaryOperation <: ExpressionNode
    unary_operation::String
    child::Union{ExpressionNode, VariableNode}
end

struct ExpressionBinaryOperation <: ExpressionNode
    binary_operation::String
    left_child::Union{ExpressionNode, VariableNode}
    right_child::Union{ExpressionNode, VariableNode}
end

abstract type StrategyNode <: ASTNode
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
    child::Union{StateNode, VariableNode}
end

struct StateBinaryOperation <: StateNode
    binary_operation::String
    left_child::Union{StateNode, VariableNode}
    right_child::Union{StateNode, VariableNode}
end

abstract type ConstraintNode <: StateNode
end

struct ConstraintConstant <: ConstraintNode
    value::Bool
end

struct ConstraintUnaryOperation <: ConstraintNode
    unary_operation::String
    child::Union{ConstraintNode, ExpressionNode}
end

struct ConstraintBinaryOperation <: ConstraintNode
    binary_operation::String
    left_child::Union{ConstraintNode, ExpressionNode}
    right_child::Union{ConstraintNode, ExpressionNode}
end

struct VariableList <: ASTNode
    variables::Vector{VariableNode}
end

Base.:(==)(x::VariableList, y::VariableList) = x.variables == y.variables

struct AgentList <: ASTNode
    for_all::Bool
    agents::VariableList
end

Base.:(==)(x::AgentList, y::AgentList) = x.for_all == y.for_all && x.agents == y.agents

struct Quantifier <: StrategyNode
    for_all::Bool
    always::Bool
    agent_list::AgentList
    child::StrategyNode
end

# Grammar definition

const ParseVector = Vector{Union{Token, ASTNode}}

struct GrammarRule
    left_tokens::Vector{Union{Token, Type}}
    right_tokens::Vector{Union{Token, Type}}
    parse::Function
end

function _parse_numeric_expression(left_tokens::ParseVector, token::NumericToken, right_tokens::ParseVector)::ExpressionConstant
    _check_token_count(0, 0, left_tokens, right_tokens)
    return ExpressionConstant(Real(parse(Float64, token.type)))
end

function _parse_unary_expression(left_tokens::ParseVector, token::ExpressionUnaryOperatorToken, right_tokens::ParseVector)::ExpressionUnaryOperation
    _check_token_count(0, 3, left_tokens, right_tokens)
    return ExpressionUnaryOperation(token.type, right_tokens[2])
end

function _parse_binary_expression(left_tokens::ParseVector, token::ExpressionBinaryOperatorToken, right_tokens::ParseVector)::ExpressionBinaryOperation
    _check_token_count(1, 1, left_tokens, right_tokens)
    return ExpressionBinaryOperation(token.type, left_tokens[1], right_tokens[1])
end

expression_grammar::Dict{Type, Vector{GrammarRule}} = Dict([
    (NumericToken, [GrammarRule([], [], _parse_numeric_expression)]),
    (ExpressionUnaryOperatorToken, [GrammarRule([], [SeparatorToken("("), ExpressionNode, SeparatorToken(")")], _parse_unary_expression)]),
    (ExpressionBinaryOperatorToken, [GrammarRule([ExpressionNode], [ExpressionNode], _parse_binary_expression)])
])

function _parse_boolean_constraint(left_tokens::ParseVector, token::BooleanToken, right_tokens::ParseVector)::ConstraintConstant
    _check_token_count(0, 0, left_tokens, right_tokens)
    return ConstraintConstant(token.type == "True")
end

function _parse_unary_constraint(left_tokens::ParseVector, token::ConstraintUnaryOperatorToken, right_tokens::ParseVector)::ConstraintUnaryOperation
    _check_token_count(0, 1, left_tokens, right_tokens)
    return ConstraintUnaryOperation(token.type, right_tokens[1])
end

function _parse_binary_constraint(left_tokens::ParseVector, token::ConstraintBinaryOperatorToken, right_tokens::ParseVector)::ConstraintBinaryOperation
    _check_token_count(1, 1, left_tokens, right_tokens)
    return ConstraintBinaryOperation(token.type, left_tokens[1], right_tokens[1])
end

function _parse_compare_constraint(left_tokens::ParseVector, token::ConstraintCompareToken, right_tokens::ParseVector)::ConstraintBinaryOperation
    _check_token_count(1, 1, left_tokens, right_tokens)
    return ConstraintBinaryOperation(token.type, left_tokens[1], right_tokens[1])
end

constraint_grammar::Dict{Type, Vector{GrammarRule}} = Dict([
    (BooleanToken, [GrammarRule([], [], _parse_boolean_constraint)]),
    (ConstraintUnaryOperatorToken, [GrammarRule([], [ConstraintNode], _parse_unary_constraint)]),
    (ConstraintBinaryOperatorToken, [GrammarRule([ConstraintNode], [ConstraintNode], _parse_binary_constraint)]),
    (ConstraintCompareToken, [GrammarRule([ExpressionNode], [ExpressionNode], _parse_compare_constraint)])
])

function _parse_custom_expression(left_tokens::ParseVector, token::CustomToken, right_tokens::ParseVector)::VariableNode
    _check_token_count(0, 0, left_tokens, right_tokens)
    return VariableNode(token.type)
end

function _parse_variable_list_1(left_tokens::ParseVector, token::VariableNode, right_tokens::ParseVector)::VariableList
    _check_token_count(0, 2, left_tokens, right_tokens)
    return VariableList([token, right_tokens[2]])
end

function _parse_variable_list_2(left_tokens::ParseVector, token::VariableList, right_tokens::ParseVector)::VariableList
    _check_token_count(0, 2, left_tokens, right_tokens)
    return VariableList([token, right_tokens[2].variables])
end

function _parse_variable_list_3(left_tokens::ParseVector, token::VariableList, right_tokens::ParseVector)::VariableList
    _check_token_count(0, 2, left_tokens, right_tokens)
    return VariableList([token.variables, right_tokens[2].variables])
end

function _parse_agent_list(left_tokens::ParseVector, token::VariableList, right_tokens::ParseVector)::AgentList
    _check_token_count(1, 1, left_tokens, right_tokens)
    return AgentList(left_tokens[1].type == "[[", token)
end

agent_grammar::Dict{Type, Vector{GrammarRule}} = Dict([
    (CustomToken, [GrammarRule([], [], _parse_custom_expression)]),
    (VariableNode, [GrammarRule([], [SeparatorToken(","), VariableNode], _parse_variable_list_1)]),
    (VariableList, [GrammarRule([], [SeparatorToken(","), VariableNode], _parse_variable_list_2), 
                    GrammarRule([], [SeparatorToken(","), VariableList], _parse_variable_list_3),
                    GrammarRule([SeparatorToken("<<")], [SeparatorToken(">>")], _parse_agent_list),
                    GrammarRule([SeparatorToken("[[")], [SeparatorToken("]]")], _parse_agent_list)])
])

function _parse_quantifier_strategy(left_tokens::ParseVector, token::QuantifierToken, right_tokens::ParseVector)::Quantifier
    _check_token_count(1, 1, left_tokens, right_tokens)
    return Quantifier(left_tokens[1].for_all, token.type == "G", left_tokens[1], right_tokens[1])
end

function _parse_unary_strategy(left_tokens::ParseVector, token::StrategyUnaryOperatorToken, right_tokens::ParseVector)::StrategyUnaryOperation
    _check_token_count(0, 1, left_tokens, right_tokens)
    return StrategyUnaryOperation(token.type, right_tokens[1])
end

function _parse_binary_strategy(left_tokens::ParseVector, token::StrategyBinaryOperatorToken, right_tokens::ParseVector)::StrategyBinaryOperation
    _check_token_count(1, 1, left_tokens, right_tokens)
    return StrategyBinaryOperation(token.type, left_tokens[1], right_tokens[1])
end

strategy_grammar::Dict{Type, Vector{GrammarRule}} = Dict([
    (QuantifierToken, [GrammarRule([AgentList], [StrategyNode], _parse_quantifier_strategy)]),
    (StrategyUnaryOperatorToken, [GrammarRule([], [StrategyNode], _parse_unary_strategy)]),
    (StrategyBinaryOperatorToken, [GrammarRule([StrategyNode], [StrategyNode], _parse_binary_strategy)])
])

"""
    parse_tokens(token::Vector{Token})

Convert a vector of tokens into an abstract syntax tree.

See also [`tokenize`]

# Arguments
- `token::Vector{Token}`: the tokens to parse.

# Examples
```julia-repl
julia> parse_tokens(tokenize("a + b"))
ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b"))
```
"""
function parse_tokens(tokens::Vector{Token})::ASTNode
    parsed_tokens::ParseVector = _parse_grammar(ParseVector(tokens), agent_grammar)
    parsed_tokens = _parse_grammar(parsed_tokens, expression_grammar)
    parsed_tokens = _parse_grammar(parsed_tokens, constraint_grammar)
    parsed_tokens = _parse_grammar(parsed_tokens, strategy_grammar)
    if length(parsed_tokens) != 1
        throw(ParseError("Invalid sequence of tokens."))
    end
    return parsed_tokens[1]
end

function _parse_grammar(tokens::ParseVector, grammar::Dict{Type, Vector{GrammarRule}})::ParseVector
    parsed_tokens::ParseVector = ParseVector(undef, 0)
    parsed::Bool = false
    skips::Int = 0
    for i in 1:length(tokens)
        if skips > 0
            skips -= 1
            continue
        end

        if haskey(grammar, typeof(tokens[i]))
            rules::Vector{GrammarRule} = get(grammar, typeof(tokens[i]), [])
            matched::Bool = false
            for rule in rules
                if _match_grammar_rule(rule, ParseVector(parsed_tokens), ParseVector(tokens[i + 1:end]))
                    left_tokens::ParseVector = parsed_tokens[end - length(rule.left_tokens) + 1:end]
                    parsed_tokens = parsed_tokens[1:end - length(rule.left_tokens)]
                    right_tokens::ParseVector = tokens[i + 1:i + length(rule.right_tokens)]
                    push!(parsed_tokens, rule.parse(left_tokens, tokens[i], right_tokens))
                    skips += length(rule.right_tokens)
                    parsed = true
                    matched = true
                    break
                end
            end
            if !matched
                push!(parsed_tokens, tokens[i])
            end
        else
            push!(parsed_tokens, tokens[i])
        end
    end

    if skips > 0
        throw(ParseError("Missing argument."))
    end

    if parsed
        return _parse_grammar(parsed_tokens, grammar)
    end
    return parsed_tokens
end

function _match_grammar_rule(rule::GrammarRule, left_tokens::ParseVector, right_tokens::ParseVector)::Bool
    if length(rule.left_tokens) > length(left_tokens) || length(rule.right_tokens) > length(right_tokens)
        return false
    end
    left_tokens = left_tokens
    return _match_tokens(rule.left_tokens, left_tokens[end - length(rule.left_tokens) + 1:end]) && _match_tokens(rule.right_tokens, right_tokens[1:length(rule.right_tokens)])
end

function _match_tokens(rule::Vector{Union{Token, Type}}, tokens::ParseVector)::Bool
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

function _check_token_count(l::Int, r::Int, provided_l::Vector, provided_r::Vector)
    if l != length(provided_l) || r != length(provided_r)
        throw(ParseError("Invalid amount of left or right tokens. Required: $l left, $r right. Provided: $(provided_l), $(provided_r)."))
    end
    return
end

struct ParseError <: Exception
    msg::AbstractString
end
