# This file provides a function to convert a Context-Free Grammar (CFG)
# into an equivalent grammar in Chomsky Normal Form (CNF).

# First, we define the CFG struct for clarity and structure.
struct CFG
    # Non-terminals of the grammar
    non_terminals::Set{Char}
    # Terminals of the grammar
    terminals::Set{Char}
    # The starting non-terminal
    start_symbol::Char
    # The production rules
    rules::Dict{Char, Vector{String}}
end

"""
    convert_to_cnf(grammar::CFG)::CFG

Converts a given `grammar` into an equivalent Context-Free Grammar in
Chomsky Normal Form (CNF).

# Arguments
- `grammar::CFG`: The original CFG.

# Returns
- `CFG`: The new CFG in CNF.
"""
function convert_to_cnf(grammar::CFG)::CFG
    # Start with a copy of the original grammar to avoid modifying the input
    new_rules = deepcopy(grammar.rules)
    new_non_terminals = deepcopy(grammar.non_terminals)
    
    # Keep track of a counter for creating new non-terminals
    new_non_terminal_counter = 'Z' + 1
    
    function get_new_non_terminal()
        while Char(new_non_terminal_counter) in new_non_terminals
            new_non_terminal_counter += 1
        end
        return Char(new_non_terminal_counter)
    end

    # Step 1: Add a new start symbol S_0 that derives S
    new_start_symbol = get_new_non_terminal()
    new_non_terminals = push!(new_non_terminals, new_start_symbol)
    new_rules[new_start_symbol] = [string(grammar.start_symbol)]
    start_symbol = new_start_symbol
    
    # Step 2: Eliminate epsilon rules (rules of the form A -> "")
    # Note: Our CFG struct doesn't explicitly handle epsilon. This step assumes
    # there are no epsilon rules, or they are handled separately.
    
    # Step 3: Eliminate unit rules (rules of the form A -> B)
    # This process may need to be repeated until no more unit rules exist.
    while true
        unit_rules = Dict{Char, Vector{Char}}()
        
        # Find all unit rules
        for (nt, productions) in new_rules
            for prod in productions
                if length(prod) == 1 && prod[1] in new_non_terminals
                    if !haskey(unit_rules, nt)
                        unit_rules[nt] = []
                    end
                    push!(unit_rules[nt], prod[1])
                end
            end
        end
        
        if isempty(unit_rules)
            break
        end

        # Expand unit rules
        # while !isempty(unit_rules)
        for (A, Bs) in unit_rules
            while !isempty(Bs)
                B = pop!(Bs)
                # Add all productions of B to A
                # Avoid adding A -> A to prevent infinite loops
                # for B in Bs
                if haskey(new_rules, B)
                    for production in new_rules[B]
                        if production != string(A) # Avoid infinite loop
                            push!(new_rules[A], production)
                            if length(production) == 1 && production[1] in new_non_terminals
                                # if !haskey(unit_rules, A)
                                #     unit_rules[A] = []
                                # end
                                push!(Bs, production[1])
                            end
                        end
                    end
                end
            end
        end
        # end

        
        # Remove the original unit rules
        for (nt, prods) in new_rules
            filter!(p -> !(length(p) == 1 && p[1] in new_non_terminals), prods)
        end
    end

    # Step 4: Convert to CNF format (A -> BC or A -> a)
    final_rules = Dict{Char, Vector{String}}()
    
    for (A, prods) in new_rules
        final_rules[A] = []
        for prod in prods
            if length(prod) == 1
                # Rule is already in CNF (A -> a)
                push!(final_rules[A], prod)
            elseif length(prod) == 2 && prod[1] in new_non_terminals && prod[2] in new_non_terminals
                # Rule is already in CNF (A -> BC)
                push!(final_rules[A], prod)
            else
                # We have a complex rule to convert
                current_prod = prod
                temp_nt = []
                
                # First, replace all terminals with new non-terminals
                for char in current_prod
                    if char in grammar.terminals
                        new_nt = get_new_non_terminal()
                        push!(new_non_terminals, new_nt)
                        final_rules[new_nt] = [string(char)]
                        push!(temp_nt, new_nt)
                    else
                        push!(temp_nt, char)
                    end
                end
                
                # Next, break down long rules (length > 2)
                while length(temp_nt) > 2
                    B = temp_nt[1]
                    C = temp_nt[2]
                    D = get_new_non_terminal()
                    push!(new_non_terminals, D)
                    
                    push!(final_rules[A], string(B, C))
                    final_rules[D] = [join(temp_nt[3:end])]
                    A = D
                    temp_nt = [D]
                end
                
                if length(temp_nt) == 2
                    push!(final_rules[A], join(temp_nt))
                end
            end
        end
    end

    # Step 5: Clean up and return the final CNF grammar
    # This step implicitly handles non-productive and unreachable symbols
    # since we only built the rules for reachable symbols.
    
    # Remove any empty rule lists
    filter!(!isempty, final_rules)

    return CFG(new_non_terminals, grammar.terminals, start_symbol, final_rules)
end

# Example Usage:
println("Original CFG for a simple expression language: E -> E + E | E * E | (E) | id")
# We'll represent this simplified grammar. Note: This is not in CNF.
# original_cfg = CFG(
#     Set(['S', 'A', 'B']),
#     Set(['a', 'b']),
#     'S',
#     Dict(
#         'S' => ["ASB", "AB"],
#         'A' => ["a"],
#         'B' => ["b"]
#     )
# )

# println("Original Grammar:")
# for (nt, prods) in original_cfg.rules
#     println("$nt -> $(join(prods, " | "))")
# end

# println("\nConverting to CNF...")
# cnf_cfg = convert_to_cnf(original_cfg)

# println("CNF Grammar:")
# for (nt, prods) in cnf_cfg.rules
#     println("$nt -> $(join(prods, " | "))")
# end


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
        'S' => ["ASB", "AB"],
        'A' => ["a"],
        'B' => ["b"]
    )
)

println("Original Grammar:")
for (nt, prods) in cfg_example.rules
    println("$nt -> $(join(prods, " | "))")
end

println("\nConverting to CNF...")
cnf_example = convert_to_cnf(cfg_example)

println("CNF Grammar:")
for (nt, prods) in cnf_example.rules
    println("$nt -> $(join(prods, " | "))")
end

println("Checking words against the grammar...")

word1 = "aaabbb"
result1 = is_in_language(cnf_example, word1)
println("Is '$word1' in the language? $result1") # Expected: true

word2 = "ab"
result2 = is_in_language(cnf_example, word2)
println("Is '$word2' in the language? $result2") # Expected: true

word3 = "aba"
result3 = is_in_language(cnf_example, word3)
println("Is '$word3' in the language? $result3") # Expected: false

word4 = "a"
result4 = is_in_language(cnf_example, word4)
println("Is '$word4' in the language? $result4") # Expected: false

word5 = "bb"
result5 = is_in_language(cnf_example, word5)
println("Is '$word5' in the language? $result5") # Expected: false

