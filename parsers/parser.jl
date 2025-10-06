abstract type ASTNode
end

abstract type StrategyNode <: ASTNode
end

struct AgentList <: StrategyNode
    agents::Set{StringVariable}
end

struct Quantifier <: StrategyNode
    for_all::Bool
    always::Bool
    agent_list::AgentList
    child::ASTNode
end

abstract type StateNode <: ASTNode
end

abstract type ConstraintNode <: StateNode
end

struct ConstraintConstant <: ConstraintNode
    value::Bool
end

abstract type ExpressionNode <: StateNode
end

struct ExpressionConstant <: ExpressionNode
    value::float
end
