# using Ranges   # Remove this line
include("game_semantics/game_tree.jl")
include("parsers/parse_constraint.jl")
include("packages.jl")
using DataStructures


function run_discrete_test()
    t1 = time();
    variables = [:x, :y]
    initial_valuation::OrderedDict{Symbol, Float64} = OrderedDict(:x => 1, :y => 1)

    flow1::Dict{Symbol, ExprLike} = OrderedDict(:x => parse_expression("x"), :y => parse_expression("y"))
    flow2::Dict{Symbol, ExprLike} = OrderedDict(:x => parse_expression("x"), :y => parse_expression("y"))

    invariant1::Constraint = parse_constraint("x < 4000") 
    invariant2::Constraint = parse_constraint("x < 4000")
    invariant3::Constraint = parse_constraint("x < 4000 && y < 4000")

    guard1::Constraint = parse_constraint("x < 4000")
    guard2::Constraint = parse_constraint("x < 4000")

    l1::Location = Location(:l1, invariant1, flow1)
    l2::Location = Location(:l2, invariant2, flow2)

    l11::Location = Location(:l1, invariant1, flow1)
    l12::Location = Location(:l2, invariant2, flow2)
    l13::Location = Location(:l3, invariant3, flow1)

    actions::Vector{Symbol} = [:a, :b]


    one_agent::Vector{Symbol} = [:α] 

    e1::Edge = Edge(:e1, l1, l2, guard1, Dict(:α => :a), Dict(:x => parse_expression("x + 1")))
    e2::Edge = Edge(:e2, l2, l1, guard2, Dict(:α => :b), Dict(:y => parse_expression("y + 1")))



    two_agents::Vector{Symbol} = [:α, :β]

    e12::Edge = Edge(:e12, l11, l12, guard1, Dict(:α => :a, :β => :a), OrderedDict(:x => parse_expression("x + 1")))
    e13::Edge = Edge(:e13, l11, l13, guard2, Dict(:α => :b, :β => :a), OrderedDict(:y => parse_expression("y + 1")))

    e21::Edge = Edge(:e21, l12, l11, guard1, Dict(:α => :a, :β => :a), OrderedDict(:x => parse_expression("x + 1")))
    e23::Edge = Edge(:e23, l12, l13, guard2, Dict(:β => :b, :α => :a), OrderedDict(:y => parse_expression("y + 1")))

    e31::Edge = Edge(:e31, l13, l11, guard1, Dict(:α => :a, :β => :b), OrderedDict(:x => parse_expression("x + 1")))
    e32::Edge = Edge(:e32, l13, l12, guard2, Dict(:α => :b, :β => :b), OrderedDict(:y => parse_expression("y + 1")))



    small_game::Game = Game("Small Game", [l1, l2], l1, initial_valuation, one_agent, actions, [e1, e2])

    big_game::Game = Game("Big Game", [l11, l12, l13], l11, initial_valuation, two_agents, actions, [e12, e13, e21, e23, e31, e32])

    game_tree::Node = build_game_tree(big_game, max_time=10.0, max_steps=3)

    t2 = time();

    println("*************************")
    println("Nodes = ", count_nodes(game_tree))
    println("Time = $(t2 - t1)")
    println("*************************")
    # println("Game tree path [0]:")
    # println(game_tree.config)
    # while !isempty(game_tree.children)
    #     game_tree = game_tree.children[1]
    #     println(game_tree.config)
    # end
end



run_discrete_test()