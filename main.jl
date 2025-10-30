# using Ranges   # Remove this line
include("packages.jl")
include("parsers/parse_game.jl")
include("game_tree/triggers_based_game_tree.jl")
include("model_checking/build_and_evaluate.jl")
using DataStructures


t1 = time();

example = 2

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

nodes_count, passive_nodes = count_nodes(game_tree), count_passive_nodes(game_tree)
tree_depth = depth_of_tree(game_tree)

##################################
t5 = time();

results_on_demand, game_tree_on_demand = evaluate_queries(game, termination_conditions, queries)

t6 = time();

nodes_count_on_demand, passive_nodes_on_demand = count_nodes_on_demand(game_tree_on_demand), count_passive_nodes_on_demand(game_tree_on_demand)
tree_depth_on_demand = depth_of_tree_on_demand(game_tree_on_demand)

println("*************************")
println("Time to parse = $(t2 - t1)")
println("*************************")
println("Nodes = ", nodes_count, " Passive Nodes = ", passive_nodes, " Depth = ", tree_depth)
println("results = ", results)
println("Time to build = $(t3 - t2)")
println("Time to evaluate = $(t4 - t3)")
println("*************************")
println("***** On the fly ********")
println("Nodes = ", nodes_count_on_demand, " Passive Nodes = ", passive_nodes_on_demand, " Depth = ", tree_depth_on_demand)
println("results = ", results_on_demand)
println("Time to evaluate and build = $(t6 - t5)")
println("*************************")