include("parse_expression.jl")
include("../essential_definitions/constraint.jl")

# function parse_constraint(s::AbstractString)::Constraint
#     # println("Parsing constraint: $s")  # Debugging line
#     s = strip(s)
#     # Truth
#     if s == "true"
#         return Truth(true)
#     elseif s == "false"
#         return Truth(false)
#     end

#     # Parentheses
#     if startswith(s, "(") && endswith(s, ")")
#         # Remove outer parentheses if they enclose the whole string
#         depth = 0
#         for (i, c) in enumerate(s)
#             if c == '('
#                 depth += 1
#             elseif c == ')'
#                 depth -= 1
#                 if depth == 0 && i != lastindex(s)
#                     break
#                 end
#             end
#         end
#         if depth == 0
#             return parse_constraint(s[2:end-1])
#         end
#     end

#     # Not
#     m = match(r"^¬\((.*)\)$", s)
#     if m !== nothing
#         println("Matched negation: $m")  # Debugging line
#         println("Negation content: $(m.captures[1])")  # Debugging line
#         return Not(parse_constraint(m.captures[1]))
#     end

#     # And
#     m = match(r"^(.*)\s*∧\s*(.*)$", s)
#     if m !== nothing
#         return And(parse_constraint(m.captures[1]), parse_constraint(m.captures[2]))
#     end

#     # Or
#     m = match(r"^(.*)\s*∨\s*(.*)$", s)
#     if m !== nothing
#         return Or(parse_constraint(m.captures[1]), parse_constraint(m.captures[2]))
#     end

#     # Comparison operators
#     ops = [
#         (r"^(.*)\s*<=\s*(.*)$", LeQ),
#         (r"^(.*)\s*<\s*(.*)$", Less),
#         (r"^(.*)\s*>=\s*(.*)$", GeQ),
#         (r"^(.*)\s*>\s*(.*)$", Greater),
#         (r"^(.*)\s*==\s*(.*)$", Equal),
#         (r"^(.*)\s*!=\s*(.*)$", NotEqual)
#     ]
#     for (re, ctor) in ops
#         m = match(re, s)
#         if m !== nothing
#             # println("Matched operator: $re")  # Debugging line
#             # println("(m.captures[1]): $(m.captures[1])")  # Debugging line
#             # println("(m.captures[2]): $(m.captures[2])")  # Debugging line
#             left = parse_expr(strip(m.captures[1]))
#             right = parse_expr(strip(m.captures[2]))
#             return ctor(left, right)
#         end
#     end

#     error("Could not parse constraint: $s")
# end


# # println(parse_constraint("x <= 5 ∧ y > 3"))  
# println(parse_constraint("¬(x < 10) ∨ (y == 2)"))  
# println(parse_constraint("(x + y) > 0 ∧ ¬(z == 0)"))  
# println(parse_constraint("true ∨ false"))  
# println(parse_constraint("false ∧ (x != y)"))  
# println(parse_constraint("¬(x <= 5)"))  
# println(parse_constraint("(x < 10) ∨ (y >= 20)"))  
# println(parse_constraint("x == y ∧ y != z"))  
# println(parse_constraint("¬(x > 0) ∨ (y < 5)"))  
# println(parse_constraint("x + y == 10 ∧ z != 0"))  
# println(parse_constraint("¬(        x < 0) ∨ (y > 3)"))  
# println(parse_constraint("x > 0 ∧ y < 5 ∨ z == 10"))  
# println(parse_constraint("true ∧ false ∨ ¬(x == y)"))  
# println(parse_constraint("¬(x <= 5) ∨ (y > 3) ∧ (z < 10)"))  #



"""
    parse_constraint(s::String)::Constraint

Parses a string representing a real arithmetic constraint into a Constraint object.
"""
function parse_constraint(s::String)::Constraint
    expr = Meta.parse(s)
    return _parse_constraint_internal(expr)
end

function _parse_constraint_internal(@nospecialize ex)::Constraint
    if isa(ex, Bool)
        return Truth(ex)
    elseif isa(ex, Expr)
        if ex.head == :call
            op = ex.args[1]
            if op == :<
                return Less(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
            elseif op == :<=
                return LeQ(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
            elseif op == :>
                return Greater(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
            elseif op == :>=
                return GeQ(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
            elseif op == :(==)
                return Equal(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
            elseif op == :(!=) || op == :≠ # Julia uses !=, but ≠ is also supported
                return NotEqual(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
            elseif op == :! # Unary Not
                return Not(_parse_constraint_internal(ex.args[2]))
            else
                error("Unsupported constraint operator: $op")
            end
        elseif ex.head == :&& # Corrected: Handle && directly
            return And(_parse_constraint_internal(ex.args[1]), _parse_constraint_internal(ex.args[2]))
        elseif ex.head == :|| # Corrected: Handle || directly
            return Or(_parse_constraint_internal(ex.args[1]), _parse_constraint_internal(ex.args[2]))
        elseif ex.head == :block
            return _parse_constraint_internal(ex.args[end])
        elseif ex.head == :quote
            return _parse_constraint_internal(ex.args[1])
        else
            error("Unsupported constraint type: $(ex.head)")
        end
    else
        error("Unsupported constraint element: $ex of type $(typeof(ex))")
    end
end


# println(parse_constraint("a >= b && c != d"))  
# println(parse_constraint("!(x < 10) || (y == 2)"))  
# println(parse_constraint("(x + y) > 0 && !(z == 0)"))  
# println(parse_constraint("true || false"))  
# println(parse_constraint("false || (x != y)"))  
# println(parse_constraint("!(x <= 5)"))  
# println(parse_constraint("(x < 10) || (y >= 20)"))  
# println(parse_constraint("x == y && y != z"))  
# println(parse_constraint("!(x > 0) || (y < 5)"))  
# println(parse_constraint("x + y == 10 && z != 0"))  
# println(parse_constraint("!(        x < 0) || (y > 3)"))  
# println(parse_constraint("x > 0 && y < 5 || z == 10"))  
# println(parse_constraint("true && false || !(x == y)"))  
# println(parse_constraint("!(x <= 5) || y > 3 && z + 5 < 10"))