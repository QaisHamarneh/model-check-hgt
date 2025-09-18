
include("../essential_definitions/expression.jl")


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
        return Var(ex)
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
            elseif op == :sin
                return Sin(_parse_expr_internal(ex.args[2]))
            elseif op == :cos
                return CoSin(_parse_expr_internal(ex.args[2]))
            elseif op == :tan
                return Tan(_parse_expr_internal(ex.args[2]))
            elseif op == :cot
                return CoTan(_parse_expr_internal(ex.args[2]))
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
# println(parse_expression("sin(x)")) 
# println(parse_expression("5"))  
# println(parse_expression("x + y"))  
# println(simplify(parse_expression("(x + y) - (x + y)")))  
# println(parse_expression("  - x  "))  
# println(parse_expression("3.14 * x - 2 ^ 2"))  
# println(parse_expression("a / (b + 1)"))  
# println(parse_expression("x^2 + 3*x + 2"))  
# println(parse_expression("(b_x + 10)^ 2 + b_y^2"))  
