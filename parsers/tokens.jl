"""
    Tokens

This file contains all token definitions needed to convert a string into an array of tokens.

# Types:
- `Token`: abstract type for all tokens
- `KeywordToken`: abstract type for all keywords
- `OperatorToken`: abstract type for all operators
- `SeparatorToken`: token for all valid separators
- `CustomToken`: token for all user defined variables
- `NumericToken`: token for all numeric values
- `BooleanToken`: token for all boolean values
- `QuantifierToken`: token for quantifier keywords
- `StrategyUnaryOperatorToken`: token for unary operations on strategies
- `StrategyBinaryOperatorToken`: token for binary operations on strategies
- `StateUnaryOperatorToken`: token for unary operations on states
- `StateBinaryOperatorToken`: token for binary operations on states
- `ConstraintUnaryOperatorToken`: token for unary operations on constraints
- `ConstraintBinaryOperatorToken`: token for binary operations on constraints
- `ConstraintCompareToken`: token for comparison operators
- `ExpressionUnaryOperatorToken`: token for unary operations on expression
- `ExpressionBinaryOperatorToken`: token for binary operations on expression

The types are hierarchically ordered as follows:
    Token
    |-- SeparatorToken
    |-- CustomToken
    |-- NumericToken
    |-- KeywordToken
    |   |-- BooleanToken
    |   |-- QuantifierToken
    |-- OperatorToken
        |-- ...UnaryOperatorToken
        |-- ...BinaryOperatorToken
        |-- ConstraintCompareToken
"""

# abstract types for all tokens
abstract type Token
end

abstract type KeywordToken <: Token
end

abstract type OperatorToken <: Token
end

"""
    SeparatorToken <: Token

A token for all valid separators.

    SeparatorToken(type::String)

Create a SeparatorToken of type `type`.
"""
struct SeparatorToken <: Token
    type::String
end

"""
    EmptyListToken <: Token

A token for empty lists.

    EmptyListToken(type::String)

Create a EmptyListToken of type `type`.
"""
struct EmptyListToken <: Token
    type::String
end


"""
    CustomToken <: Token

A token for all user defined variables.

    CustomToken(type::String)

Create a CustomToken of type `type`.
"""
struct CustomToken <: Token
    type::String
end

"""
    NumericToken <: Token

A token for all numeric values.

    NumericToken(type::String)

Create a NumericToken of type `type`.
"""
struct NumericToken <: Token
    type::String
end

"""
    BooleanToken <: KeywordToken

A token for boolean constants.

    BooleanToken(type::String)

Create a BooleanToken of type `type`.
"""
struct BooleanToken <: KeywordToken
    type::String
end

"""
    StateConstantToken <: KeywordToken

A token for state constants like `deadlock`.

    StateConstantToken(type::String)

Create a StateConstantToken of type `type`.
"""
struct StateConstantToken <: KeywordToken
    type::String
end

"""
    QuantifierToken <: KeywordToken

A token for quantifier keywords.

    QuantifierToken(type::String)

Create a QuantifierToken of type `type`.
"""
struct QuantifierToken <: KeywordToken
    type::String
end

"""
    StrategyUnaryOperatorToken <: OperatorToken

A token for unary operators on strategies.

    StrategyUnaryOperatorToken(type::String)

Create a StrategyUnaryOperatorToken of type `type`.
"""
struct StrategyUnaryOperatorToken <: OperatorToken
    type::String
end

"""
    StrategyBinaryOperatorToken <: OperatorToken

A token for binary operators on strategies.

    StrategyBinaryOperatorToken(type::String)

Create a StrategyBinaryOperatorToken of type `type`.
"""
struct StrategyBinaryOperatorToken <: OperatorToken
    type::String
end

"""
    StateUnaryOperatorToken <: OperatorToken

A token for unary operators on states.

    StateUnaryOperatorToken(type::String)

Create a StateUnaryOperatorToken of type `type`.
"""
struct StateUnaryOperatorToken <: OperatorToken
    type::String
end

"""
    StateBinaryOperatorToken <: OperatorToken

A token for unary operators on states.

    StateBinaryOperatorToken(type::String)

Create a StateBinaryOperatorToken of type `type`.
"""
struct StateBinaryOperatorToken <: OperatorToken
    type::String
end

"""
    ConstraintUnaryOperatorToken <: OperatorToken

A token for unary operators on constraints.

    ConstraintUnaryOperatorToken(type::String)

Create a ConstraintUnaryOperatorToken of type `type`.
"""
struct ConstraintUnaryOperatorToken <: OperatorToken
    type::String
end

"""
    ConstraintBinaryOperatorToken <: OperatorToken

A token for binary operators on constraints.

    ConstraintBinaryOperatorToken(type::String)

Create a ConstraintBinaryOperatorToken of type `type`.
"""
struct ConstraintBinaryOperatorToken <: OperatorToken
    type::String
end

"""
    ConstraintCompareToken <: OperatorToken

A token for comparing expressions.

    ConstraintCompareToken(type::String)

Create a ConstraintCompareToken of type `type`.
"""
struct ConstraintCompareToken <: OperatorToken
    type::String
end

"""
    ExpressionUnaryOperatorToken <: OperatorToken

A token for unary operators on expressions.

    ExpressionUnaryOperatorToken(type::String)

Create a ExpressionUnaryOperatorToken of type `type`.
"""
struct ExpressionUnaryOperatorToken <: OperatorToken
    type::String
end

"""
    ExpressionBinaryOperatorToken <: OperatorToken

A token for binary operators on expressions.

    ExpressionBinaryOperatorToken(type::String)

Create a ExpressionBinaryOperatorToken of type `type`.
"""
struct ExpressionBinaryOperatorToken <: OperatorToken
    type::String
end
