# This file provides a way to define a Context-Free Grammar (CFG) in Julia
# and a function to get the abstract syntax tree for a word in the language
# defined by that grammar using a modified Cocke-Younger-Kasami (CYK) algorithm.
#
# NOTE: This implementation assumes the grammar is already in Chomsky Normal Form (CNF).
# This means all production rules are of the form A -> BC or A -> a, where A, B, and C
# are non-terminals and 'a' is a terminal. The epsilon (empty) string is not supported.

# First, we define a struct to represent our grammar.
# This provides a clear, structured way to store the grammar components.
struct CFG
    # Non-terminals of the grammar (e.g., S, A, B)
    non_terminals::Set{Char}
    # Terminals of the grammar (e.g., 'a', 'b')
    terminals::Set{Char}
    # The starting non-terminal
    start_symbol::Char
    # The production rules as a dictionary.
    # The keys are the left-hand side non-terminals.
    # The values are a list of possible right-hand side productions.
    # For CNF, these can be either a single terminal character or a two-character string
    # representing two non-terminals.
    rules::Dict{Char, Vector{String}}
end

"""
    is_in_language(grammar::CFG, word::String)::Bool

Checks if a given `word` belongs to the language defined by the `grammar` using
the CYK parsing algorithm. This is a wrapper for `get_ast`.

# Arguments
- `grammar::CFG`: The context-free grammar definition.
- `word::String`: The word to check.

# Returns
- `Bool`: `true` if the word is in the language, `false` otherwise.
"""
function is_in_language(grammar::CFG, word::String)::Bool
    return get_ast(grammar, word) !== nothing
end

"""
    get_ast(grammar::CFG, word::String)::Union{Vector, Nothing}

Constructs the Abstract Syntax Tree (AST) for a given `word` based on the `grammar`.
The function uses a modified CYK algorithm to build a parse table with back-pointers,
which are then used to reconstruct the tree.

# Arguments
- `grammar::CFG`: The context-free grammar definition.
- `word::String`: The word to parse.

# Returns
- `Union{Vector, Nothing}`: A nested array representing the AST, or `nothing` if
  the word is not in the language.
"""
function get_ast(grammar::CFG, word::String)::Union{Vector, Nothing}
    n = length(word)

    # Handle edge cases
    if n == 0
        return nothing
    end

    # The dynamic programming table for the CYK algorithm.
    # T[len][start_idx] will store a dictionary mapping non-terminals to the
    # rules used to derive them, along with the split point for reconstruction.
    T = [[Dict{Char, Union{Char, Tuple{Int, Char, Char}}}() for _ in 1:n] for _ in 1:n]

    # Step 1: Initialize the table for substrings of length 1.
    for j in 1:n
        char = word[j]
        for (nt, productions) in grammar.rules
            for prod in productions
                if prod == string(char)
                    # For terminal rules, we store the terminal character itself.
                    T[1][j][nt] = char
                end
            end
        end
    end

    # Step 2: Fill the rest of the table for substrings of length 2 to n.
    for len in 2:n
        for i in 1:(n - len + 1)
            j = i + len - 1
            for k in i:(j - 1)
                # Left substring is from i to k, right is from k+1 to j
                len1 = k - i + 1
                len2 = j - k
                
                # Check all binary rules A -> BC
                for (nt, productions) in grammar.rules
                    for prod in productions
                        if length(prod) == 2
                            B = prod[1]
                            C = prod[2]
                            # Check if a production can be formed
                            if haskey(T[len1][i], B) && haskey(T[len2][k + 1], C)
                                T[len][i][nt] = (k, B, C)
                            end
                        end
                    end
                end
            end
        end
    end
    
    # Step 3: Check if the full word can be derived from the start symbol.
    if !haskey(T[n][1], grammar.start_symbol)
        return nothing
    end

    # Step 4: Reconstruct the AST using the back-pointers.
    function build_ast(len, start_idx, non_terminal)
        rule = T[len][start_idx][non_terminal]
        
        # Base case: Terminal rule
        if isa(rule, Char)
            return [non_terminal, rule]
        end
        
        # Recursive case: Binary rule A -> BC
        split_k, B, C = rule
        len1 = split_k - start_idx + 1
        len2 = len - len1
        
        child1 = build_ast(len1, start_idx, B)
        child2 = build_ast(len2, split_k + 1, C)
        
        return [non_terminal, child1, child2]
    end

    return build_ast(n, 1, grammar.start_symbol)
end

# Example Usage:
# Define a simple grammar for an expression language: S -> AB | BA, A -> a, B -> b
println("Defining a simple example grammar...")
cfg_example = CFG(
    Set(['S', 'A', 'B']),
    Set(['a', 'b']),
    'S',
    Dict(
        'S' => ["A S B", "A B"],
        'A' => ["a"],
        'B' => ["b"]
    )
)

println("Getting ASTs for words...")

word1 = "aaabbb"
ast1 = get_ast(cfg_example, word1)
println("Word: '$word1'")
println("AST:")
println(ast1) # Expected: a nested array like ['S', ['A', 'a'], ['B', 'b']]
println()

word2 = "ab"
ast2 = get_ast(cfg_example, word2)
println("Word: '$word2'")
println("AST:")
println(ast2) # Expected: a nested array like ['S', ['B', 'b'], ['A', 'a']]
println()

word3 = "aba"
ast3 = get_ast(cfg_example, word3)
println("Word: '$word3'")
println("AST:")
println(ast3) # Expected: nothing
println()

word4 = "a"
ast4 = get_ast(cfg_example, word4)
println("Word: '$word4'")
println("AST:")
println(ast4) # Expected: nothing
println()
