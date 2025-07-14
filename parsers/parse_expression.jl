
include("../essential_definitions/expression.jl")

# function parse_expr(s::AbstractString)::ExprLike
#     s = strip(s)
#     # Parentheses
#     if startswith(s, "(") && endswith(s, ")")
#         # Remove outermost parentheses if they match
#         depth = 0
#         for i in eachindex(s)
#             if s[i] == '('
#                 depth += 1
#             elseif s[i] == ')'
#                 depth -= 1
#             end
#             if depth == 0 && i < length(s)
#                 break
#             end
#             if i == length(s)
#                 return parse_expr(s[2:end-1])
#             end
#         end
#     end

#     # Binary operators, lowest precedence first
#     # ops = [r"\+", r"-", r"\*", r"/", r"\^"]
#     ops = ['+', '-', '*', '/', '^']
#     types = [Add, Sub, Mul, Div, Expon]
#     for (op, T) in zip(ops, types)
#         # Split only at the top level (not inside parentheses)
#         depth = 0
#         for i in eachindex(reverse(s))
#             c = s[i]
#             if c == ')'
#                 depth += 1
#             elseif c == '('
#                 depth -= 1
            
#             elseif depth == 0 && c == op
#                 left = strip(s[1:i-1])
#                 right = strip(s[i+1:end])
#                 if !isempty(left) && !isempty(right)
#                     return T(parse_expr(left), parse_expr(right))
#                 end
#             end
#         end
#     end


#     # Constant (number)
#     if occursin(r"^-?\d+(\.\d+)?$", s)
#         return Const(parse(Float64, s))
#     end

#     # Variable (identifier)
#     if occursin(r"^[a-zA-Z_][a-zA-Z0-9_]*$", s)
#         return Var(s)
#     end

#     # Negation (unary minus)
#     if s[1] == '-' && length(s) > 1
#         return Neg(parse_expr(s[2:end]
#         ))
#     end

#     error("Could not parse expression: $s")
# end


# println(parse_expr("x"))  
# println(parse_expr("5"))  
# println(parse_expr("x + y"))  
# println(simplify(parse_expr("(x + y) - (x + y)")))  
# println(parse_expr("  - x  "))  
# println(parse_expr("3.14 * x - 2 ^ 2"))  
# println(parse_expr("a / (b + 1)"))  
# println(parse_expr("x^2 + 3*x + 2"))  



"""
    parse_expression(s::String)::ExprLike

Parses a string representing a real arithmetic expression into an ExprLike object.
"""
function parse_expression(s::String)::ExprLike
    expr = Meta.parse(s)
    return _parse_expr_internal(expr)
end

function _parse_expr_internal(@nospecialize ex)::ExprLike
    if isa(ex, Number)
        return Const(ex)
    elseif isa(ex, Symbol)
        return Var(string(ex))
    elseif isa(ex, Expr)
        if ex.head == :call
            op = ex.args[1]
            if op == :+
                return Add(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
            elseif op == :-
                if length(ex.args) == 2 # Unary negation
                    return Neg(_parse_expr_internal(ex.args[2]))
                else # Binary subtraction
                    return Sub(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
                end
            elseif op == :*
                return Mul(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
            elseif op == :/
                return Div(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
            elseif op == :^
                return Expon(_parse_expr_internal(ex.args[2]), _parse_expr_internal(ex.args[3]))
            else
                error("Unsupported expression operator: $op")
            end
        elseif ex.head == :block # Handle expressions like begin x + y end
            # Take the last expression in the block
            return _parse_expr_internal(ex.args[end])
        elseif ex.head == :quote # Handle quoted expressions if they appear
            return _parse_expr_internal(ex.args[1])
        else
            error("Unsupported expression type: $(ex.head)")
        end
    else
        error("Unsupported expression element: $ex of type $(typeof(ex))")
    end
end


# println(parse_expression("x"))  
# println(parse_expression("5"))  
# println(parse_expression("x + y"))  
# println(simplify(parse_expression("(x + y) - (x + y)")))  
# println(parse_expression("  - x  "))  
# println(parse_expression("3.14 * x - 2 ^ 2"))  
# println(parse_expression("a / (b + 1)"))  
# println(parse_expression("x^2 + 3*x + 2"))  
