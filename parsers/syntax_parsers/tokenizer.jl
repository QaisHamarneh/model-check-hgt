"""
    Tokenizer

This file contains all methods to convert a string into an array of tokens.
The tokens are created according to the set of grammar rules for strategy formulas.

Uses tokens defined by [`tokens.jl`].

# Functions:
- `tokenize(str::String, bindings::Bindings)::Vector{Token}`: returns the tokenized string as an array of tokens

# Types:
- `Bindings`: contains all binded names
- `TokenizeError`: describes an error that occured while tokenizing

# Authors:
- Moritz Maas
"""

include("tokens.jl")

"""
    Bindings

Bindings contain binded variable, location or agent names.

    Bindings(agents::Set{String}, locations::Set{String}, variables::Set{String})

Create Bindings of `agents`, `locations` and `variables`.
"""
struct Bindings
    agents::Set{String}
    locations::Set{String}
    variables::Set{String}
end

# set of all valid separators
separators::Set{String} = Set([
    ",",
    "(",
    ")"
])

# mapping of all keywords to their type of token
keywords::Dict{String, Type} = Dict([
    ("F",     QuantifierToken),
    ("G",     QuantifierToken),

    ("not",   StrategyUnaryOperatorToken),

    ("and",   StrategyBinaryOperatorToken),
    ("or",    StrategyBinaryOperatorToken),
    ("imply", StrategyBinaryOperatorToken),

    ("deadlock", StateConstantToken),

    ("true",  BooleanToken),
    ("false", BooleanToken),

    ("sin",   ExpressionUnaryOperatorToken),
    ("cos",   ExpressionUnaryOperatorToken),
    ("tan",   ExpressionUnaryOperatorToken),
    ("cot",   ExpressionUnaryOperatorToken)
])

# mapping of all operators to their type of token
operators::Dict{String, Type} = Dict([
    ("+",  ExpressionBinaryOperatorToken),
    ("*",  ExpressionBinaryOperatorToken),
    ("/",  ExpressionBinaryOperatorToken),
    ("^",  ExpressionBinaryOperatorToken),

    ("-",  ExpressionUnBinaryOperatorToken),

    ("<",  ConstraintCompareToken),
    ("<=", ConstraintCompareToken),
    (">",  ConstraintCompareToken),
    (">=", ConstraintCompareToken),
    ("==", ConstraintCompareToken),
    ("!=", ConstraintCompareToken),

    ("&&", ConstraintBinaryOperatorToken),
    ("||", ConstraintBinaryOperatorToken),
    ("->", ConstraintBinaryOperatorToken),

    ("!",  ConstraintUnaryOperatorToken),

    ("<<", SeparatorToken),
    (">>", SeparatorToken),
    ("[[", SeparatorToken),
    ("]]", SeparatorToken),
    ("<<>>", EmptyListToken),
    ("[[]]", EmptyListToken)
])

# all symbols that occur in separators
separator_symbols::Set{Char} = Set(union(
    collect(Iterators.flatten(collect(separators)))
))

# all symbols that occur in operators
operator_symbols::Set{Char} = Set(union(
    collect(Iterators.flatten(keys(operators)))
))

# all allowed symbols for custom tokens
unreserved_symbols::Set{Char} = Set(union(
    collect(Iterators.map(x -> Char(x), 65:90)),        # symbols A-Z
    collect(Iterators.map(x -> Char(x), 97:122))        # symbols a-z
))

# numeric symbols
numeric_symbols::Set{Char} = Set(union(
    collect(Iterators.map(x -> Char(x), 48:57)),        # symbols 0-9
))

"""
    tokenize(str::String, bindings::Bindings)::Vector{Token}

Convert an input string `str` into ordered tokens.

# Arguments
- `str::String`: the string input to tokenize
- `bindings::Bindings`: sets of all user-binded words

# Examples
```julia-repl
julia> tokenize("a + b", Bindings(Set([]), Set([]), Set(["a", "b"])))
3-element Vector{Token}:
 VariableToken("a")
 OperatorToken("+")
 VariableToken("b")
```
"""
function tokenize(str::String, bindings::Bindings)::Vector{Token}
    if intersect(bindings.agents, bindings.locations, bindings.variables) != Set([])
        throw(TokenizeError("A name is binded ambiguously."))
    end

    # split string by ' ' characters and call tokenize on all substrings
    split_input::Vector{SubString{String}} = split(str)
    if length(split_input) != 1
        tokens::Vector{Token} = Vector{Token}(undef, 0)
        for substring in split_input
            append!(tokens, tokenize(String(substring), bindings))
        end
        return tokens
    end

    # determine current set of symbols
    current_symbols::Set{Char} = Set{Char}([])
    current_type::Type = Nothing
    if str[1] in separator_symbols
        current_symbols = Set([])
        current_type = SeparatorToken
    elseif str[1] in operator_symbols
        current_symbols = operator_symbols
        current_type = OperatorToken
    elseif str[1] in unreserved_symbols
        current_symbols = union(unreserved_symbols, numeric_symbols, ['_'])
        current_type = CustomToken
    elseif isnumeric(str[1])
        current_symbols = union(numeric_symbols, ['.'])
        current_type = NumericToken
    else
        throw(TokenizeError("'$(str[1])' is an invalid starting symbol."))
    end

    # get longest substring of symbols in the current set of symbols
    for i in (firstindex(str) + 1):lastindex(str)
        if !(str[i] in current_symbols)
            try
                return Vector{Token}([_convert_to_token(str[1:(i - 1)], current_type, bindings); tokenize(str[i:end], bindings)])
            catch e
                throw(e)
            end
        end
    end
    
    return Vector{Token}([_convert_to_token(str, current_type, bindings)])
end

function _convert_to_token(token::String, type::Type, bindings::Bindings)::Token
    if token in separators
        return SeparatorToken(token)
    elseif haskey(keywords, token)
        return get(keywords, token, Nothing)(token)
    elseif haskey(operators, token)
        return get(operators, token, Nothing)(token)
    end

    if type == NumericToken
        if _is_valid_numeric(token)
            return NumericToken(token)
        else
            throw(TokenizeError("'$token' is an invalid number."))
        end
    elseif type == CustomToken
        if token in bindings.agents
            return AgentToken(token)
        elseif token in bindings.locations
            return LocationToken(token)
        elseif token in bindings.variables
            return VariableToken(token)
        else
            throw(TokenizeError("'$token' is not defined in bindings."))
        end
    else
        throw(TokenizeError("'$token' is an invalid sequence of symbols."))
    end
end

function _is_valid_numeric(token::String)::Bool
    return count('.', token) <= 1 && token[end] != '.'
end

"""
    TokenizeError <: Exception

A string cannot be tokenized. `msg` is a descriptive error message.

    TokenizeError(msg::AbstractString)

Create a TokenizeError with message `msg`.
"""
struct TokenizeError <: Exception
    msg::AbstractString
end
