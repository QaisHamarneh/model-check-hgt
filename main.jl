# using Ranges   # Remove this line
include("packages.jl")
include("parsers/parse_game.jl")
include("game_semantics/triggers_turn_based_game_tree.jl")
using DataStructures


t1 = time();

# bouncing_ball, max_time, max_steps = parse_game("examples/warehouse_robots_2_streets.json")
# game, max_time, max_steps = parse_game("examples/simple_game.json")

# game, max_time, max_steps = parse_game("examples/3_players_1_ball.json")

game, max_time, max_steps = parse_game("examples/player_in_middle.json")
t2 = time();


game_tree::Node = build_triggers_game_tree(game, max_time=max_time, max_steps=max_steps)
# game_tree::Node = build_triggers_game_tree_iterative(game, max_time=max_time, max_steps=max_steps)
t3 = time();

count = count_nodes(game_tree)
depth = depth_of_tree(game_tree)

t4 = time();

println("*************************")
println("Nodes = ", count, " Depth = ", depth)
println("Time to parse = $(t2 - t1)")
println("Time to build = $(t3 - t2)")
println("Time to count = $(t4 - t3)")
println("*************************")