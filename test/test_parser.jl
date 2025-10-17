using Test

include("../parsers/parser.jl")

# Test expressions

ast::ASTNode = parse_tokens(tokenize("a+b"))
@test ast == ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b"))
@test to_string(ast) == "(a)+(b)"
@test to_logic(ast) == Add(Var(:a), Var(:b))
@test ast == parse_tokens(tokenize("(a+b)"), expression)
@test ast == parse_tokens(tokenize("((a)+b)"), constraint)
@test ast == parse_tokens(tokenize("(a+(b))"), state)
@test ast == parse_tokens(tokenize("((a)+(b))"), strategy)
@test ast == parse_tokens(tokenize("(a)+(b)"))
@test_throws ParseError("Cannot parse tokens between 'a' and '('.") parse_tokens(tokenize("a(+)b"))
@test_throws ParseError("Cannot parse tokens between 'a' and '('.") parse_tokens(tokenize("a()+b"))
@test_throws ParseError("Cannot parse tokens between '(a)+(b)' and ')'.") parse_tokens(tokenize("a+b)"))

ast = parse_tokens(tokenize("-a"))
@test ast == ExpressionUnaryOperation("-", VariableNode("a"))
@test to_string(ast) == "-(a)"
@test to_logic(ast) == Neg(Var(:a))
@test ast == parse_tokens(tokenize("-(a)"), expression)
@test ast == parse_tokens(tokenize("(-(a))"), constraint)
@test_throws ParseError("Cannot parse tokens between '(' and '-'.") parse_tokens(tokenize("(-)(a)"))

ast = parse_tokens(tokenize("b+(-a)"))
@test ast == ExpressionBinaryOperation("+", VariableNode("b"), ExpressionUnaryOperation("-", VariableNode("a")))
@test to_string(ast) == "(b)+(-(a))"
@test to_logic(ast) == Add(Var(:b), Neg(Var(:a)))
@test ast == parse_tokens(tokenize("b+ -a"), expression)
@test ast == parse_tokens(tokenize("(b+(-a))"), constraint)
@test_throws TokenizeError("+- is an invalid sequence of symbols.") parse_tokens(tokenize("a+-b"))

ast = parse_tokens(tokenize("a+b-c"))
@test to_string(ast) == "((a)+(b))-(c)"
@test to_logic(ast) == Sub(Add(Var(:a), Var(:b)), Var(:c))
@test ast == ExpressionBinaryOperation("-", ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b")), VariableNode("c"))

ast = parse_tokens(tokenize("a*sin(b)"))
@test ast == ExpressionBinaryOperation("*", VariableNode("a"), ExpressionUnaryOperation("sin", VariableNode("b")))
@test to_string(ast) == "(a)*(sin(b))"
@test to_logic(ast) == Mul(Var(:a), Sin(Var(:b)))

ast = parse_tokens(tokenize("cot(0)/10"))
@test ast == ExpressionBinaryOperation("/", ExpressionUnaryOperation("cot", ExpressionConstant(0.0)), ExpressionConstant(10.0))
@test to_string(ast) == "(cot(0.0))/(10.0)"
@test to_logic(ast) == Div(CoTan(Const(0.0)), Const(10.0))
@test ast == parse_tokens(tokenize("(cot(((0)))/(10))"), expression)

ast = ast = parse_tokens(tokenize("x + y * z"))
@test ast == ExpressionBinaryOperation("+", VariableNode("x"), ExpressionBinaryOperation("*", VariableNode("y"), VariableNode("z")))
@test to_string(ast) == "(x)+((y)*(z))"
@test to_logic(ast) == Add(Var(:x), Mul(Var(:y), Var(:z)))
@test ast == parse_tokens(tokenize("x + (y * z)"), expression)
@test ast == parse_tokens(tokenize("x + (y) * z"), constraint)

ast = ast = parse_tokens(tokenize("x - y * z"))
@test ast == ExpressionBinaryOperation("-", VariableNode("x"), ExpressionBinaryOperation("*", VariableNode("y"), VariableNode("z")))
@test to_string(ast) == "(x)-((y)*(z))"

@test to_logic(ast) == Sub(Var(:x), Mul(Var(:y), Var(:z)))
@test ast == parse_tokens(tokenize("x - (y * z)"), expression)
@test ast == parse_tokens(tokenize("x - (y) * z"), constraint)

ast = ast = parse_tokens(tokenize("x * y - z"))
@test ast == ExpressionBinaryOperation("-", ExpressionBinaryOperation("*", VariableNode("x"), VariableNode("y")), VariableNode("z"))
@test to_string(ast) == "((x)*(y))-(z)"
@test to_logic(ast) == Sub(Mul(Var(:x), Var(:y)), Var(:z))
@test ast == parse_tokens(tokenize("(x * y) - z"), expression)
@test ast == parse_tokens(tokenize("x * y - (z)"), constraint)

ast = ast = parse_tokens(tokenize("-y * z"))
@test ast == ExpressionBinaryOperation("*", ExpressionUnaryOperation("-", VariableNode("y")), VariableNode("z"))
@test to_string(ast) == "(-(y))*(z)"
@test to_logic(ast) == Mul(Neg(Var(:y)), Var(:z))
@test ast == parse_tokens(tokenize("-(y) * z"), expression)
@test ast != parse_tokens(tokenize("-(y * z)"), constraint)

ast = ast = parse_tokens(tokenize("x ^ y - z * 10"))
@test ast == ExpressionBinaryOperation(
    "-",
    ExpressionBinaryOperation("^", VariableNode("x"), VariableNode("y")),
    ExpressionBinaryOperation("*", VariableNode("z"), ExpressionConstant(10.0))
)
@test to_string(ast) == "((x)^(y))-((z)*(10.0))"
@test to_logic(ast) == Sub(Expon(Var(:x), Var(:y)), Mul(Var(:z), Const(10.0)))

# Test constraints

ast = parse_tokens(tokenize("x < y + 10"))
@test ast == ConstraintBinaryOperation("<", VariableNode("x"), ExpressionBinaryOperation("+", VariableNode("y"), ExpressionConstant(10.0)))
@test to_string(ast) == "(x)<((y)+(10.0))"
@test to_logic(ast) == Less(Var(:x), Add(Var(:y), Const(10.0)))
@test ast == parse_tokens(tokenize("x < (y + 10)"), constraint)
@test ast == parse_tokens(tokenize("(x < (y + 10))"), state)
@test ast == parse_tokens(tokenize("(x) < (y + 10)"))
@test ast == parse_tokens(tokenize("((x) < (y + 10))"))
@test_throws ParseError("Cannot parse tokens between '(x)<(y)' and '+'.") parse_tokens(tokenize("(x < y) + 10"))

ast = parse_tokens(tokenize("true && x < y"))
@test ast == ConstraintBinaryOperation("&&", ConstraintConstant(true), ConstraintBinaryOperation("<", VariableNode("x"), VariableNode("y")))
@test to_string(ast) == "(true)&&((x)<(y))"
@test to_logic(ast) == And(Truth(true), Less(Var(:x), Var(:y)))
@test ast == parse_tokens(tokenize("(true) && (x < y)"), constraint)
@test_throws ParseError("Cannot parse tokens between '(true)&&(x)' and '<'.") parse_tokens(tokenize("(true && x) < y"))

ast = parse_tokens(tokenize("x < 10 && false"))
@test ast == ConstraintBinaryOperation("&&", ConstraintBinaryOperation("<", VariableNode("x"), ExpressionConstant(10.0)), ConstraintConstant(false))
@test to_string(ast) == "((x)<(10.0))&&(false)"
@test to_logic(ast) == And(Less(Var(:x), Const(10.0)), Truth(false))

ast = parse_tokens(tokenize("true || false && false"))
@test ast == ConstraintBinaryOperation("||", ConstraintConstant(true), ConstraintBinaryOperation("&&", ConstraintConstant(false), ConstraintConstant(false)))
@test to_string(ast) == "(true)||((false)&&(false))"
@test to_logic(ast) == Or(Truth(true), And(Truth(false), Truth(false)))

# Test states

ast = parse_tokens(tokenize("true && loc"))
@test ast == StateBinaryOperation("&&", ConstraintConstant(true), LocationNode("loc"))
@test to_string(ast) == "(true)&&(loc)"
@test to_logic(ast) == State_And(State_Constraint(Truth(true)), State_Location(:loc))

ast = parse_tokens(tokenize("true || false || loc1 && loc2"))
@test ast == StateBinaryOperation(
    "||",
    ConstraintBinaryOperation("||", ConstraintConstant(true), ConstraintConstant(false)),
    StateBinaryOperation("&&", LocationNode("loc1"), LocationNode("loc2"))
)
@test to_string(ast) == "((true)||(false))||((loc1)&&(loc2))"
@test to_logic(ast) == State_Or(State_Constraint(Or(Truth(true), Truth(false))), State_And(State_Location(:loc1), State_Location(:loc2)))

# Test strategies

ast = parse_tokens(tokenize("<<a,b>> F true"))
@test ast == Quantifier(false, false, AgentList(false, VariableList([VariableNode("a"), VariableNode("b")])), ConstraintConstant(true))
@test to_string(ast) == "<<a,b>>F(true)"
@test ast == parse_tokens(tokenize("(<<a,b>> F (true))"), strategy)
@test_throws ParseError("Cannot parse tokens between '<<' and '('.") parse_tokens(tokenize("<<(a,b)>> F true"))
@test_throws ParseError("Cannot parse tokens between '(' and '<<'.") parse_tokens(tokenize("(<<(a),(b)>> F (true))"))

ast = parse_tokens(tokenize("<<a>> F x>5 and y<10"))
@test ast == StrategyBinaryOperation(
    "and",
    Quantifier(
        false, false, AgentList(false, VariableList([VariableNode("a")])),
        ConstraintBinaryOperation(">", VariableNode("x"), ExpressionConstant(5.0))
    ),
    ConstraintBinaryOperation("<", VariableNode("y"), ExpressionConstant(10.0))
)
@test to_string(ast) == "(<<a>>F((x)>(5.0)))and((y)<(10.0))"
@test ast == parse_tokens(tokenize("((<< a >> F x>5) and (y<10))"))
@test ast == parse_tokens(tokenize("((<<a>> F x>5) and (y<10))"))

ast = parse_tokens(tokenize("<< >> F x>5 && y<10"))
@test ast == Quantifier(
    false,
    false,
    AgentList(false, VariableList([])),
    ConstraintBinaryOperation(
        "&&",
        ConstraintBinaryOperation(">", VariableNode("x"), ExpressionConstant(5.0)),
        ConstraintBinaryOperation("<", VariableNode("y"), ExpressionConstant(10.0)),
    )
)
@test to_string(ast) == "<<>>F(((x)>(5.0))&&((y)<(10.0)))"
@test ast == parse_tokens(tokenize("(<< >> F (x>5 && y<10))"))
@test ast == parse_tokens(tokenize("(<<>> F (x>5 && y<10))"))

ast = parse_tokens(tokenize("not << >> F true"))
@test ast == StrategyUnaryOperation("not", parse_tokens((tokenize("<< >> F true"))))
@test to_string(ast) == "not(<<>>F(true))"
@test ast == parse_tokens(tokenize("(not (<< >> F (true)))"))

ast = parse_tokens(tokenize("p or q and w"))
@test ast == StrategyBinaryOperation("or", LocationNode("p"), StrategyBinaryOperation("and", LocationNode("q"), LocationNode("w")))
@test to_string(ast) == "(p)or((q)and(w))"

# Test error handling

@test_throws ParseError("Unparsed token at 'not'.") parse_tokens(tokenize("not"))
@test_throws ParseError("Cannot parse tokens between '14.0' and '&&'.") parse_tokens(tokenize("14 && true"))
@test_throws ParseError("Cannot parse tokens between '<<' and 'a'.") parse_tokens(tokenize("<<a, >> F true"))
@test_throws ParseError("Cannot parse tokens between 'true' and '&&'.") parse_tokens(tokenize("true && false"), expression)
@test_throws ParseError("Cannot parse tokens between 'true' and '&&'.") parse_tokens(tokenize("true && var"), constraint)



#################################
# Comprehensive tests for to_logic function
#################################
expr1 = to_logic(parse_tokens(tokenize("x + y * z")))
@test expr1 == Add(Var(:x), Mul(Var(:y), Var(:z)))
constr1 = to_logic(parse_tokens(tokenize("x + y * z > 0"), constraint))
@test constr1 == Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0))
constr2 = to_logic(parse_tokens(tokenize("x + y * z > 0 && z > 0"), constraint))
@test constr2 == And(
    Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0)),
    Greater(Var(:z), Const(0.0))
)
state1 = to_logic(parse_tokens(tokenize("x + y * z > 0"), state))
@test state1 == State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0)))
state2 = to_logic(parse_tokens(tokenize("x + y * z > 0 && z > 0"), state))
@test state2 == State_Constraint(
    And(
        Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0)),
        Greater(Var(:z), Const(0.0))
    )
)
state3 = to_logic(parse_tokens(tokenize("x + y * z > 0 || z > 0"), state))
@test state3 == State_Constraint(
    Or(
        Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0)),
        Greater(Var(:z), Const(0.0))
    )
)
state4 = to_logic(parse_tokens(tokenize("x + y * z > 0 && loc1"), state))
@test state4 == State_And(
    State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0))),
    State_Location(:loc1)
)
state5 = to_logic(parse_tokens(tokenize("true"), state))
@test state5 == State_Constraint(Truth(true))
strategy1 = to_logic(parse_tokens(tokenize("true"), strategy))
@test strategy1 == Strategy_to_State(State_Constraint(Truth(true)))
strategy2 = to_logic(parse_tokens(tokenize("<<>> F true"), strategy))
@test strategy2 == Exist_Eventually(Set{Symbol}(), Strategy_to_State(State_Constraint(Truth(true))))
strategy3 = to_logic(parse_tokens(tokenize("<<A>> F true"), strategy))
@test strategy3 == Exist_Eventually(Set([:A]), Strategy_to_State(State_Constraint(Truth(true))))
strategy4 = to_logic(parse_tokens(tokenize("<<A, B, C , D>> F x + y * z > 0 && loc1"), strategy))
@test strategy4 == 
    Exist_Eventually(Set([:A, :D, :B, :C]), 
        Strategy_to_State(State_And(
            State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0))), 
            State_Location(:loc1)
        )
    ))
strategy5 = to_logic(parse_tokens(tokenize("<<A, B, C , D>> F x + y * z > 0 and loc1"), strategy))
@test strategy5 == 
    Strategy_And(
        Exist_Eventually(Set([:A, :D, :B, :C]), 
            Strategy_to_State(State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0))))), 
        Strategy_to_State(State_Location(:loc1))
    )
strategy6 = to_logic(parse_tokens(tokenize("<<A, B, C , D>> F <<A, B, C , D>> F x + y * z > 0 and loc1"), strategy))
@test strategy6 == 
    Strategy_And(
        Exist_Eventually(Set([:A, :D, :B, :C]), 
            Exist_Eventually(Set([:A, :D, :B, :C]), 
                Strategy_to_State(State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0)))))), 
        Strategy_to_State(State_Location(:loc1))
    )
strategy7 = to_logic(parse_tokens(tokenize("loc1 imply <<A, B, C , D>> F <<A, B, C , D>> F x + y * z > 0"), strategy))
@test strategy7 == 
    Strategy_Imply(
        Strategy_to_State(State_Location(:loc1)), 
        Exist_Eventually(Set([:A, :D, :B, :C]), 
            Exist_Eventually(Set([:A, :D, :B, :C]), 
                Strategy_to_State(State_Constraint(Greater(Add(Var(:x), Mul(Var(:y), Var(:z))), Const(0.0))))))
    )