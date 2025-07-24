# using Ranges   # Remove this line
include("parsers/parse_game.jl")
include("game_semantics/triggers_turn_based_game_tree.jl")
include("packages.jl")
using DataStructures


function run_discrete_test()
    t1 = time();
    
    # bouncing_ball, max_time, max_steps = parse_game("examples/warehouse_robots_2_streets.json")
    bouncing_ball, max_time, max_steps = parse_game("examples/4_locations_game.json")

    t2 = time();

    game_tree::Node = build__triggers_game_tree(bouncing_ball, max_time=max_time, max_steps=max_steps)

    t3 = time();

    count = count_nodes(game_tree)

    t4 = time();

    println("*************************")
    println("Nodes = ", count)
    println("Time to parse = $(t2 - t1)")
    println("Time to build = $(t3 - t2)")
    println("Time to count = $(t4 - t3)")
    println("*************************")
    # println("Game tree path [0]:")
    # println(game_tree.config)
    # while !isempty(game_tree.children)
    #     game_tree = game_tree.children[1]
    #     println(game_tree.config)
    # end
end



run_discrete_test()