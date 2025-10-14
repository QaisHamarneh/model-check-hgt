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

ast = parse_tokens(tokenize("a+b-c"))
@test ast == ExpressionBinaryOperation("-", ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b")), VariableNode("c"))

ast = parse_tokens(tokenize("a*sin(b)"))
@test ast == ExpressionBinaryOperation("*", VariableNode("a"), ExpressionUnaryOperation("sin", VariableNode("b")))

ast = parse_tokens(tokenize("cot(0)/10"))
@test ast == ExpressionBinaryOperation("/", ExpressionUnaryOperation("cot", ExpressionConstant(0.0)), ExpressionConstant(10.0))
@test ast == parse_tokens(tokenize("(cot(((0)))/(10))"))

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

ast = parse_tokens(tokenize("p and q"))
@test ast == StrategyBinaryOperation("and", LocationNode("p"), LocationNode("q"))

# Test error handling

@test_throws ParseError parse_tokens(tokenize("not"))
@test_throws ParseError parse_tokens(tokenize("14 && true"))
@test_throws ParseError parse_tokens(tokenize("<<a, >> F true"))
