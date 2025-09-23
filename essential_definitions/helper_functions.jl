using DataStructures

function round5(num::Float64)::Float64
    return round(num, digits=5)
end

function round5(valuation::Valuation)::Valuation
    new_valuation::OrderedDict{Symbol, Float64} = OrderedDict()
    for (var, value) in valuation
        new_valuation[var] = round5(value)
    end
    return new_valuation
end

function round5(expr::ExprLike)::ExprLike
    @match expr begin
        Const(value) => Const(round5(value))
        Var(name) => Var(name)
        Neg(expr1) => Neg(round5(expr1))
        Add(left, right) => Add(round5(left), round5(right))
        Mul(left, right) => Mul(round5(left), round5(right))
        Sub(left, right) => Sub(round5(left), round5(right))
        Div(left, right) => Div(round5(left), round5(right))
        Expon(base, power) => Expon(round5(base), round5(power))
    end
end

function round5(constraint::Constraint)::Constraint
    @match constraint begin
        Truth(value) => Truth(value)
        Less(left, right) => Less(round5(left), round5(right))
        LeQ(left, right) => LeQ(round5(left), round5(right))
        Greater(left, right) => Greater(round5(left), round5(right))
        GeQ(left, right) => GeQ(round5(left), round5(right))
        Equal(left, right) => Equal(round5(left), round5(right))
        NotEqual(left, right) => NotEqual(round5(left), round5(right))
        And(left, right) => And(round5(left), round5(right))
        Or(left, right) => Or(round5(left), round5(right))
        Not(constraint1) => Not(round5(constraint1))
    end
end

function valuation_from_vector(valuation::Valuation, vector::Vector{Float64})::Valuation
    new_valuation::OrderedDict{Symbol, Float64} = OrderedDict()
    for (i, (var, _)) in enumerate(valuation)
        new_valuation[var] = vector[i]
    end
    return new_valuation
end

function union_safe(l)
    if isempty(l)
        # Return an empty vector with a specific type if known,
        # or a generic empty vector if not.
        return eltype(l)[] 
    else
        return union(l...)
    end
end