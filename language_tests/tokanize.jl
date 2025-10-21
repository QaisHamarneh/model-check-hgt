function tokenize(text::String, operators::Vector{String})::Vector{String}
    tokens = String[]
    i = 1
    n = length(text)

    # Sort operators by length in descending order to match multi-character
    # operators before their single-character components (e.g., "&&" before "&").
    sorted_operators = sort(collect(operators), by=length, rev=true)

    while i <= n
        # Skip any whitespace
        if isspace(text[i])
            i += 1
            continue
        end

        # Check for multi-character operators
        matched_operator = ""
        for op in sorted_operators
            if startswith(text[i:n], op)
                matched_operator = op
                break
            end
        end

        if !isempty(matched_operator)
            # Add the matched operator as a token
            push!(tokens, matched_operator)
            i += length(matched_operator)
        else
            # If not an operator, it must be a variable name.
            # Read until the next space or operator.
            j = i
            while j <= n && !isspace(text[j])
                is_op_prefix = false
                for op in sorted_operators
                    if startswith(text[j:n], op)
                        is_op_prefix = true
                        break
                    end
                end
                if is_op_prefix
                    break
                end
                j += 1
            end
            
            # Extract the variable token
            variable = text[i:j-1]
            if !isempty(variable)
                push!(tokens, variable)
            end
            i = j
        end
    end
    return tokens
end

# Example Usage:
println("Tokenizing an example string...")

operators_list = ["||", "&&", "+", "-", "*", "/", "<=", ">=", "<<", ">>", "=", "<", ">", "!"]
input_string = "x = y + z * a || b"

println("Input String: \"$input_string\"")
println("Operators: $operators_list")
tokens_list = tokenize(input_string, operators_list)
println("Tokens: $tokens_list")

println("\nAnother example with multi-character operators:")
input_string_2 = "a && b << 2"
println("Input String: \"$input_string_2\"")
tokens_list_2 = tokenize(input_string_2, operators_list)
println("Tokens: $tokens_list_2")
