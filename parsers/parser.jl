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
    parse_tokens(tokens::Vector{Token}; level::ParseLevel = strategy)::Union{ASTNode, Nothing}

Convert a vector of tokens into an abstract syntax tree using the given parse level.

See also [`tokenize`]

# Arguments
- `tokens::Vector{Token}`: the tokens to parse
- `level::ParseLevel`: the parse level to use, default is the strategy level

# Examples
```julia-repl
julia> parse_tokens(tokenize("a + b"))
ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b"))
```
"""
function parse_tokens(tokens::Vector{Token}, level::ParseLevel = strategy)::Union{ASTNode, Nothing}
    if length(tokens) == 0
        return Nothing
    end
    
    parsed_tokens::ParseVector = ParseVector(tokens)
    for grammar in get(level_to_grammar, level, [])
        parsed_tokens = _parse_grammar(parsed_tokens, grammar)
    end

    if length(parsed_tokens) > 1
        throw(ParseError("Cannot parse tokens between '$(to_string(parsed_tokens[1]))' and '$(to_string(parsed_tokens[2]))'."))
    elseif length(parsed_tokens) == 1 && !(parsed_tokens[1] isa ASTNode)
        throw(ParseError("Unparsed token at '$(to_string(parsed_tokens[1]))'."))
    end
    return parsed_tokens[1]
end

function _parse_grammar(tokens::ParseVector, grammar::Grammar)::ParseVector
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
            consumable_tokens::Dict{Int, GrammarRule} = _get_consumable_tokens(i, tokens, grammar)
            if haskey(consumable_tokens, i) && _is_strongest_operator(typeof(tokens[i]), i, sort(collect(keys(consumable_tokens))), tokens)
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

function _get_consumable_tokens(current_index::Int, tokens::ParseVector, grammar::Grammar)::Dict{Int, GrammarRule}
    first_rule::GrammarRule = GrammarRule([], [], get)
    for rule in get(grammar, typeof(tokens[current_index]), [])
        if _match_grammar_rule(rule, ParseVector(tokens[begin:(current_index - 1)]), ParseVector(tokens[(current_index + 1):end]))
            first_rule = rule
            break
        end 
    end
    consumable_tokens::Dict{Int, GrammarRule} = Dict([])
    for i in eachindex(tokens)
        for rule in get(grammar, typeof(tokens[i]), [])
            if rule == first_rule && _match_grammar_rule(rule, ParseVector(tokens[begin:(i - 1)]), ParseVector(tokens[(i + 1):end]))
                consumable_tokens[i] = rule
                break
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

function _is_strongest_operator(type::Type, i::Int, indexes::Vector{Int}, tokens::ParseVector)::Bool
    if length(indexes) == 0
        throw(ArgumentError("Index vector cannot be empty."))
    end
    strongest_index::Int = -1
    highest_strength::Int = -1
    if !haskey(operator_type_to_strength, type)
        return true
    end
    binding_strengths::Dict{String, Int} = get(operator_type_to_strength, type, Dict([]))
    for index in indexes
        if get(binding_strengths, tokens[index].type, -1) > highest_strength
            strongest_index = index
            highest_strength = get(binding_strengths, tokens[index].type, -1)
        end
    end
    return strongest_index == i
end
