include("parse_constraint.jl")
include("../STL/logic.jl")

"""
    parse_stl_formula(s::String)::STL_Formula

Parses a string representing an STL formula into an STL_Formula object.
Temporal operators are expected in function call syntax:
- `U(formula1, formula2, begin_time, end_time)` for Until
- `G(formula, begin_time, end_time)` for Always
- `F(formula, begin_time, end_time)` for Eventually
"""
function parse_stl_formula(s::String)::STL_Formula
    if s == ""
        return Truth(true)  # Return a truth constraint for empty input
    end
    expr = Meta.parse(s)
    return _parse_stl_formula_internal(expr)
end

function _parse_stl_formula_internal(@nospecialize ex)::STL_Formula
    if isa(ex, Bool)
        return STL_Truth(ex)
    elseif isa(ex, Symbol)
        return Proposition(ex)
    elseif isa(ex, Expr)
        if ex.head == :call
            op = ex.args[1]
            if op == :U || op == :Until
                # Support both U(a, b, t1, t2) and infix U[a,b]
                left = _parse_stl_formula_internal(ex.args[2])
                right = _parse_stl_formula_internal(ex.args[3])
                t1 = Float64(ex.args[4])
                t2 = Float64(ex.args[5])
                return Until(left, right, t1, t2)
            elseif op == :G || op == :Always
                formula = _parse_stl_formula_internal(ex.args[2])
                t1 = Float64(ex.args[3])
                t2 = Float64(ex.args[4])
                return Always(formula, t1, t2)
            elseif op == :F || op == :Eventually
                formula = _parse_stl_formula_internal(ex.args[2])
                t1 = Float64(ex.args[3])
                t2 = Float64(ex.args[4])
                return Eventually(formula, t1, t2)
            elseif op == :and
                return STL_And(_parse_stl_formula_internal(ex.args[2]), _parse_stl_formula_internal(ex.args[3]))
            elseif op == :or
                return STL_Or(_parse_stl_formula_internal(ex.args[2]), _parse_stl_formula_internal(ex.args[3]))
            elseif op == :not
                return STL_Not(_parse_stl_formula_internal(ex.args[2]))
            elseif op in (:<, :<=, :>, :>=, :(==), :(!=), :≠)
                # Parse as constraint
                return STL_Constraint(_parse_constraint_internal(ex))
            else
                error("Unsupported STL operator: $op")
            end
        elseif ex.head == :!
            return STL_Not(_parse_stl_formula_internal(ex.args[1]))
        elseif ex.head == :&&
            return STL_And(_parse_stl_formula_internal(ex.args[1]), _parse_stl_formula_internal(ex.args[2]))
        elseif ex.head == :||
            return STL_Or(_parse_stl_formula_internal(ex.args[1]), _parse_stl_formula_internal(ex.args[2]))
        elseif ex.head == :comparison
            # Handle chained inequalities as in constraints
            current_constraint = _parse_constraint_internal(ex)
            return STL_Constraint(current_constraint)
        elseif ex.head == :block
            return _parse_stl_formula_internal(ex.args[end])
        elseif ex.head == :quote
            return _parse_stl_formula_internal(ex.args[1])
        elseif ex.head == :curly
            # For U[4,6] style: ex.args[1] == :U, ex.args[2] == 4, ex.args[3] == 6
            # This is only the type, not the call, so handle in :call below
            error("Unexpected curly expression in STL formula: $ex")
        else
            error("Unsupported STL expression type: $(ex.head)")
        end
    else
        error("Unsupported STL formula element: $ex of type $(typeof(ex))")
    end
end

parse_stl_formula("! (a && b) || x > 5 && (y < 10 U[4, 6] c)")