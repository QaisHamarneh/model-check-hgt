# This file provides a way to define a Context-Free Grammar (CFG) in Julia
# and a function to check if a word is in the language defined by that grammar
# using the Cocke-Younger-Kasami (CYK) algorithm.
#
# NOTE: The provided function assumes the grammar is already in Chomsky Normal Form (CNF).
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
the CYK parsing algorithm. The grammar must be in Chomsky Normal Form.

# Arguments
- `grammar::CFG`: The context-free grammar definition.
- `word::String`: The word to check.

# Returns
- `Bool`: `true` if the word is in the language, `false` otherwise.
"""
function is_in_language(grammar::CFG, word::String)::Bool
    n = length(word)

    # Handle edge cases: empty word is not supported by standard CYK for CNF
    if n == 0
        # If the start symbol can derive an empty string, the word would be in the language.
        # But our simplified CNF model doesn't handle this.
        return false
    end

    # The dynamic programming table for the CYK algorithm.
    # T[i, j] will store the set of non-terminals that can generate the substring
    # of length i starting at index j.
    T = [[Set{Char}() for _ in 1:n] for _ in 1:n]

    # Step 1: Initialize the table for substrings of length 1.
    # For each character in the word, find all non-terminals that can produce it.
    for j in 1:n
        char = word[j]
        for (nt, productions) in grammar.rules
            for prod in productions
                if prod == string(char)
                    push!(T[1][j], nt)
                end
            end
        end
    end

    # Step 2: Fill the rest of the table for substrings of length 2 to n.
    for len in 2:n  # Substring length
        for i in 1:(n - len + 1)  # Starting position
            j = i + len - 1  # Ending position
            for k in i:(j - 1) # Split point
                # Check all binary rules A -> BC
                for (nt, productions) in grammar.rules
                    for prod in productions
                        if length(prod) == 2
                            B = prod[1]
                            C = prod[2]
                            # Check if B is in the left part and C is in the right part
                            if B in T[k - i + 1][i] && C in T[j - k][k + 1]
                                push!(T[len][i], nt)
                            end
                        end
                    end
                end
            end
        end
    end

    # Step 3: The word is in the language if the start symbol is in the
    # set for the full word (length n, starting at index 1).
    return grammar.start_symbol in T[n][1]
end

# Example Usage:
# Define a simple grammar for an expression language: S -> AB | BA, A -> a, B -> b
println("Defining a simple example grammar...")
cfg_example = CFG(
    Set(['S', 'A', 'B']),
    Set(['a', 'b']),
    'S',
    Dict(
        'S' => ["AXB", "AB"],
        'X' => ["S"],
        'A' => ["a"],
        'B' => ["b"]
    )
)

convert_to_cnf(cfg_example)

println("Checking words against the grammar...")

word1 = "aaabbb"
result1 = is_in_language(cfg_example, word1)
println("Is '$word1' in the language? $result1") # Expected: true

word2 = "ab"
result2 = is_in_language(cfg_example, word2)
println("Is '$word2' in the language? $result2") # Expected: true

word3 = "aba"
result3 = is_in_language(cfg_example, word3)
println("Is '$word3' in the language? $result3") # Expected: false

word4 = "a"
result4 = is_in_language(cfg_example, word4)
println("Is '$word4' in the language? $result4") # Expected: false

word5 = "bb"
result5 = is_in_language(cfg_example, word5)
println("Is '$word5' in the language? $result5") # Expected: false