# using Ranges   # Remove this line
include("packages.jl")
include("parsers/parse_game.jl")
include("game_tree/triggers_based_game_tree.jl")
# include("hybrid_atl/logic.jl")
using DataStructures


t1 = time();

example = 1

if example == 1
    game, termination_conditions, queries = parse_game("examples/bouncing_ball.json")
elseif example == 2
    game, termination_conditions, queries = parse_game("examples/3_players_1_ball.json")
elseif example == 3
    game, termination_conditions, queries = parse_game("examples/player_in_middle.json")
end

t2 = time();


game_tree::Node = build_game_tree(game, termination_conditions, queries)

t3 = time();

results = evaluate(queries, game_tree, game.agents)

t4 = time();

nodes_count, passive_node = count_nodes(game_tree), count_passive_nodes(game_tree)
tree_depth = depth_of_tree(game_tree)

t5 = time();

println("*************************")
println("Nodes = ", nodes_count, " Passive Nodes = ", passive_node, " Depth = ", tree_depth)
println("results = ", results)
println("Time to parse = $(t2 - t1)")
println("Time to build = $(t3 - t2)")
println("Time to model check = $(t4 - t3)")
println("Time to count = $(t5 - t3)")
println("*************************")