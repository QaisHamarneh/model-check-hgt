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

function tokenize(input::String)::Vector{Token}
    tokens::Vector{Token} = Vector{Token}(undef, 0)
    split_input::Vector{SubString{String}} = split(input)

    if length(split_input) != 1
        for substring in split_input
            append!(tokens, tokenize(String(substring)))
        end
        return tokens
    end
        
    token_begin::Int = 1

    for i = firstindex(input):lastindex(input)
        current::String = string(input[i])
        lookahead::String = ""
        if i == length(input)
            lookahead = string(input[i])
        else
            lookahead = input[i] * input[i + 1]
        end

        if lookahead in separators
            tokens = _append_previous_token(input, tokens, token_begin, i)
            push!(tokens, SeparatorToken(lookahead))
            i = i + 1
            token_begin = i + 1
        elseif lookahead in operators
            tokens = _append_previous_token(input, tokens, token_begin, i)
            push!(tokens, OperatorToken(lookahead))
            i = i + 1
            token_begin = i + 1
        elseif current in separators
            tokens = _append_previous_token(input, tokens, token_begin, i)
            push!(tokens, SeparatorToken(current))
            token_begin = i + 1
        elseif current in operators
            tokens = _append_previous_token(input, tokens, token_begin, i)
            push!(tokens, OperatorToken(current))
            token_begin = i + 1
        end
    end
    if token_begin <= lastindex(input)
        token::String = input[token_begin:lastindex(input)]
        if token in keywords
            push!(tokens, KeywordToken(token))
        else
            push!(tokens, CustomToken(token))
        end
    end
    return tokens
end

function _append_previous_token(input::String, tokens::Vector{Token}, token_begin::Int, i::Int)::Vector{Token}
    if token_begin != i
        token::String = input[token_begin:i - 1]
        if token in keywords
            push!(tokens, KeywordToken(token))
        else
            push!(tokens, CustomToken(token))
        end
    end
    return tokens
end
