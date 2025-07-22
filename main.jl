# using Ranges   # Remove this line
include("parsers/parse_game.jl")
include("game_semantics/game_tree.jl")
include("packages.jl")
using DataStructures


function run_discrete_test()
    t1 = time();
    

    
    bouncing_ball::Game = parse_game("examples/simple_game.json")

    game_tree::Node = build_game_tree(bouncing_ball, max_time=10.0, max_steps=3)

    t2 = time();

    # println("*************************")
    # println("Nodes = ", count_nodes(game_tree))
    # println("Time = $(t2 - t1)")
    println("*************************")
    # println("Game tree path [0]:")
    # println(game_tree.config)
    # while !isempty(game_tree.children)
    #     game_tree = game_tree.children[1]
    #     println(game_tree.config)
    # end
end



run_discrete_test()