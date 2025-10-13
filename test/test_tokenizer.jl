using Test

include("../parsers/tokenizer.jl")

@test tokenize("") == Vector{Token}(undef, 0)

function _test_a_plus_b(input::String)
    test_tokens::Vector{Token} = tokenize(input)

    @test length(test_tokens) == 3
    @test test_tokens[1] isa CustomToken
    @test test_tokens[1].type == "a"
    @test test_tokens[2] isa ExpressionBinaryOperatorToken
    @test test_tokens[2].type == "+"
    @test test_tokens[3] isa CustomToken
    @test test_tokens[3].type == "b"
end

# test different spacing
_test_a_plus_b("a+b")
_test_a_plus_b("a + b")
_test_a_plus_b("    a+ b")
_test_a_plus_b("a +b    ")
_test_a_plus_b("a\n+\nb")

# test keyword tokenization
test_tokens::Vector{Token} = tokenize("true && deadlock")
@test length(test_tokens) == 3
@test test_tokens[1] isa BooleanToken
@test test_tokens[1].type == "true"
@test test_tokens[2] isa ConstraintBinaryOperatorToken
@test test_tokens[2].type == "&&"
@test test_tokens[3] isa StateConstantToken
@test test_tokens[3].type == "deadlock"

# test comparison tokenization
test_tokens = tokenize("10 <= c < 20")
@test length(test_tokens) == 5
@test test_tokens[1] isa NumericToken
@test test_tokens[1].type == "10"
@test test_tokens[2] isa ConstraintCompareToken
@test test_tokens[2].type == "<="
@test test_tokens[3] isa CustomToken
@test test_tokens[3].type == "c"
@test test_tokens[4] isa ConstraintCompareToken
@test test_tokens[4].type == "<"
@test test_tokens[5] isa NumericToken
@test test_tokens[5].type == "20"

# test separator tokenization
test_tokens = tokenize("<<a,b>>")
@test length(test_tokens) == 5
@test test_tokens[1] isa SeparatorToken
@test test_tokens[1].type == "<<"
@test test_tokens[2] isa CustomToken
@test test_tokens[2].type == "a"
@test test_tokens[3] isa SeparatorToken
@test test_tokens[3].type == ","
@test test_tokens[4] isa CustomToken
@test test_tokens[4].type == "b"
@test test_tokens[5] isa SeparatorToken
@test test_tokens[5].type == ">>"

test_tokens = tokenize("))")
@test length(test_tokens) == 2
@test test_tokens[1] isa SeparatorToken
@test test_tokens[1].type == ")"
@test test_tokens[2] isa SeparatorToken
@test test_tokens[2].type == ")"

# test numeric tokenization
@test tokenize("10") == [NumericToken("10")]
@test tokenize("10.0") == [NumericToken("10.0")]
@test tokenize("10.01") == [NumericToken("10.01")]

# test error handling
@test_throws TokenizeError("10. is an invalid number.") tokenize("10.")
@test_throws TokenizeError("+- is an invalid sequence of symbols.") tokenize("a+-b")
@test_throws TokenizeError("' is an invalid starting symbol.") tokenize("a'b")
@test_throws TokenizeError("_ is an invalid starting symbol.") tokenize("a && _b")
