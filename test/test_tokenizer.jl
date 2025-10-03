using Test

include("../parsers/tokenizer.jl")

function test_a_plus_b(input::String)
    test_tokens::Vector{Token} = tokenize(input)

    @test length(test_tokens) == 3
    @test test_tokens[1] isa CustomToken
    @test test_tokens[1].type == "a"
    @test test_tokens[2] isa OperatorToken
    @test test_tokens[2].type == "+"
    @test test_tokens[3] isa CustomToken
    @test test_tokens[3].type == "b"
end

test_a_plus_b("a+b")
test_a_plus_b("a + b")
test_a_plus_b("    a+ b")
test_a_plus_b("a +b    ")

test_tokens::Vector{Token} = tokenize("True && False")

@test length(test_tokens) == 3
@test test_tokens[1] isa KeywordToken
@test test_tokens[1].type == "True"
@test test_tokens[2] isa OperatorToken
@test test_tokens[2].type == "&&"
@test test_tokens[3] isa KeywordToken
@test test_tokens[3].type == "False"
