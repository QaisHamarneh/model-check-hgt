include("parse_expression.jl")
include("../essential_definitions/constraint.jl")

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