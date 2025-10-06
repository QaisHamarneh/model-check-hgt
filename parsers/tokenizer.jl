abstract type Token
end

"""
    SeparatorToken <: Token

A token for all valid separators.
"""
struct SeparatorToken <: Token
    type::String
end

separators::Set{String} = Set([
    "(",
    ")",
    "<<",
    ">>",
    "[[",
    "]]"
])

"""
    KeywordToken <: Token

A token for all reserved keywords.
"""
struct KeywordToken <: Token
    type::String
end

keywords::Set{String} = Set([
    "F",
    "G",
    "and",
    "or",
    "not",
    "imply",
    "True",
    "False",
    "sin",
    "cos",
    "tan",
    "cot"
])

"""
    OperatorToken <: Token

A token for all valid operators.
"""
struct OperatorToken <: Token
    type::String
end

operators::Set{String} = Set([
    "+",
    "-",
    "*",
    "/",
    "^",

    "<",
    "<=",
    ">",
    ">=",
    "==",
    "!=",

    "!",
    "&&",
    "||",
    "->"
])


"""
    CustomToken <: Token

A token for all user defined variables.
"""
struct CustomToken <: Token
    type::String
end

"""
    NumericToken <: Token

A token for all numeric values.
"""
struct NumericToken <: Token
    type::String
end

reserved_symbols::Set{Char} = Set(union(
    collect(Iterators.flatten(collect(separators))),
    collect(Iterators.flatten(collect(operators)))
))

unreserved_symbols::Set{Char} = Set(union(
    collect(Iterators.map(x -> Char(x), 65:90)),        # symbols A-Z
    collect(Iterators.map(x -> Char(x), 97:122)),       # symbols a-z
    ['_']
))

numeric_symbols::Set{Char} = Set(union(
    collect(Iterators.map(x -> Char(x), 48:57)),        # symbols 0-9
    ['.']
))

"""
    tokenize(str::String)

Convert an input string str into ordered tokens.

# Arguments
- `str::String`: the string input to tokenize.

# Examples
```julia-repl
julia> tokenize("a + b")
3-element Vector{Token}:
 CustomToken("a")
 OperatorToken("+")
 CustomToken("b")
```
"""
function tokenize(str::String)::Vector{Token}
    split_input::Vector{SubString{String}} = split(str)

    if length(split_input) != 1
        tokens::Vector{Token} = Vector{Token}(undef, 0)
        for substring in split_input
            append!(tokens, tokenize(String(substring)))
        end
        return tokens
    end

    current_symbols::Set{Char} = Set{Char}([])
    current_type::Type = Nothing

    if str[1] in reserved_symbols
        current_symbols = reserved_symbols
        current_type = OperatorToken
    elseif str[1] in unreserved_symbols
        current_symbols = union(unreserved_symbols, collect(Iterators.map(x -> Char(x), 48:57)))
        current_type = CustomToken
    elseif isnumeric(str[1])
        current_symbols = numeric_symbols
        current_type = NumericToken
    else
        throw(ArgumentError("$(str[1]) is not a valid symbol."))
    end

    for i in firstindex(str) + 1:lastindex(str)
        if !(str[i] in current_symbols)
            try
                return union(
                Vector{Token}([_convert_to_token(str[1:i - 1], current_type)]),
                tokenize(str[i:end])
                )
            catch e
                throw(e)
            end
        end
    end
    
    return Vector{Token}([_convert_to_token(str, current_type)])
end

function _convert_to_token(token::String, type::Type)::Token
    if token in keywords
        return KeywordToken(token)
    elseif type == NumericToken
        return NumericToken(token)
    elseif type == CustomToken
        return CustomToken(token)
    elseif token in operators
        return OperatorToken(token)
    elseif token in separators
        return SeparatorToken(token)
    else
        throw(ArgumentError("$token is an invalid sequence of symbols."))
    end
end
