using DataStructures

function round3(num::Float64)::Float64
    return round(num, digits=3)
end

function round3(valuation::OrderedDict{Symbol, Float64})::OrderedDict{Symbol, Float64}
    new_valuation::OrderedDict{Symbol, Float64} = OrderedDict()
    for (var, value) in valuation
        new_valuation[var] = round3(value)
    end
    return new_valuation
end
function round3(expr::ExprLike)::ExprLike
    @match expr begin
        Const(value) => Const(round3(value))
        Var(name) => Var(name)
        Neg(expr1) => Neg(round3(expr1))
        Add(left, right) => Add(round3(left), round3(right))
        Mul(left, right) => Mul(round3(left), round3(right))
        Sub(left, right) => Sub(round3(left), round3(right))
        Div(left, right) => Div(round3(left), round3(right))
        Expon(base, power) => Expon(round3(base), round3(power))
    end
end

function round3(constraint::Constraint)::Constraint
    @match constraint begin
        Truth(value) => Truth(value)
        Less(left, right) => Less(round3(left), round3(right))
        LeQ(left, right) => LeQ(round3(left), round3(right))
        Greater(left, right) => Greater(round3(left), round3(right))
        GeQ(left, right) => GeQ(round3(left), round3(right))
        Equal(left, right) => Equal(round3(left), round3(right))
        NotEqual(left, right) => NotEqual(round3(left), round3(right))
        And(left, right) => And(round3(left), round3(right))
        Or(left, right) => Or(round3(left), round3(right))
        Not(constraint1) => Not(round3(constraint1))
    end
end

function valuation_from_vector(valuation::OrderedDict{Symbol, Float64}, vector::Vector{Float64})::OrderedDict{Symbol, Float64}
    new_valuation::OrderedDict{Symbol, Float64} = OrderedDict()
    for (i, (var, _)) in enumerate(valuation)
        new_valuation[var] = vector[i]
    end
    return new_valuation
end

function find_set(set::Vector, 
                     relation)
    minimums = []
    for element in set
        is_minimal = true
        for other_element in set
            if element != other_element && relation(other_element, element)
                is_minimal = false
                break
            end
        end
        if is_minimal
            push!(minimums, element)
        end
    end
    return minimums
end
