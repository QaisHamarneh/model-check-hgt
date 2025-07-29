using Match
using DataStructures

abstract type ExprLike end

struct Const <: ExprLike
    value::Float64
end

struct Var <: ExprLike
    name::Symbol
end

struct Neg <: ExprLike
    expr::ExprLike
end

struct Add <: ExprLike
    left::ExprLike
    right::ExprLike
end

struct Mul <: ExprLike
    left::ExprLike
    right::ExprLike
end

struct Sub <: ExprLike
    left::ExprLike
    right::ExprLike
end

struct Div <: ExprLike
    left::ExprLike
    right::ExprLike
end

struct Expon <: ExprLike
    base::ExprLike
    power::ExprLike
end

function evaluate(expr::ExprLike, valuation::OrderedDict{Symbol, Float64})::Float64
    @match expr begin
        Const(value) => round5(value)
        Var(name) => round5(valuation[name])
        Neg(expr1) => round5(-1 * evaluate(expr1, valuation))
        Add(left, right) => round5(evaluate(left, valuation) + evaluate(right, valuation))
        Mul(left, right) => round5(evaluate(left, valuation) * evaluate(right, valuation))
        Sub(left, right) => round5(evaluate(left, valuation) - evaluate(right, valuation))
        Div(left, right) => round5(evaluate(left, valuation) / evaluate(right, valuation))
        Expon(base, power) => round5(evaluate(base, valuation) ^ evaluate(power, valuation))
    end
end

function str(expr::ExprLike)::String
    @match expr begin
        Const(value) => string(value)
        Var(name) => string(name)
        Neg(expr1) => "- ($(str(expr1)))"
        Add(left, right) => "($(str(left)) + $(str(right)))"
        Mul(left, right) => "($(str(left)) * $(str(right)))"
        Sub(left, right) => "($(str(left)) - $(str(right)))"
        Div(left, right) => "($(str(left)) / $(str(right)))"
        Expon(base, power) => "($(str(base))^($(str(power))"
    end
end

function is_constant(expr::ExprLike)::Bool
    @match expr begin
        Const(_) => true
        Var(_) => false
        Neg(expr1) => is_constant(expr1)
        Add(left, right) => is_constant(left) && is_constant(right)
        Mul(left, right) => is_constant(left) && is_constant(right)
        Sub(left, right) => is_constant(left) && is_constant(right)
        Div(left, right) => is_constant(left) && is_constant(right)
        Expon(base, power) => is_constant(base) && is_constant(power)
    end
end

function is_linear(expr::ExprLike)::Bool
    @match expr begin
        Const(_) => true
        Var(_) => true
        Neg(expr1) => is_linear(expr1)
        Add(left, right) => is_linear(left) && is_linear(right)
        Sub(left, right) => is_linear(left) && is_linear(right)
        Mul(left, right) => is_constant(left) || is_constant(right)
        Div(left, right) => is_linear(left) && is_constant(right)
        Expon(base, power) => is_linear(base) && is_constant(power)
    end
end

function simplify(expr::ExprLike)::ExprLike
    @match expr begin
        Const(value) => Const(value)
        Var(name) => Var(name)

        Add(Const(0), right) => right
        Add(left, Const(0)) => left
        Mul(Const(0), right) => Const(0)
        Mul(left, Const(0)) => Const(0)
        Mul(Const(1), right) => right
        Mul(left, Const(1)) => left
        Sub(left, Const(0)) => left
        Sub(Const(0), right) => Mul(Const(-1), right)
        Div(left, Const(1)) => left
        Expon(left, Const(1)) => left
        Expon(Const(1), power) => Const(1)
        Expon(base, Const(0)) => Const(1)
        
        Neg(expr1) => Neg(simplify(expr1))

        Add(left, right) => begin
            left_simplified = simplify(left)
            right_simplified = simplify(right)
            if left_simplified isa Const && right_simplified isa Const
                Const(left_simplified.value + right_simplified.value)
            elseif left_simplified == right_simplified
                Mul(Const(2), left_simplified)
            else
                Add(left_simplified, right_simplified)
            end
        end
        Mul(left, right) => begin
            left_simplified = simplify(left)
            right_simplified = simplify(right)
            if left_simplified isa Const && right_simplified isa Const
                Const(left_simplified.value * right_simplified.value)
            elseif left_simplified == right_simplified
                Expon(left_simplified, Const(2))
            else
                Mul(left_simplified, right_simplified)
            end
        end
        Sub(left, right) => begin
            left_simplified = simplify(left)
            right_simplified = simplify(right)
            if left_simplified isa Const && right_simplified isa Const
                Const(left_simplified.value - right_simplified.value)
            elseif left_simplified == right_simplified
                Const(0)
            else
                Sub(left_simplified, right_simplified)
            end
        end
        Div(left, right) => begin
            left_simplified = simplify(left)
            right_simplified = simplify(right)
            if left_simplified isa Const && right_simplified isa Const
                Const(left_simplified.value / right_simplified.value)
            elseif left_simplified == right_simplified && left_simplified != Const(0)
                Const(1)
            else
                Div(left_simplified, right_simplified)
            end
        end
        Expon(base, power) => begin
            base_simplified = simplify(base)
            power_simplified = simplify(power)
            if base_simplified isa Const && power_simplified isa Const
                Const(base_simplified.value / power_simplified.value)
            else
                Div(base_simplified, power_simplified)
            end
        end
    end
end


# println(evaluate(Add(Var(:x), Const(5)), OrderedDict(:x => 10))) # Should return 15.0
# println(evaluate(Mul(Var(:x), Var(:y)), OrderedDict(:x => 2, :y => 3))) # Should return 6.0
# println(evaluate(Sub(Const(10), Var(:x)), OrderedDict(:x => 4))) # Should return 6.0
# println(evaluate(Div(Var(:x), Const(2)), OrderedDict(:x => 8))) # Should return 4.0

# str(simplify(Mul(Add(Var(:x), Var(:x)), Var(:x)))) # Should return Mul(Var(:x), Const(2))

# println(is_linear(Sub(Div(Var(:x), Const(2)), Neg(Mul(Var(:y), Const(2)))))) # Should return 4.0