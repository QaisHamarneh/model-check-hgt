"""
    Parser

This file contains all methods to parse an array of tokens to an abstract syntax tree.
The tokens are parsed according to the set of grammar rules for strategy formulas.

Uses tokens defined by [`tokenizer.jl`], [`grammar.jl`].

# Functions:
- `parse_tokens(tokens::Vector{Token})::ASTNode`: returns the root of the parsed AST

# Authors:
- Moritz Maas
"""

include("tokenizer.jl")
include("grammar.jl")

"""
    parse_tokens(tokens::Vector{Token})

Convert a vector of tokens into an abstract syntax tree.

See also [`tokenize`]

# Arguments
- `tokens::Vector{Token}`: the tokens to parse.

# Examples
```julia-repl
julia> parse_tokens(tokenize("a + b"))
ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b"))
```
"""
function parse_tokens(tokens::Vector{Token})::ASTNode
    # parse agent lists
    parsed_tokens::ParseVector = _parse_grammar(ParseVector(tokens), agent_grammar)
    # parse expressions
    parsed_tokens = _parse_grammar(parsed_tokens, expression_grammar)
    # parse constraints
    parsed_tokens = _parse_grammar(parsed_tokens, constraint_grammar)
    # parse states
    parsed_tokens = _parse_grammar(parsed_tokens, state_grammar)
    # parse strategies
    parsed_tokens = _parse_grammar(parsed_tokens, strategy_grammar)
    
    if length(parsed_tokens) != 1 || !(parsed_tokens[1] isa ASTNode)
        throw(ParseError("$parsed_tokens is an invalid sequence of tokens."))
    end
    return parsed_tokens[1]
end

function _parse_grammar(tokens::ParseVector, grammar::Dict{Type, Vector{GrammarRule}})::ParseVector
    parsed_tokens::ParseVector = ParseVector(undef, 0)
    parsed::Bool = false
    skips::Int = 0
    for i in eachindex(tokens)
        # skip tokens that have been consumed by a grammar rule
        if skips > 0
            skips -= 1
            continue
        end

        # check if grammar rules can be applied to token
        if haskey(grammar, typeof(tokens[i])) && !parsed
            consumable_tokens::Dict{Int, GrammarRule} = _get_consumable_tokens(typeof(tokens[i]), tokens, get(grammar, typeof(tokens[i]), []))
            if haskey(consumable_tokens, i)
                rule::GrammarRule = get(consumable_tokens, i , Nothing)
                left_tokens::ParseVector = parsed_tokens[(end - length(rule.left_tokens) + 1):end]
                parsed_tokens = parsed_tokens[1:(end - length(rule.left_tokens))]
                right_tokens::ParseVector = tokens[(i + 1):(i + length(rule.right_tokens))]

                push!(parsed_tokens, rule.parse(left_tokens, tokens[i], right_tokens))
                skips += length(rule.right_tokens)
                parsed = true
            else
                push!(parsed_tokens, tokens[i])
            end
        else
            push!(parsed_tokens, tokens[i])
        end
    end

    if parsed
        return _parse_grammar(parsed_tokens, grammar)
    end
    return parsed_tokens
end

function _get_consumable_tokens(type::Type, tokens::ParseVector, rules::Vector{GrammarRule})::Dict{Int, GrammarRule}
    consumable_tokens::Dict{Int, GrammarRule} = Dict([])
    for i in eachindex(tokens)
        if typeof(tokens[i]) == type
            for rule in rules
                if _match_grammar_rule(rule, ParseVector(tokens[begin:(i - 1)]), ParseVector(tokens[(i + 1):end]))
                    consumable_tokens[i] = rule
                    break
                end
            end
        end
    end
    return consumable_tokens
end

function _match_grammar_rule(rule::GrammarRule, left_tokens::ParseVector, right_tokens::ParseVector)::Bool
    if length(rule.left_tokens) > length(left_tokens) || length(rule.right_tokens) > length(right_tokens)
        return false
    end
    return _match_tokens(rule.left_tokens, left_tokens[(end - length(rule.left_tokens) + 1):end]) && _match_tokens(rule.right_tokens, right_tokens[1:length(rule.right_tokens)])
end

function _match_tokens(rule::Vector{Union{Token, Type}}, tokens::ParseVector)::Bool
    if length(rule) != length(tokens)
        throw(ArgumentError("Argument counts not matching."))
    end


    for i in eachindex(rule)
        if rule[i] isa Token && tokens[i] != rule[i]
            return false
        elseif rule[i] isa Type && !(tokens[i] isa rule[i])
            return false
        end
    end
    return true
end
