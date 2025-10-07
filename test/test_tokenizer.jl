using Test

include("../parsers/tokenizer.jl")

@test tokenize("") == Vector{Token}(undef, 0)

function test_a_plus_b(input::String)
    test_tokens::Vector{Token} = tokenize(input)

    @test length(test_tokens) == 3
    @test test_tokens[1] isa CustomToken
    @test test_tokens[1].type == "a"
    @test test_tokens[2] isa ExpressionBinaryOperatorToken
    @test test_tokens[2].type == "+"
    @test test_tokens[3] isa CustomToken
    @test test_tokens[3].type == "b"
end

test_a_plus_b("a+b")
test_a_plus_b("a + b")
test_a_plus_b("    a+ b")
test_a_plus_b("a +b    ")
test_a_plus_b("a\n+\nb")

test_tokens::Vector{Token} = tokenize("True && False")

@test length(test_tokens) == 3
@test test_tokens[1] isa ConstraintConstantToken
@test test_tokens[1].type == "True"
@test test_tokens[2] isa ConstraintBinaryOperatorToken
@test test_tokens[2].type == "&&"
@test test_tokens[3] isa ConstraintConstantToken
@test test_tokens[3].type == "False"

test_tokens = tokenize("10 <= c < 20")
@test length(test_tokens) == 5
@test test_tokens[1] isa NumericToken
@test test_tokens[1].type == "10"
@test test_tokens[2] isa ConstraintBinaryOperatorToken
@test test_tokens[2].type == "<="
@test test_tokens[3] isa CustomToken
@test test_tokens[3].type == "c"
@test test_tokens[4] isa ConstraintBinaryOperatorToken
@test test_tokens[4].type == "<"
@test test_tokens[5] isa NumericToken
@test test_tokens[5].type == "20"

@test_throws ArgumentError tokenize("a+-b")
@test_throws ArgumentError tokenize("a?b")
