using Test

include("../parsers/parser.jl")

# Test expressions

ast::ASTNode = parse_tokens(tokenize("a+b"))
@test ast == ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b"))
@test to_string(ast) == "(a)+(b)"
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
@test ast == parse_tokens(tokenize("-(a)"), expression)
@test ast == parse_tokens(tokenize("(-(a))"), constraint)
@test_throws ParseError("Cannot parse tokens between '(' and '-'.") parse_tokens(tokenize("(-)(a)"))

ast = parse_tokens(tokenize("b+(-a)"))
@test ast == ExpressionBinaryOperation("+", VariableNode("b"), ExpressionUnaryOperation("-", VariableNode("a")))
@test to_string(ast) == "(b)+(-(a))"
@test ast == parse_tokens(tokenize("b+ -a"), expression)
@test ast == parse_tokens(tokenize("(b+(-a))"), constraint)
@test_throws TokenizeError("+- is an invalid sequence of symbols.") parse_tokens(tokenize("a+-b"))

ast = parse_tokens(tokenize("a+b-c"))
@test to_string(ast) == "((a)+(b))-(c)"
@test ast == ExpressionBinaryOperation("-", ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b")), VariableNode("c"))

ast = parse_tokens(tokenize("a*sin(b)"))
@test ast == ExpressionBinaryOperation("*", VariableNode("a"), ExpressionUnaryOperation("sin", VariableNode("b")))
@test to_string(ast) == "(a)*(sin(b))"

ast = parse_tokens(tokenize("cot(0)/10"))
@test ast == ExpressionBinaryOperation("/", ExpressionUnaryOperation("cot", ExpressionConstant(0.0)), ExpressionConstant(10.0))
@test to_string(ast) == "(cot(0.0))/(10.0)"
@test ast == parse_tokens(tokenize("(cot(((0)))/(10))"), expression)

ast = ast = parse_tokens(tokenize("x + y * z"))
@test ast == ExpressionBinaryOperation("+", VariableNode("x"), ExpressionBinaryOperation("*", VariableNode("y"), VariableNode("z")))
@test to_string(ast) == "(x)+((y)*(z))"
@test ast == parse_tokens(tokenize("x + (y * z)"), expression)
@test ast == parse_tokens(tokenize("x + (y) * z"), constraint)

ast = ast = parse_tokens(tokenize("x - y * z"))
@test ast == ExpressionBinaryOperation("-", VariableNode("x"), ExpressionBinaryOperation("*", VariableNode("y"), VariableNode("z")))
@test to_string(ast) == "(x)-((y)*(z))"
@test ast == parse_tokens(tokenize("x - (y * z)"), expression)
@test ast == parse_tokens(tokenize("x - (y) * z"), constraint)

ast = ast = parse_tokens(tokenize("x * y - z"))
@test ast == ExpressionBinaryOperation("-", ExpressionBinaryOperation("*", VariableNode("x"), VariableNode("y")), VariableNode("z"))
@test to_string(ast) == "((x)*(y))-(z)"
@test ast == parse_tokens(tokenize("(x * y) - z"), expression)
@test ast == parse_tokens(tokenize("x * y - (z)"), constraint)

ast = ast = parse_tokens(tokenize("-y * z"))
@test ast == ExpressionBinaryOperation("*", ExpressionUnaryOperation("-", VariableNode("y")), VariableNode("z"))
@test to_string(ast) == "(-(y))*(z)"
@test ast == parse_tokens(tokenize("-(y) * z"), expression)
@test ast != parse_tokens(tokenize("-(y * z)"), constraint)

ast = ast = parse_tokens(tokenize("x ^ y - z * 10"))
@test ast == ExpressionBinaryOperation(
    "-",
    ExpressionBinaryOperation("^", VariableNode("x"), VariableNode("y")),
    ExpressionBinaryOperation("*", VariableNode("z"), ExpressionConstant(10.0))
)
@test to_string(ast) == "((x)^(y))-((z)*(10.0))"

# Test constraints

ast = parse_tokens(tokenize("x < y + 10"))
@test ast == ConstraintBinaryOperation("<", VariableNode("x"), ExpressionBinaryOperation("+", VariableNode("y"), ExpressionConstant(10.0)))
@test to_string(ast) == "(x)<((y)+(10.0))"
@test ast == parse_tokens(tokenize("x < (y + 10)"), constraint)
@test ast == parse_tokens(tokenize("(x < (y + 10))"), state)
@test ast == parse_tokens(tokenize("(x) < (y + 10)"))
@test ast == parse_tokens(tokenize("((x) < (y + 10))"))
@test_throws ParseError("Cannot parse tokens between '(x)<(y)' and '+'.") parse_tokens(tokenize("(x < y) + 10"))

ast = parse_tokens(tokenize("true && x < y"))
@test ast == ConstraintBinaryOperation("&&", ConstraintConstant(true), ConstraintBinaryOperation("<", VariableNode("x"), VariableNode("y")))
@test to_string(ast) == "(true)&&((x)<(y))"
@test ast == parse_tokens(tokenize("(true) && (x < y)"), constraint)
@test_throws ParseError("Cannot parse tokens between '(true)&&(x)' and '<'.") parse_tokens(tokenize("(true && x) < y"))

ast = parse_tokens(tokenize("x < 10 && false"))
@test ast == ConstraintBinaryOperation("&&", ConstraintBinaryOperation("<", VariableNode("x"), ExpressionConstant(10.0)), ConstraintConstant(false))
@test to_string(ast) == "((x)<(10.0))&&(false)"

ast = parse_tokens(tokenize("true || false && false"))
@test ast == ConstraintBinaryOperation("||", ConstraintConstant(true), ConstraintBinaryOperation("&&", ConstraintConstant(false), ConstraintConstant(false)))
@test to_string(ast) == "(true)||((false)&&(false))"

# Test states

ast = parse_tokens(tokenize("true && var"))
@test ast == StateBinaryOperation("&&", ConstraintConstant(true), LocationNode("var"))
@test to_string(ast) == "(true)&&(var)"

ast = parse_tokens(tokenize("true || false || loc1 && loc2"))
@test ast == StateBinaryOperation(
    "||",
    ConstraintBinaryOperation("||", ConstraintConstant(true), ConstraintConstant(false)),
    StateBinaryOperation("&&", LocationNode("loc1"), LocationNode("loc2"))
)
@test to_string(ast) == "((true)||(false))||((loc1)&&(loc2))"

# Test strategies

ast = parse_tokens(tokenize("<<a,b>> F true"))
@test ast == Quantifier(false, false, AgentList(false, VariableList([VariableNode("a"), VariableNode("b")])), ConstraintConstant(true))
@test to_string(ast) == "<<a,b>>F(true)"
@test ast == parse_tokens(tokenize("(<<a,b>> F (true))"), strategy)
@test_throws ParseError("Cannot parse tokens between '<<' and '('.") parse_tokens(tokenize("<<(a,b)>> F true"))
@test_throws ParseError("Cannot parse tokens between '<<' and 'a'.") parse_tokens(tokenize("<<(a),(b)>> F true"))

ast = parse_tokens(tokenize("<< >> F x>5 and y<10"))
@test ast == StrategyBinaryOperation(
    "and",
    Quantifier(
        false, false, AgentList(false, VariableList([])),
        ConstraintBinaryOperation(">", VariableNode("x"), ExpressionConstant(5.0))
    ),
    ConstraintBinaryOperation("<", VariableNode("y"), ExpressionConstant(10.0))
)
@test to_string(ast) == "(<<>>F((x)>(5.0)))and((y)<(10.0))"
@test ast == parse_tokens(tokenize("((<< >> F x>5) and (y<10))"))
@test ast == parse_tokens(tokenize("((<<>> F x>5) and (y<10))"))

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
