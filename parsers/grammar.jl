"""
    Grammar

This file contains all grammar rules needed to parse a strategy formula.

# Types:
- `GrammarRule`: defines a grammar rule for a `Token` or `ASTNode`
- `ParseError`: describes an error that occured while parsing

# Constants:
- `ParseVector`: type of array of partially parsed tokens
- `agent_grammar`: grammar rules for variable and agent lists
- `expression_grammar`: grammar rules for expressions
- `constraint_grammar`: grammar rules for constraints
- `strategy_grammar`: grammar rules for strategies

# Authors:
- Moritz Maas
"""

include("ast_nodes.jl")

# parse vectors are arrays of partially parsed tokens 
const ParseVector = Vector{Union{Token, ASTNode}}

"""
    GrammarRule

A grammar rule for a `Token` or `ASTNode`.

    GrammarRule(left_tokens::Vector{Union{Token, Type}}, right_tokens::Vector{Union{Token, Type}}, parse::Function)

Create a GrammarRule for a `Token` or `ASTNode` **X**, such that **X** -> `left_tokens` **X** `right_tokens`.
The `Token` or `ASTNode` is parsed according to the `Function` given by `parse`.
"""
struct GrammarRule
    left_tokens::Vector{Union{Token, Type}}
    right_tokens::Vector{Union{Token, Type}}
    parse::Function
end


# any -> any
function _parse_bracket(left_tokens::ParseVector, token::ASTNode, right_tokens::ParseVector)::ASTNode
    _check_token_count(1, 1, left_tokens, right_tokens)
    return token
end


# var -> string
function _parse_custom_expression(left_tokens::ParseVector, token::CustomToken, right_tokens::ParseVector)::VariableNode
    _check_token_count(0, 0, left_tokens, right_tokens)
    return VariableNode(token.type)
end

# var_list -> var , var
function _parse_variable_list_1(left_tokens::ParseVector, token::VariableNode, right_tokens::ParseVector)::VariableList
    _check_token_count(0, 2, left_tokens, right_tokens)
    return VariableList([token, right_tokens[2]])
end

# var_list -> var , var_list
function _parse_variable_list_2(left_tokens::ParseVector, token::VariableList, right_tokens::ParseVector)::VariableList
    _check_token_count(0, 2, left_tokens, right_tokens)
    return VariableList([token, right_tokens[2].variables])
end

# var_list -> var_list , var_list
function _parse_variable_list_3(left_tokens::ParseVector, token::VariableList, right_tokens::ParseVector)::VariableList
    _check_token_count(0, 2, left_tokens, right_tokens)
    return VariableList([token.variables, right_tokens[2].variables])
end

# agent_list -> << var_list >> | [[ var_list ]]
function _parse_agent_list(left_tokens::ParseVector, token::VariableList, right_tokens::ParseVector)::AgentList
    _check_token_count(1, 1, left_tokens, right_tokens)
    return AgentList(left_tokens[1].type == "[[", token)
end

# # agent_list -> << >> | [[ ]]
function _parse_empty_list(left_tokens::ParseVector, token::EmptyListToken, right_tokens::ParseVector)::AgentList
    _check_token_count(0, 0, left_tokens, right_tokens)
    return AgentList(token.type == "[[]]", VariableList([]))
end

const agent_grammar::Dict{Type, Vector{GrammarRule}} = Dict([
    # var -> string
    (CustomToken, [GrammarRule([], [], _parse_custom_expression)]),
    # var_list -> var , var
    (VariableNode, [GrammarRule([], [SeparatorToken(","), VariableNode], _parse_variable_list_1)]),
    # var_list -> var , var_list
    (VariableList, [GrammarRule([], [SeparatorToken(","), VariableNode], _parse_variable_list_2),
    # var_list -> var_list , var_list
                    GrammarRule([], [SeparatorToken(","), VariableList], _parse_variable_list_3),
    # agent_list -> << var_list >>
                    GrammarRule([SeparatorToken("<<")], [SeparatorToken(">>")], _parse_agent_list),
    # agent_list -> [[ var_list ]]
                    GrammarRule([SeparatorToken("[[")], [SeparatorToken("]]")], _parse_agent_list)]),
    # agent_list -> << >> | [[ ]]
    (EmptyListToken, [GrammarRule([], [], _parse_empty_list)])
])



# expr -> number
function _parse_numeric_expression(left_tokens::ParseVector, token::NumericToken, right_tokens::ParseVector)::ExpressionConstant
    _check_token_count(0, 0, left_tokens, right_tokens)
    return ExpressionConstant(Real(parse(Float64, token.type)))
end

# expr -> expr_unary_op expr 
function _parse_unary_expression(left_tokens::ParseVector, token::ExpressionUnaryOperatorToken, right_tokens::ParseVector)::ExpressionUnaryOperation
    _check_token_count(0, 1, left_tokens, right_tokens)
    return ExpressionUnaryOperation(token.type, right_tokens[1])
end

# expr -> expr expr_binary_op expr
function _parse_binary_expression(left_tokens::ParseVector, token::ExpressionBinaryOperatorToken, right_tokens::ParseVector)::ExpressionBinaryOperation
    _check_token_count(1, 1, left_tokens, right_tokens)
    return ExpressionBinaryOperation(token.type, left_tokens[1], right_tokens[1])
end

expression_grammar::Dict{Type, Vector{GrammarRule}} = Dict([
    # expr -> ( expr )
    (VariableNode, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # expr -> ( expr )
    (ExpressionConstant, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # expr -> ( expr )
    (ExpressionUnaryOperation, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # expr -> ( expr )
    (ExpressionBinaryOperation, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # expr -> var
    (CustomToken, [GrammarRule([], [], _parse_custom_expression)]),
    # expr -> number
    (NumericToken, [GrammarRule([], [], _parse_numeric_expression)]),
    # expr -> expr_unary_op expr 
    (ExpressionUnaryOperatorToken, [GrammarRule([], [ExpressionNode], _parse_unary_expression)]),
    # expr -> expr expr_binary_op expr
    (ExpressionBinaryOperatorToken, [GrammarRule([ExpressionNode], [ExpressionNode], _parse_binary_expression)])
])



# constr -> boolean
function _parse_boolean_constraint(left_tokens::ParseVector, token::BooleanToken, right_tokens::ParseVector)::ConstraintConstant
    _check_token_count(0, 0, left_tokens, right_tokens)
    return ConstraintConstant(token.type == "true")
end

# constr -> constr_unary_op constr
function _parse_unary_constraint(left_tokens::ParseVector, token::ConstraintUnaryOperatorToken, right_tokens::ParseVector)::ConstraintUnaryOperation
    _check_token_count(0, 1, left_tokens, right_tokens)
    return ConstraintUnaryOperation(token.type, right_tokens[1])
end

# constr -> constr constr_binary_op constr
function _parse_binary_constraint(left_tokens::ParseVector, token::ConstraintBinaryOperatorToken, right_tokens::ParseVector)::ConstraintBinaryOperation
    _check_token_count(1, 1, left_tokens, right_tokens)
    return ConstraintBinaryOperation(token.type, left_tokens[1], right_tokens[1])
end

# constr -> expr constr_compare_op expr
function _parse_compare_constraint(left_tokens::ParseVector, token::ConstraintCompareToken, right_tokens::ParseVector)::ConstraintBinaryOperation
    _check_token_count(1, 1, left_tokens, right_tokens)
    return ConstraintBinaryOperation(token.type, left_tokens[1], right_tokens[1])
end

const constraint_grammar::Dict{Type, Vector{GrammarRule}} = Dict([
    # constr -> ( constr )
    (ConstraintConstant, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # constr -> ( constr )
    (ConstraintUnaryOperation, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # constr -> ( constr )
    (ConstraintBinaryOperation, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # constr -> boolean
    (BooleanToken, [GrammarRule([], [], _parse_boolean_constraint)]),
    # constr -> constr_unary_op constr
    (ConstraintUnaryOperatorToken, [GrammarRule([], [ConstraintNode], _parse_unary_constraint)]),
    # constr -> constr constr_binary_op constr
    (ConstraintBinaryOperatorToken, [GrammarRule([ConstraintNode], [ConstraintNode], _parse_binary_constraint)]),
    # constr -> expr constr_compare_op expr
    (ConstraintCompareToken, [GrammarRule([ExpressionNode], [ExpressionNode], _parse_compare_constraint)])
])



# state -> location
function _parse_location(left_tokens::ParseVector, token::VariableNode, right_tokens::ParseVector)::LocationNode
    _check_token_count(0, 0, left_tokens, right_tokens)
    return LocationNode(token.name)
end

# state -> state_unary_op state
function _parse_unary_state(left_tokens::ParseVector, token::ConstraintUnaryOperatorToken, right_tokens::ParseVector)::StateUnaryOperation
    _check_token_count(0, 1, left_tokens, right_tokens)
    return StateUnaryOperation(token.type, right_tokens[1])
end

# state -> state state_binary_op state
function _parse_binary_state(left_tokens::ParseVector, token::ConstraintBinaryOperatorToken, right_tokens::ParseVector)::StateBinaryOperation
    _check_token_count(1, 1, left_tokens, right_tokens)
    return StateBinaryOperation(token.type, left_tokens[1], right_tokens[1])
end

const state_grammar::Dict{Type, Vector{GrammarRule}} = Dict([
    # state -> ( state )
    (LocationNode, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # state -> ( state )
    (StateUnaryOperation, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # state -> ( state )
    (StateBinaryOperation, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # state -> location
    (VariableNode, [GrammarRule([], [], _parse_location)]),
    # state -> state_unary_op state
    (ConstraintUnaryOperatorToken, [GrammarRule([], [StateNode], _parse_unary_state)]),
    # state -> state state_binary_op state
    (ConstraintBinaryOperatorToken, [GrammarRule([StateNode], [StateNode], _parse_binary_state)])
])



# strat -> agent_list F strat | agent_list G strat
function _parse_quantifier_strategy(left_tokens::ParseVector, token::QuantifierToken, right_tokens::ParseVector)::Quantifier
    _check_token_count(1, 1, left_tokens, right_tokens)
    return Quantifier(left_tokens[1].for_all, token.type == "G", left_tokens[1], right_tokens[1])
end

# strat -> << >> F strat | << >> G strat | [[ ]] F strat | [[ ]] G strat
function _parse_empty_quantifier_strategy(left_tokens::ParseVector, token::QuantifierToken, right_tokens::ParseVector)::Quantifier
    _check_token_count(2, 1, left_tokens, right_tokens)
    return Quantifier(left_tokens[1].type == "[[", token.type == "G", AgentList(left_tokens[1].type == "[[", VariableList([])), right_tokens[1])
end

# strat -> strat_unary_op strat
function _parse_unary_strategy(left_tokens::ParseVector, token::StrategyUnaryOperatorToken, right_tokens::ParseVector)::StrategyUnaryOperation
    _check_token_count(0, 1, left_tokens, right_tokens)
    return StrategyUnaryOperation(token.type, right_tokens[1])
end

# strat -> strat strat_binary_op strat
function _parse_binary_strategy(left_tokens::ParseVector, token::StrategyBinaryOperatorToken, right_tokens::ParseVector)::StrategyBinaryOperation
    _check_token_count(1, 1, left_tokens, right_tokens)
    return StrategyBinaryOperation(token.type, left_tokens[1], right_tokens[1])
end



const strategy_grammar::Dict{Type, Vector{GrammarRule}} = Dict([
    # strat -> ( strat )
    (Quantifier, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # strat -> ( strat )
    (StrategyUnaryOperation, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # strat -> ( strat )
    (StrategyBinaryOperation, [GrammarRule([SeparatorToken("(")], [SeparatorToken(")")], _parse_bracket)]),
    # strat -> agent_list F strat | agent_list G strat
    (QuantifierToken, [GrammarRule([AgentList], [StrategyNode], _parse_quantifier_strategy),
    # strat -> << >> F strat | << >> G strat
                       GrammarRule([SeparatorToken("<<"), SeparatorToken(">>")], [StrategyNode], _parse_empty_quantifier_strategy),
    # strat -> [[ ]] F strat | [[ ]] G strat
                       GrammarRule([SeparatorToken("[["), SeparatorToken("]]")], [StrategyNode], _parse_empty_quantifier_strategy)]),
    # strat -> strat_unary_op strat
    (StrategyUnaryOperatorToken, [GrammarRule([], [StrategyNode], _parse_unary_strategy)]),
    # strat -> strat strat_binary_op strat
    (StrategyBinaryOperatorToken, [GrammarRule([StrategyNode], [StrategyNode], _parse_binary_strategy)])
])



function _check_token_count(l::Int, r::Int, provided_l::ParseVector, provided_r::ParseVector)
    if l != length(provided_l) || r != length(provided_r)
        throw(ParseError("Invalid amount of left or right tokens. Required: $l left, $r right. Provided: $(length(provided_l)), $(length(provided_r))."))
    end
    return
end

"""
    ParseError <: Exception

A token array cannot be parsed. `msg` is a descriptive error message.

    ParseError(msg::AbstractString)

Create a ParseError with message `msg`.
"""
struct ParseError <: Exception
    msg::AbstractString
end
