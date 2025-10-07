using Test

include("../parsers/parser.jl")

ast::Vector{Union{Token, ExpressionNode}} = _parse_expressions(Vector{Union{Token, ExpressionNode}}(tokenize("a+b")))
@test length(ast) == 1
@test ast[1] == ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b"))

ast = _parse_expressions(Vector{Union{Token, ExpressionNode}}(tokenize("a+b-c")))
@test length(ast) == 1
@test ast[1] == ExpressionBinaryOperation("-", ExpressionBinaryOperation("+", VariableNode("a"), VariableNode("b")), VariableNode("c"))

ast = _parse_expressions(Vector{Union{Token, ExpressionNode}}(tokenize("a*sin(b)")))
@test length(ast) == 1
@test ast[1] == ExpressionBinaryOperation("*", VariableNode("a"), ExpressionUnaryOperation("sin", VariableNode("b")))

ast = _parse_expressions(Vector{Union{Token, ExpressionNode}}(tokenize("cot(0)/10")))
@test length(ast) == 1
@test ast[1] == ExpressionBinaryOperation("/", ExpressionUnaryOperation("cot", ExpressionConstant(0.0)), ExpressionConstant(10.0))
