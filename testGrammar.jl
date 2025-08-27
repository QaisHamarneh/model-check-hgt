
using DataStructures

function eval_expression(expr::Expr, valuation::OrderedDict{Symbol, Float64})::Float64
    for (var, val) in valuation
        eval(Meta.parse("$(var) = $(val)"))
    end
    return eval(expr)
end


res_1 = eval_expression(:(a + b * 2), OrderedDict(:a => 3.0, :b => 4.0))  # Should return 11.0
println(res_1)
res_2 = eval_expression(:(x^2 + y), OrderedDict(:x => 2.0, :y => 3.0))  # Should return 7.0
println(res_2)  
