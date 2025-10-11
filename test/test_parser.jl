using Test

include("../parsers/parser.jl")

# Test expressions

ast::ASTNode = parse_tokens(Vector{Token}(tokenize("a+b")))
@test ast == ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b"))

ast = parse_tokens(Vector{Token}(tokenize("a+b-c")))
@test ast == ExpressionBinaryOperation("-", ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b")), VariableNode("c"))

ast = parse_tokens(Vector{Token}(tokenize("a*sin(b)")))
@test ast == ExpressionBinaryOperation("*", VariableNode("a"), ExpressionUnaryOperation("sin", VariableNode("b")))

ast = parse_tokens(Vector{Token}(tokenize("cot(0)/10")))
@test ast == ExpressionBinaryOperation("/", ExpressionUnaryOperation("cot", ExpressionConstant(0.0)), ExpressionConstant(10.0))

# Test constraints

ast = parse_tokens(Vector{Token}(tokenize("x < y + 10")))
@test ast == ConstraintBinaryOperation("<", VariableNode("x"), ExpressionBinaryOperation("+", VariableNode("y"), ExpressionConstant(10.0)))

ast = parse_tokens(Vector{Token}(tokenize("true && x < y")))
@test ast == ConstraintBinaryOperation("&&", ConstraintConstant(true), ConstraintBinaryOperation("<", VariableNode("x"), VariableNode("y")))

ast = parse_tokens(Vector{Token}(tokenize("x < 10 && false")))
@test ast == ConstraintBinaryOperation("&&", ConstraintBinaryOperation("<", VariableNode("x"), ExpressionConstant(10.0)), ConstraintConstant(false))

# Test strategies

ast = parse_tokens(Vector{Token}(tokenize("<<a,b>> F true")))
@test ast == Quantifier(false, false, AgentList(false, VariableList([VariableNode("a"), VariableNode("b")])), ConstraintConstant(true))

ast = parse_tokens(Vector{Token}(tokenize("<< >> F x>5 and y<10")))
@test ast == StrategyBinaryOperation(
    "and",
    Quantifier(
        false, false, AgentList(false, VariableList([])),
        ConstraintBinaryOperation(">", VariableNode("x"), ExpressionConstant(5.0))
    ),
    ConstraintBinaryOperation("<", VariableNode("y"), ExpressionConstant(10.0))
)

ast = parse_tokens(Vector{Token}(tokenize("<< >> F x>5 && y<10")))
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

ast = parse_tokens(Vector{Token}(tokenize("not << >> F true")))
@test ast == StrategyUnaryOperation("not", parse_tokens(Vector{Token}(tokenize("<< >> F true"))))

ast = parse_tokens(Vector{Token}(tokenize("a and b")))
@test ast == StrategyBinaryOperation("and", LocationNode("a"), LocationNode("b"))

# Test error handling

@test_throws ParseError parse_tokens(Vector{Token}(tokenize("not")))
@test_throws ParseError parse_tokens(Vector{Token}(tokenize("14 && true")))
@test_throws ParseError parse_tokens(Vector{Token}(tokenize("<<a, >> F true")))
