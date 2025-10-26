using Test

include("../parsers/syntax_parsers/parser.jl")
include("../parsers/ast_to_logic.jl")

# test expressions

ast::Union{ASTNode, Nothing} = _parse_tokens(tokenize("", Bindings(Set([]), Set([]), Set([]))))
@test isnothing(ast)

ast = _parse_tokens(tokenize("a+b", Bindings(Set([]), Set([]), Set(["a", "b"]))))
@test ast == ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b"))
@test to_string(ast) == "(a)+(b)"
@test to_logic(ast) == Add(Var(:a), Var(:b))
@test ast == _parse_tokens(tokenize("(a+b)", Bindings(Set([]), Set([]), Set(["a", "b"]))), expression)
@test ast == _parse_tokens(tokenize("((a)+b)", Bindings(Set([]), Set([]), Set(["a", "b"]))), constraint)
@test ast == _parse_tokens(tokenize("(a+(b))", Bindings(Set([]), Set([]), Set(["a", "b"]))), state)
@test ast == _parse_tokens(tokenize("((a)+(b))", Bindings(Set([]), Set([]), Set(["a", "b"]))), strategy)
@test ast == _parse_tokens(tokenize("(a)+(b)", Bindings(Set([]), Set([]), Set(["a", "b"]))))
@test_throws ParseError("Cannot parse tokens between 'a' and '('.") _parse_tokens(tokenize("a(+)b", Bindings(Set([]), Set([]), Set(["a", "b"]))))
@test_throws ParseError("Cannot parse tokens between 'a' and '('.") _parse_tokens(tokenize("a()+b", Bindings(Set([]), Set([]), Set(["a", "b"]))))
@test_throws ParseError("Cannot parse tokens between '(a)+(b)' and ')'.") _parse_tokens(tokenize("a+b)", Bindings(Set([]), Set([]), Set(["a", "b"]))))

ast = _parse_tokens(tokenize("-a", Bindings(Set([]), Set([]), Set(["a"]))))
@test ast == ExpressionUnaryOperation("-", VariableNode("a"))
@test to_string(ast) == "-(a)"
@test to_logic(ast) == Neg(Var(:a))
@test ast == _parse_tokens(tokenize("-(a)", Bindings(Set([]), Set([]), Set(["a"]))), expression)
@test ast == _parse_tokens(tokenize("(-(a))", Bindings(Set([]), Set([]), Set(["a"]))), constraint)
@test_throws ParseError("Cannot parse tokens between '(' and '-'.") _parse_tokens(tokenize("(-)(a)", Bindings(Set([]), Set([]), Set(["a"]))))

ast = _parse_tokens(tokenize("b+(-a)", Bindings(Set([]), Set([]), Set(["a", "b"]))))
@test ast == ExpressionBinaryOperation("+", VariableNode("b"), ExpressionUnaryOperation("-", VariableNode("a")))
@test to_string(ast) == "(b)+(-(a))"
@test to_logic(ast) == Add(Var(:b), Neg(Var(:a)))
@test ast == _parse_tokens(tokenize("b+ -a", Bindings(Set([]), Set([]), Set(["a", "b"]))), expression)
@test ast == _parse_tokens(tokenize("(b+(-a))", Bindings(Set([]), Set([]), Set(["a", "b"]))), constraint)
@test_throws TokenizeError("'+-' is an invalid sequence of symbols.") _parse_tokens(tokenize("a+-b", Bindings(Set([]), Set([]), Set(["a", "b"]))))

ast = _parse_tokens(tokenize("a+b-c", Bindings(Set([]), Set([]), Set(["a", "b", "c"]))))
@test to_string(ast) == "((a)+(b))-(c)"
@test to_logic(ast) == Sub(Add(Var(:a), Var(:b)), Var(:c))
@test ast == ExpressionBinaryOperation("-", ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b")), VariableNode("c"))

ast = _parse_tokens(tokenize("a*sin(b)", Bindings(Set([]), Set([]), Set(["a", "b"]))))
@test ast == ExpressionBinaryOperation("*", VariableNode("a"), ExpressionUnaryOperation("sin", VariableNode("b")))
@test to_string(ast) == "(a)*(sin(b))"
@test to_logic(ast) == Mul(Var(:a), Sin(Var(:b)))

ast = _parse_tokens(tokenize("cot(0)/10", Bindings(Set([]), Set([]), Set([]))))
@test ast == ExpressionBinaryOperation("/", ExpressionUnaryOperation("cot", ExpressionConstant(0.0)), ExpressionConstant(10.0))
@test to_string(ast) == "(cot(0.0))/(10.0)"
@test to_logic(ast) == Div(CoTan(Const(0.0)), Const(10.0))
@test ast == _parse_tokens(tokenize("(cot(((0)))/(10))", Bindings(Set([]), Set([]), Set([]))), expression)

ast = ast = _parse_tokens(tokenize("x + y * z", Bindings(Set([]), Set([]), Set(["x", "y", "z"]))))
@test ast == ExpressionBinaryOperation("+", VariableNode("x"), ExpressionBinaryOperation("*", VariableNode("y"), VariableNode("z")))
@test to_string(ast) == "(x)+((y)*(z))"
@test to_logic(ast) == Add(Var(:x), Mul(Var(:y), Var(:z)))
@test ast == _parse_tokens(tokenize("x + (y * z)", Bindings(Set([]), Set([]), Set(["x", "y", "z"]))), expression)
@test ast == _parse_tokens(tokenize("x + (y) * z", Bindings(Set([]), Set([]), Set(["x", "y", "z"]))), constraint)

ast = ast = _parse_tokens(tokenize("x - y * z", Bindings(Set([]), Set([]), Set(["x", "y", "z"]))))
@test ast == ExpressionBinaryOperation("-", VariableNode("x"), ExpressionBinaryOperation("*", VariableNode("y"), VariableNode("z")))
@test to_string(ast) == "(x)-((y)*(z))"

@test to_logic(ast) == Sub(Var(:x), Mul(Var(:y), Var(:z)))
@test ast == _parse_tokens(tokenize("x - (y * z)", Bindings(Set([]), Set([]), Set(["x", "y", "z"]))), expression)
@test ast == _parse_tokens(tokenize("x - (y) * z", Bindings(Set([]), Set([]), Set(["x", "y", "z"]))), constraint)

ast = ast = _parse_tokens(tokenize("x * y - z", Bindings(Set([]), Set([]), Set(["x", "y", "z"]))))
@test ast == ExpressionBinaryOperation("-", ExpressionBinaryOperation("*", VariableNode("x"), VariableNode("y")), VariableNode("z"))
@test to_string(ast) == "((x)*(y))-(z)"
@test to_logic(ast) == Sub(Mul(Var(:x), Var(:y)), Var(:z))
@test ast == _parse_tokens(tokenize("(x * y) - z", Bindings(Set([]), Set([]), Set(["x", "y", "z"]))), expression)
@test ast == _parse_tokens(tokenize("x * y - (z)", Bindings(Set([]), Set([]), Set(["x", "y", "z"]))), constraint)

ast = ast = _parse_tokens(tokenize("-y * z", Bindings(Set([]), Set([]), Set(["y", "z"]))))
@test ast == ExpressionBinaryOperation("*", ExpressionUnaryOperation("-", VariableNode("y")), VariableNode("z"))
@test to_string(ast) == "(-(y))*(z)"
@test to_logic(ast) == Mul(Neg(Var(:y)), Var(:z))
@test ast == _parse_tokens(tokenize("-(y) * z", Bindings(Set([]), Set([]), Set(["y", "z"]))), expression)
@test ast != _parse_tokens(tokenize("-(y * z)", Bindings(Set([]), Set([]), Set(["y", "z"]))), constraint)

ast = ast = _parse_tokens(tokenize("x ^ y - z * 10", Bindings(Set([]), Set([]), Set(["x", "y", "z"]))))
@test ast == ExpressionBinaryOperation(
    "-",
    ExpressionBinaryOperation("^", VariableNode("x"), VariableNode("y")),
    ExpressionBinaryOperation("*", VariableNode("z"), ExpressionConstant(10.0))
)
@test to_string(ast) == "((x)^(y))-((z)*(10.0))"
@test to_logic(ast) == Sub(Expon(Var(:x), Var(:y)), Mul(Var(:z), Const(10.0)))

# test constraints

ast = _parse_tokens(tokenize("x < y + 10", Bindings(Set([]), Set([]), Set(["x", "y"]))))
@test ast == ConstraintBinaryOperation("<", VariableNode("x"), ExpressionBinaryOperation("+", VariableNode("y"), ExpressionConstant(10.0)))
@test to_string(ast) == "(x)<((y)+(10.0))"
@test to_logic(ast) == Less(Var(:x), Add(Var(:y), Const(10.0)))
@test ast == _parse_tokens(tokenize("x < (y + 10)", Bindings(Set([]), Set([]), Set(["x", "y"]))), constraint)
@test ast == _parse_tokens(tokenize("(x < (y + 10))", Bindings(Set([]), Set([]), Set(["x", "y"]))), state)
@test ast == _parse_tokens(tokenize("(x) < (y + 10)", Bindings(Set([]), Set([]), Set(["x", "y"]))))
@test ast == _parse_tokens(tokenize("((x) < (y + 10))", Bindings(Set([]), Set([]), Set(["x", "y"]))))
@test_throws ParseError("Cannot parse tokens between '(x)<(y)' and '+'.") _parse_tokens(tokenize("(x < y) + 10", Bindings(Set([]), Set([]), Set(["x", "y"]))))

ast = _parse_tokens(tokenize("true && x < y", Bindings(Set([]), Set([]), Set(["x", "y"]))))
@test ast == ConstraintBinaryOperation("&&", ConstraintConstant(true), ConstraintBinaryOperation("<", VariableNode("x"), VariableNode("y")))
@test to_string(ast) == "(true)&&((x)<(y))"
@test to_logic(ast) == And(Truth(true), Less(Var(:x), Var(:y)))
@test ast == _parse_tokens(tokenize("(true) && (x < y)", Bindings(Set([]), Set([]), Set(["x", "y"]))), constraint)
@test_throws ParseError("Cannot parse tokens between '(' and 'true'.") _parse_tokens(tokenize("(true && x) < y", Bindings(Set([]), Set([]), Set(["x", "y"]))))

ast = _parse_tokens(tokenize("x < 10 && false", Bindings(Set([]), Set([]), Set(["x"]))))
@test ast == ConstraintBinaryOperation("&&", ConstraintBinaryOperation("<", VariableNode("x"), ExpressionConstant(10.0)), ConstraintConstant(false))
@test to_string(ast) == "((x)<(10.0))&&(false)"
@test to_logic(ast) == And(Less(Var(:x), Const(10.0)), Truth(false))

ast = _parse_tokens(tokenize("true || false && false", Bindings(Set([]), Set([]), Set([]))))
@test ast == ConstraintBinaryOperation("||", ConstraintConstant(true), ConstraintBinaryOperation("&&", ConstraintConstant(false), ConstraintConstant(false)))
@test to_string(ast) == "(true)||((false)&&(false))"
@test to_logic(ast) == Or(Truth(true), And(Truth(false), Truth(false)))

# test states

ast = _parse_tokens(tokenize("true && loc", Bindings(Set([]), Set(["loc"]), Set([]))))
@test ast == StateBinaryOperation("&&", ConstraintConstant(true), LocationNode("loc"))
@test to_string(ast) == "(true)&&(loc)"
@test to_logic(ast) == State_And(State_Constraint(Truth(true)), State_Location(:loc))

ast = _parse_tokens(tokenize("true || false || loc1 && loc2", Bindings(Set([]), Set(["loc1", "loc2"]), Set([]))))
@test ast == StateBinaryOperation(
    "||",
    ConstraintBinaryOperation("||", ConstraintConstant(true), ConstraintConstant(false)),
    StateBinaryOperation("&&", LocationNode("loc1"), LocationNode("loc2"))
)
@test to_string(ast) == "((true)||(false))||((loc1)&&(loc2))"
@test to_logic(ast) == State_Or(State_Constraint(Or(Truth(true), Truth(false))), State_And(State_Location(:loc1), State_Location(:loc2)))

# test strategies

ast = _parse_tokens(tokenize("<<a,b>> F true", Bindings(Set(["a", "b"]), Set([]), Set([]))))
@test ast == Quantifier(false, false, Agents(false, AgentList(["a", "b"])), ConstraintConstant(true))
@test to_string(ast) == "<<a,b>>F(true)"
@test ast == _parse_tokens(tokenize("(<<a,b>> F (true))", Bindings(Set(["a", "b"]), Set([]), Set([]))), strategy)
@test_throws ParseError("Cannot parse tokens between '<<' and '('.") _parse_tokens(tokenize("<<(a,b)>> F true", Bindings(Set(["a", "b"]), Set([]), Set([]))))
@test_throws ParseError("Cannot parse tokens between '(' and '<<'.") _parse_tokens(tokenize("(<<(a),(b)>> F (true))", Bindings(Set(["a", "b"]), Set([]), Set([]))))

ast = _parse_tokens(tokenize("<<a>> F x>5 and y<10", Bindings(Set(["a"]), Set([]), Set(["x", "y"]))))
@test ast == StrategyBinaryOperation(
    "and",
    Quantifier(
        false, false, Agents(false, AgentList(["a"])),
        ConstraintBinaryOperation(">", VariableNode("x"), ExpressionConstant(5.0))
    ),
    ConstraintBinaryOperation("<", VariableNode("y"), ExpressionConstant(10.0))
)
@test to_string(ast) == "(<<a>>F((x)>(5.0)))and((y)<(10.0))"
@test ast == _parse_tokens(tokenize("((<< a >> F x>5) and (y<10))", Bindings(Set(["a"]), Set([]), Set(["x", "y"]))))
@test ast == _parse_tokens(tokenize("((<<a>> F x>5) and (y<10))", Bindings(Set(["a"]), Set([]), Set(["x", "y"]))))

ast = _parse_tokens(tokenize("<< >> F x>5 && y<10", Bindings(Set([]), Set([]), Set(["x", "y"]))))
@test ast == Quantifier(
    false,
    false,
    Agents(false, AgentList([])),
    ConstraintBinaryOperation(
        "&&",
        ConstraintBinaryOperation(">", VariableNode("x"), ExpressionConstant(5.0)),
        ConstraintBinaryOperation("<", VariableNode("y"), ExpressionConstant(10.0)),
    )
)
@test to_string(ast) == "<<>>F(((x)>(5.0))&&((y)<(10.0)))"
@test ast == _parse_tokens(tokenize("(<< >> F (x>5 && y<10))", Bindings(Set([]), Set([]), Set(["x", "y"]))))
@test ast == _parse_tokens(tokenize("(<<>> F (x>5 && y<10))", Bindings(Set([]), Set([]), Set(["x", "y"]))))

ast = _parse_tokens(tokenize("not << >> F true", Bindings(Set([]), Set([]), Set([]))))
@test ast == StrategyUnaryOperation("not", _parse_tokens((tokenize("<< >> F true", Bindings(Set([]), Set([]), Set([]))))))
@test to_string(ast) == "not(<<>>F(true))"
@test ast == _parse_tokens(tokenize("(not (<< >> F (true)))", Bindings(Set([]), Set([]), Set([]))))

ast = _parse_tokens(tokenize("p or q and w", Bindings(Set([]), Set(["p", "q", "w"]), Set([]))))
@test ast == StrategyBinaryOperation("or", LocationNode("p"), StrategyBinaryOperation("and", LocationNode("q"), LocationNode("w")))
@test to_string(ast) == "(p)or((q)and(w))"

# test error handling

@test_throws ParseError("Unparsed token at 'not'.") _parse_tokens(tokenize("not", Bindings(Set([]), Set([]), Set([]))))
@test_throws ParseError("Cannot parse tokens between '14.0' and '&&'.") _parse_tokens(tokenize("14 && true", Bindings(Set([]), Set([]), Set([]))))
@test_throws ParseError("Cannot parse tokens between '<<' and 'a'.") _parse_tokens(tokenize("<<a, >> F true", Bindings(Set(["a"]), Set([]), Set([]))))
@test_throws ParseError("Cannot parse tokens between 'true' and '&&'.") _parse_tokens(tokenize("true && false", Bindings(Set([]), Set([]), Set([]))), expression)
@test_throws ParseError("Cannot parse tokens between 'true' and '&&'.") _parse_tokens(tokenize("true && var", Bindings(Set([]), Set([]), Set(["var"]))), constraint)

# test parse function

expr1 = parse("x + y * z", Bindings(Set([]), Set([]), Set(["x", "y", "z"])), expression)
@test expr1 == Add(Var(:x), Mul(Var(:y), Var(:z)))
@test_throws ParseError("Cannot parse empty expressions or strategies.") parse("", Bindings(Set([]), Set([]), Set([])), expression)

constr1 = parse("x + y * z > 0", Bindings(Set([]), Set([]), Set(["x", "y", "z"])), constraint)
@test constr1 == Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0))
constr2 = parse("x + y * z > 0 && z > 0", Bindings(Set([]), Set([]), Set(["x", "y", "z"])), constraint)
@test constr2 == And(
    Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0)),
    Greater(Var(:z), Const(0.0))
)
constr3 = parse("", Bindings(Set([]), Set([]), Set([])), constraint)
@test constr3 == Truth(true)

state1 = parse("x + y * z > 0", Bindings(Set([]), Set([]), Set(["x", "y", "z"])), state)
@test state1 == State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0)))
state2 = parse("x + y * z > 0 && z > 0", Bindings(Set([]), Set([]), Set(["x", "y", "z"])), state)
@test state2 == State_Constraint(
    And(
        Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0)),
        Greater(Var(:z), Const(0.0))
    )
)
state3 = parse("x + y * z > 0 || z > 0", Bindings(Set([]), Set([]), Set(["x", "y", "z"])), state)
@test state3 == State_Constraint(
    Or(
        Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0)),
        Greater(Var(:z), Const(0.0))
    )
)
state4 = parse("x + y * z > 0 && loc1", Bindings(Set([]), Set(["loc1"]), Set(["x", "y", "z"])), state)
@test state4 == State_And(
    State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0))),
    State_Location(:loc1)
)
state5 = parse("true", Bindings(Set([]), Set([]), Set([])), state)
@test state5 == State_Constraint(Truth(true))
state6 = parse("deadlock", Bindings(Set([]), Set([]), Set([])), state)
@test state6 == State_Deadlock()
state7 = parse("", Bindings(Set([]), Set([]), Set([])), state)
@test state7 == State_Constraint(Truth(false))

strategy1 = parse("true", Bindings(Set([]), Set([]), Set([])), strategy)
@test strategy1 == Strategy_to_State(State_Constraint(Truth(true)))
strategy2 = parse("<<>> F true", Bindings(Set([]), Set([]), Set([])), strategy)
@test strategy2 == Exist_Eventually(Set{Symbol}(), Strategy_to_State(State_Constraint(Truth(true))))
strategy3 = parse("<<A>> F true", Bindings(Set(["A"]), Set([]), Set([])), strategy)
@test strategy3 == Exist_Eventually(Set([:A]), Strategy_to_State(State_Constraint(Truth(true))))
strategy4 = parse("<<A, B, C , D>> F x + y * z > 0 && loc1", Bindings(Set(["A", "B", "C", "D"]), Set(["loc1"]), Set(["x", "y", "z"])), strategy)
@test strategy4 == 
    Exist_Eventually(Set([:A, :D, :B, :C]), 
        Strategy_to_State(State_And(
            State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0))), 
            State_Location(:loc1)
        )
    ))
strategy5 = parse("<<A, B, C , D>> F x + y * z > 0 and loc1", Bindings(Set(["A", "B", "C", "D"]), Set(["loc1"]), Set(["x", "y", "z"])), strategy)
@test strategy5 == 
    Strategy_And(
        Exist_Eventually(Set([:A, :D, :B, :C]), 
            Strategy_to_State(State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0))))), 
        Strategy_to_State(State_Location(:loc1))
    )
strategy6 = parse("<<A, B, C , D>> F <<A, B, C , D>> F x + y * z > 0 and loc1", Bindings(Set(["A", "B", "C", "D"]), Set(["loc1"]), Set(["x", "y", "z"])), strategy)
@test strategy6 == 
    Strategy_And(
        Exist_Eventually(Set([:A, :D, :B, :C]), 
            Exist_Eventually(Set([:A, :D, :B, :C]), 
                Strategy_to_State(State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0)))))), 
        Strategy_to_State(State_Location(:loc1))
    )
strategy7 = parse("loc1 imply <<A, B, C , D>> F <<A, B, C , D>> F x + y * z > 0", Bindings(Set(["A", "B", "C", "D"]), Set(["loc1"]), Set(["x", "y", "z"])), strategy)
@test strategy7 == 
    Strategy_Imply(
        Strategy_to_State(State_Location(:loc1)), 
        Exist_Eventually(Set([:A, :D, :B, :C]), 
            Exist_Eventually(Set([:A, :D, :B, :C]), 
                Strategy_to_State(State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0))))))
    )
@test_throws ParseError("Cannot parse empty expressions or strategies.") parse("", Bindings(Set([]), Set([]), Set([])), strategy)
