using Test

include("../parsers/parser.jl")

# Test expressions

ast::ASTNode = parse_tokens(tokenize("a+b"))
@test ast == ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b"))
@test ast == parse_tokens(tokenize("(a+b)"))
@test ast == parse_tokens(tokenize("((a)+b)"))
@test ast == parse_tokens(tokenize("(a+(b))"))
@test ast == parse_tokens(tokenize("((a)+(b))"))
@test ast == parse_tokens(tokenize("(a)+(b)"))
@test_throws ParseError parse_tokens(tokenize("a(+)b"))
@test_throws ParseError parse_tokens(tokenize("a()+b"))
@test_throws ParseError parse_tokens(tokenize("a+b)"))

ast = parse_tokens(tokenize("-a"))
@test ast == ExpressionUnaryOperation("-", VariableNode("a"))
@test ast == parse_tokens(tokenize("-(a)"))
@test ast == parse_tokens(tokenize("(-(a))"))
@test_throws ParseError parse_tokens(tokenize("(-)(a)"))

ast = parse_tokens(tokenize("b+(-a)"))
@test ast == ExpressionBinaryOperation("+", VariableNode("b"), ExpressionUnaryOperation("-", VariableNode("a")))
@test ast == parse_tokens(tokenize("b+ -a"))
@test ast == parse_tokens(tokenize("(b+(-a))"))
@test_throws TokenizeError parse_tokens(tokenize("a+-b"))

ast = parse_tokens(tokenize("a+b-c"))
@test ast == ExpressionBinaryOperation("-", ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b")), VariableNode("c"))

ast = parse_tokens(tokenize("a*sin(b)"))
@test ast == ExpressionBinaryOperation("*", VariableNode("a"), ExpressionUnaryOperation("sin", VariableNode("b")))

ast = parse_tokens(tokenize("cot(0)/10"))
@test ast == ExpressionBinaryOperation("/", ExpressionUnaryOperation("cot", ExpressionConstant(0.0)), ExpressionConstant(10.0))
@test ast == parse_tokens(tokenize("(cot(((0)))/(10))"))

ast = ast = parse_tokens(tokenize("x + y * z"))
@test ast == ExpressionBinaryOperation("+", VariableNode("x"), ExpressionBinaryOperation("*", VariableNode("y"), VariableNode("z")))
@test ast == parse_tokens(tokenize("x + (y * z)"))
@test ast == parse_tokens(tokenize("x + (y) * z"))

ast = ast = parse_tokens(tokenize("x - y * z"))
@test ast == ExpressionBinaryOperation("-", VariableNode("x"), ExpressionBinaryOperation("*", VariableNode("y"), VariableNode("z")))
@test ast == parse_tokens(tokenize("x - (y * z)"))
@test ast == parse_tokens(tokenize("x - (y) * z"))

ast = ast = parse_tokens(tokenize("x * y - z"))
@test ast == ExpressionBinaryOperation("-", ExpressionBinaryOperation("*", VariableNode("x"), VariableNode("y")), VariableNode("z"))
@test ast == parse_tokens(tokenize("(x * y) - z"))
@test ast == parse_tokens(tokenize("x * y - (z)"))

ast = ast = parse_tokens(tokenize("-y * z"))
@test ast == ExpressionBinaryOperation("*", ExpressionUnaryOperation("-", VariableNode("y")), VariableNode("z"))
@test ast == parse_tokens(tokenize("-(y) * z"))
@test ast != parse_tokens(tokenize("-(y * z)"))

ast = ast = parse_tokens(tokenize("x ^ y - z * 10"))
@test ast == ExpressionBinaryOperation(
    "-",
    ExpressionBinaryOperation("^", VariableNode("x"), VariableNode("y")),
    ExpressionBinaryOperation("*", VariableNode("z"), ExpressionConstant(10.0))
)

# Test constraints

ast = parse_tokens(tokenize("x < y + 10"))
@test ast == ConstraintBinaryOperation("<", VariableNode("x"), ExpressionBinaryOperation("+", VariableNode("y"), ExpressionConstant(10.0)))
@test ast == parse_tokens(tokenize("x < (y + 10)"))
@test ast == parse_tokens(tokenize("(x < (y + 10))"))
@test ast == parse_tokens(tokenize("(x) < (y + 10)"))
@test ast == parse_tokens(tokenize("((x) < (y + 10))"))
@test_throws ParseError parse_tokens(tokenize("(x < y) + 10"))

ast = parse_tokens(tokenize("true && x < y"))
@test ast == ConstraintBinaryOperation("&&", ConstraintConstant(true), ConstraintBinaryOperation("<", VariableNode("x"), VariableNode("y")))
@test ast == parse_tokens(tokenize("(true) && (x < y)"))
@test_throws ParseError parse_tokens(tokenize("(true && x) < y"))

ast = parse_tokens(tokenize("x < 10 && false"))
@test ast == ConstraintBinaryOperation("&&", ConstraintBinaryOperation("<", VariableNode("x"), ExpressionConstant(10.0)), ConstraintConstant(false))

ast = parse_tokens(tokenize("true || false && false"))
@test ast == ConstraintBinaryOperation("||", ConstraintConstant(true), ConstraintBinaryOperation("&&", ConstraintConstant(false), ConstraintConstant(false)))

# Test states

ast = parse_tokens(tokenize("true && var"))
@test ast == StateBinaryOperation("&&", ConstraintConstant(true), LocationNode("var"))

ast = parse_tokens(tokenize("true || false || loc1 && loc2"))
@test ast == StateBinaryOperation(
    "||",
    ConstraintBinaryOperation("||", ConstraintConstant(true), ConstraintConstant(false)),
    StateBinaryOperation("&&", LocationNode("loc1"), LocationNode("loc2"))
)

# Test strategies

ast = parse_tokens(tokenize("<<a,b>> F true"))
@test ast == Quantifier(false, false, AgentList(false, VariableList([VariableNode("a"), VariableNode("b")])), ConstraintConstant(true))
@test ast == parse_tokens(tokenize("(<<a,b>> F (true))"))
@test_throws ParseError parse_tokens(tokenize("<<(a,b)>> F true"))
@test_throws ParseError parse_tokens(tokenize("<<(a),(b)>> F true"))

ast = parse_tokens(tokenize("<< >> F x>5 and y<10"))
@test ast == StrategyBinaryOperation(
    "and",
    Quantifier(
        false, false, AgentList(false, VariableList([])),
        ConstraintBinaryOperation(">", VariableNode("x"), ExpressionConstant(5.0))
    ),
    ConstraintBinaryOperation("<", VariableNode("y"), ExpressionConstant(10.0))
)
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
@test ast == parse_tokens(tokenize("(<< >> F (x>5 && y<10))"))
@test ast == parse_tokens(tokenize("(<<>> F (x>5 && y<10))"))

ast = parse_tokens(tokenize("not << >> F true"))
@test ast == StrategyUnaryOperation("not", parse_tokens((tokenize("<< >> F true"))))
@test ast == parse_tokens(tokenize("(not (<< >> F (true)))"))

ast = parse_tokens(tokenize("p or q and w"))
@test ast == StrategyBinaryOperation("or", LocationNode("p"), StrategyBinaryOperation("and", LocationNode("q"), LocationNode("w")))

# Test error handling

@test_throws ParseError parse_tokens(tokenize("not"))
@test_throws ParseError parse_tokens(tokenize("14 && true"))
@test_throws ParseError parse_tokens(tokenize("<<a, >> F true"))
