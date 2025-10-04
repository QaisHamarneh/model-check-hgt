abstract type Token
end

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

struct KeywordToken <: Token
    type::String
end

keywords::Set{String} = Set([
    "F",
    "G",
    "True",
    "False",
    "sin",
    "cos",
    "tan",
    "cot"
])

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

struct CustomToken <: Token
    type::String
end

reserved_symbols::Set{Char} = Set(union(
    collect(Iterators.flatten(collect(separators))),
    collect(Iterators.flatten(collect(operators)))
))

unreserved_symbols::Set{Char} = Set(union(
    collect(Iterators.map(x -> Char(x), 48:57)),
    collect(Iterators.map(x -> Char(x), 65:90)),
    collect(Iterators.map(x -> Char(x), 97:122)),
    ['_']
))

function tokenize(input::String)::Vector{Token}
    split_input::Vector{SubString{String}} = split(input)

    if length(split_input) != 1
        tokens::Vector{Token} = Vector{Token}(undef, 0)
        for substring in split_input
            append!(tokens, tokenize(String(substring)))
        end
        return tokens
    end

    current_symbols::Set{Char} = Set{Char}([])
    is_custom_token::Bool = false

    if input[1] in reserved_symbols
        current_symbols = reserved_symbols
    elseif input[1] in unreserved_symbols
        current_symbols = unreserved_symbols
        is_custom_token = true
    else
        throw(ArgumentError("$(input[i]) is not a valid symbol."))
    end

    for i in firstindex(input) + 1:lastindex(input)
        if !(input[i] in current_symbols)
            try
                return union(
                Vector{Token}([_convert_to_token(input[1:i - 1], is_custom_token)]),
                tokenize(input[i:end])
                )
            catch e
                throw(e)
            end
        end
    end
    
    return Vector{Token}([_convert_to_token(input, is_custom_token)])
end

function _convert_to_token(token::String, is_custom_token::Bool)::Token
    if is_custom_token && token in keywords
        return KeywordToken(token)
    elseif !is_custom_token
        if token in operators
            return OperatorToken(token)
        elseif token in separators
            return SeparatorToken(token)
        else
            throw(ArgumentError("$token is an invalid sequence of symbols."))
        end
    end
    return CustomToken(token)
end
