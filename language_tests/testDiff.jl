
valuation = Dict(:x => 8, :y => 2, :z => 5)
# for (var, val) in valuation
#     @eval $var = $val
# end

[@eval $var = $val for (var, val) in valuation]

ex1 = Expr(:call, :+, :x, :y)
println("Eval = ", eval(ex1)) # Should return 10

begin
	¬ = ! # \neg
	∧(a,b) = a && b # \wedge
	∨(a,b) = a || b # \vee
	⟹(p,q) = ¬p ∨ q	# \implies
	⟺(p,q) = (p ⟹ q) ∧ (q ⟹ p)	# \iff
end;


("a" == "a") ∧ ("b" == "b") # true


ex3 = :(A + B / (12 % 5))
ex4 = Meta.parse("A + B / (12 % 5)")

println("Parsed expression: ", ex3) # Should print the expression
println("Parsed expression: ", ex4) # Should print the expression   
println("Eq = ", ex3 == ex4) # Should return the evaluated expression


ex5 = Expr(:call, :+, :x, :y)

ex6 = Expr(:call, :&&, :(a > b), :y)

