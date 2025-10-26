using Match
using DataStructures

include("expression.jl")

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

struct Imply <: Constraint
    left::Constraint
    right::Constraint
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
        Imply(left, right) => "($(str(left))) → ($(str(right)))"
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
        Imply(left, right) => is_closed(left) && is_closed(right)
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
        Imply(left, right) => Imply(simplify(left), simplify(right))
    end
end

# println(str(simplify(And(Less(Var(:x), Const(10)), Greater(Var(:x), Const(5))))))
# println(evaluate(And(Less(Var(:x), Const(10)), Greater(Var(:x), Const(5))), OrderedDict(:x => 5, :x => 6)))


function get_atomic_constraints(constraint::Constraint)::Vector{Constraint}
    @match constraint begin
        Truth(_) => [constraint]
        Less(left, right) => [constraint]
        LeQ(left, right) => [constraint]
        Greater(left, right) => [constraint]
        GeQ(left, right) => [constraint]
        Equal(left, right) => [constraint]
        NotEqual(left, right) => [constraint]
        And(left, right) => get_atomic_constraints(left) ∪ get_atomic_constraints(right)
        Or(left, right) => get_atomic_constraints(left) ∪ get_atomic_constraints(right)
        Not(constraint) => get_atomic_constraints(constraint)
        Imply(left, right) => get_atomic_constraints(left) ∪ get_atomic_constraints(right)
    end
end

function get_zero(constraint::Constraint)::Vector{ExprLike}
    @match constraint begin
        Truth(true) => ExprLike[Const(0)]
        Truth(false) => ExprLike[Const(1)]
        LeQ(left, right) => ExprLike[Sub(right, left)]
        Less(left, right) => ExprLike[Sub(right, Add(left, Const(1e-5)))]
        GeQ(left, right) => ExprLike[Sub(left, right)]
        Greater(left, right) => ExprLike[Sub(left, Add(right, Const(1e-5)))]
        Equal(left, right) => ExprLike[Sub(left, right)]
        NotEqual(left, right) => get_zero(Greater(left, right)) ∪ get_zero(Less(left, right))
        And(left, right) => get_zero(left) ∪ get_zero(right)
        Or(left, right) => get_zero(left) ∪ get_zero(right)
        Not(constraint) => get_zero(constraint)
        Imply(left, right) => get_zero(left) ∪ get_zero(right)
    end
end

function evaluate(constraint::Constraint, valuation::Valuation)::Bool
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
        Imply(left, right) => !evaluate(left, valuation) || evaluate(right, valuation)
    end
end


function get_satisfied_constraints(constraints, valuation::Valuation)
    filter(constraint -> evaluate(constraint, valuation), constraints)
end

function get_unsatisfied_constraints(constraints, valuation::Valuation)
    filter(constraint -> ! evaluate(constraint, valuation), constraints)
end
