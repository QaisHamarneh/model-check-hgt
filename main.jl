# using Ranges   # Remove this line
include("game_semantics/game_tree.jl")
include("parsers/parse_constraint.jl")
include("packages.jl")


function run_discrete_test()
    t1 = time();
    variables = ["x", "y"]
    initial_valuation::Dict{String, Real} = Dict("x" => 0, "y" => 0)

    # function flow1!(du, u, p, t)
    #     x, y = u
    #     du[1] = y      # pos' = spd
    #     du[2] = 2.0      # spd' = constant acceleration 5
    # end
    # function flow2!(du, u, p, t)
    #     x, y = u
    #     du[1] = 2.0      # pos' = spd
    #     du[2] = x      # spd' = constant acceleration 5
    # end

    flow1 = Dict("x" => parse_expression("x"), "y" => parse_expression("y + 1"))
    flow2 = Dict("x" => parse_expression("x - 1"), "y" => parse_expression("y + 2"))

    invariant1 = parse_constraint("x < 4000") 
    invariant2 = parse_constraint("x < 4000")
    invariant3 = parse_constraint("x < 4000 && y < 4000")

    guard1 = parse_constraint("x < 4000")
    guard2 = parse_constraint("x < 4000")

    l1 = Location("l1", invariant1, flow1)
    l2 = Location("l2", invariant2, flow2)
    l3 = Location("l3", invariant3, flow1)
    # l1 = Location("l1", invariant1, Dict("x" => 1, "y" => 1))
    # l2 = Location("l2", invariant2, Dict("x" => 1, "y" => 1))
    # l3 = Location("l3", invariant3, Dict("x" => 1, "y" => 1))

    one_agent::Vector{String} = ["1"] 

    actions::Vector{String} = ["a", "b"]

    e1 = Edge("e1", l1, l2, guard1, Dict(1 => "a"), Dict("x" => parse_expression("x + 1")))
    e2 = Edge("e2", l2, l1, guard2, Dict(1 => "b"), Dict("y" => parse_expression("y + 1")))



    two_agents::Vector{String} = ["1", "2"]

    e12 = Edge("e12", l1, l2, guard1, Dict(1 => "a", 2 => "a"), Dict("x" => parse_expression("x + 1")))
    e13 = Edge("e13", l1, l3, guard2, Dict(1 => "b", 2 => "a"), Dict("y" => parse_expression("y + 1")))

    e21 = Edge("e21", l2, l1, guard1, Dict(2 => "a", 1 => "a"), Dict("x" => parse_expression("x + 1")))
    e23 = Edge("e23", l2, l3, guard2, Dict(2 => "b", 1 => "a"), Dict("y" => parse_expression("y + 1")))

    e31 = Edge("e31", l3, l1, guard1, Dict(1 => "a", 2 => "b"), Dict("x" => parse_expression("x + 1")))
    e32 = Edge("e32", l3, l2, guard2, Dict(1 => "b", 2 => "b"), Dict("y" => parse_expression("y + 1")))



    small_game = Game([l1, l2], l1, variables, initial_valuation, one_agent, actions, [e1, e2], true)

    big_game = Game([l1, l2, l3], l1, variables, initial_valuation, two_agents, actions, [e12, e13, e21, e23, e31, e32], true)
    game_tree = build_game_tree(small_game, 10.0)

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