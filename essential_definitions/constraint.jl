include("expression.jl")
using Match
using DataStructures

abstract type Constraint end

struct Truth <: Constraint
    value::Bool
end

struct Less <: Constraint
    left::ExprLike
    right::ExprLike
end

struct LeQ <: Constraint
    left::ExprLike
    right::ExprLike
end

struct Greater <: Constraint
    left::ExprLike
    right::ExprLike
end

struct GeQ <: Constraint
    left::ExprLike
    right::ExprLike
end

struct Equal <: Constraint
    left::ExprLike
    right::ExprLike
end

struct NotEqual <: Constraint
    left::ExprLike
    right::ExprLike
end

struct And <: Constraint
    left::Constraint
    right::Constraint
end

struct Or <: Constraint
    left::Constraint
    right::Constraint
end

struct Not <: Constraint
    constraint::Constraint
end

function evaluate(constraint::Constraint, valuation::OrderedDict)::Bool
    @match constraint begin
        Truth(value) => value
        Less(left, right) => evaluate(left, valuation) < evaluate(right, valuation)
        LeQ(left, right) => evaluate(left, valuation) <= evaluate(right, valuation)
        Greater(left, right) => evaluate(left, valuation) > evaluate(right, valuation)
        GeQ(left, right) => evaluate(left, valuation) >= evaluate(right, valuation)
        Equal(left, right) => evaluate(left, valuation) == evaluate(right, valuation)
        NotEqual(left, right) => evaluate(left, valuation) != evaluate(right, valuation)
        And(left, right) => evaluate(left, valuation) && evaluate(right, valuation)
        Or(left, right) => evaluate(left, valuation) || evaluate(right, valuation)
        Not(constraint) => !evaluate(constraint, valuation)
    end
end

function str(constraint::Constraint)::String
    @match constraint begin
        Truth(value) => string(value)
        Less(left, right) => "$(str(left)) < $(str(right))"
        LeQ(left, right) => "$(str(left)) <= $(str(right))"
        Greater(left, right) => "$(str(left)) > $(str(right))"
        GeQ(left, right) => "$(str(left)) >= $(str(right))"
        Equal(left, right) => "$(str(left)) == $(str(right))"
        NotEqual(left, right) => "$(str(left)) != $(str(right))"
        And(left, right) => "($(str(left))) ∧ ($(str(right)))"
        Or(left, right) => "($(str(left))) ∨ ($(str(right)))"
        Not(constraint) => "¬($(str(constraint)))"
    end
end

function is_closed(constraint::Constraint)::Bool
    @match constraint begin
        Truth(_) => true
        Less(left, right) => false
        LeQ(left, right) => true
        Greater(left, right) => false
        GeQ(left, right) => true
        Equal(left, right) => true
        NotEqual(left, right) => false
        And(left, right) => is_closed(left) && is_closed(right)
        Or(left, right) => is_closed(left) && is_closed(right)
        Not(constraint) => ! is_closed(constraint)
    end
end

function simplify(constraint::Constraint)::Constraint
    @match constraint begin
        Truth(value) => Truth(value)
        Less(left, right) => Less(simplify(left), simplify(right))
        LeQ(left, right) => LeQ(simplify(left), simplify(right))
        Greater(left, right) => Greater(simplify(left), simplify(right))
        GeQ(left, right) => GeQ(simplify(left), simplify(right))
        Equal(left, right) => Equal(simplify(left), simplify(right))
        NotEqual(left, right) => NotEqual(simplify(left), simplify(right))
        And(left, right) => And(simplify(left), simplify(right))
        Or(left, right) => Or(simplify(left), simplify(right))
        Not(constraint) => Not(simplify(constraint))
    end
end

# println(str(simplify(And(Less(Var(:x), Const(10)), Greater(Var(:x), Const(5))))))
# println(evaluate(And(Less(Var(:x), Const(10)), Greater(Var(:x), Const(5))), OrderedDict(:x => 5, :x => 6)))
