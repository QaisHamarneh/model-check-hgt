include("parse_expression.jl")
include("../essential_definitions/constraint.jl")

"""
    parse_constraint(s::String)::Constraint

Parses a string representing a real arithmetic constraint into a Constraint object.
"""
function parse_constraint(s::String)::Constraint
    if s == ""
        return Truth(true)  # Return a truth constraint for empty input
    end
    expr = Meta.parse(s)
    return _parse_constraint_internal(expr)
end

# function _parse_constraint_internal(@nospecialize ex)::Constraint
#     if isa(ex, Bool)
#         return Truth(ex)
#     elseif isa(ex, Expr)
#         if ex.head == :call
#             op = ex.args[1]
#             if op == :<
#                 return Less(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
#             elseif op == :<=
#                 return LeQ(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
#             elseif op == :>
#                 return Greater(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
#             elseif op == :>=
#                 return GeQ(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
#             elseif op == :(==)
#                 return Equal(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
#             elseif op == :(!=) || op == :≠ # Julia uses !=, but ≠ is also supported
#                 return NotEqual(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
#             elseif op == :! # Unary Not
#                 return Not(_parse_constraint_internal(ex.args[2]))
#             else
#                 error("Unsupported constraint operator: $op")
#             end
#         elseif ex.head == :&& # Corrected: Handle && directly
#             return And(_parse_constraint_internal(ex.args[1]), _parse_constraint_internal(ex.args[2]))
#         elseif ex.head == :|| # Corrected: Handle || directly
#             return Or(_parse_constraint_internal(ex.args[1]), _parse_constraint_internal(ex.args[2]))
#         elseif ex.head == :block
#             return _parse_constraint_internal(ex.args[end])
#         elseif ex.head == :quote
#             return _parse_constraint_internal(ex.args[1])
#         else
#             error("Unsupported constraint type: $(ex.head)")
#         end
#     else
#         error("Unsupported constraint element: $ex of type $(typeof(ex))")
#     end
# end

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
        elseif ex.head == :&&
            return And(_parse_constraint_internal(ex.args[1]), _parse_constraint_internal(ex.args[2]))
        elseif ex.head == :||
            return Or(_parse_constraint_internal(ex.args[1]), _parse_constraint_internal(ex.args[2]))
        elseif ex.head == :comparison # Handle chained inequalities
            if length(ex.args) == 5 # Expected format: expr op expr op expr
                left_expr = _parse_expr_internal(ex.args[1])
                op1 = ex.args[2]
                mid_expr = _parse_expr_internal(ex.args[3])
                op2 = ex.args[4]
                right_expr = _parse_expr_internal(ex.args[5])
                return And(
                    _parse_constraint_internal(Expr(:call, op1, ex.args[1], ex.args[3])),
                    _parse_constraint_internal(Expr(:call, op2, ex.args[3], ex.args[5]))
                )
                # if op1 == :<= && op2 == :<
                #     return EqBetween(left_expr, mid_expr, right_expr)
                # elseif op1 == :< && op2 == :<=
                #     return BetweenEq(left_expr, mid_expr, right_expr)
                # elseif op1 == :<= && op2 == :<=
                #     return EqBetweenEq(left_expr, mid_expr, right_expr)
                # else
                #     # If it's a comparison but doesn't match the new types,
                #     # we can convert it to an And constraint of two binary comparisons.
                #     # This makes the parser more robust to other comparison chains.
                #     # For example, "a < b > c" would become And(Less(a,b), Greater(b,c))
                #     # Or you can throw an error if you strictly only allow the 3 new types.
                # end
            else
                # Handle more complex comparison chains by breaking them down into ANDs
                # This ensures any valid Julia chained comparison is parsed.
                # Example: a < b < c < d => And(Less(a,b), And(Less(b,c), Less(c,d)))
                current_constraint = _parse_constraint_internal(Expr(:call, ex.args[2], ex.args[1], ex.args[3]))
                for i in 4:2:length(ex.args)-1
                    op = ex.args[i]
                    next_expr_left = ex.args[i-1]
                    next_expr_right = ex.args[i+1]
                    current_constraint = And(current_constraint, _parse_constraint_internal(Expr(:call, op, next_expr_left, next_expr_right)))
                end
                return current_constraint
            end
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

# # Example Usage for new constraint types:
# println(parse_constraint("1 <= x < 10"))
# println(parse_constraint("y < z + 2 <= 5"))
# println(parse_constraint("0 <= a + b <= 100"))
# println(parse_constraint("x < y == z"))
# println(parse_constraint("a < b <= c < d"))

# # Using previous examples to confirm they still work
# println(parse_constraint("x + y < 10"))
# println(parse_constraint("a >= b && c != d"))
# println(parse_constraint("!(p <= q || r == 5)"))
# println(parse_constraint(""))