include("packages.jl")
include("parsers/parse_game.jl")
include("game_tree/triggers_based_game_tree.jl")


t1 = time();

example = 1

if example == 1
    game, termination_conditions, _ = parse_game("examples/bouncing_ball.json")
    queries = Logic_Formula[ Exist_Strategy(Set([:α]), Constraint_Formula(parse_constraint("pos < 0 || pos > 1000")))]
elseif example == 2
    game, termination_conditions, _ = parse_game("examples/3_players_1_ball.json")
    queries = Logic_Formula[ Exist_Strategy(Set([:A]), Eventually(Constraint_Formula(parse_constraint("y > 8")))), 
                                Exist_Strategy(Set([:A, :B]), Eventually(Constraint_Formula(parse_constraint("y > 8"))))]
elseif example == 3
    game, termination_conditions, _ = parse_game("examples/player_in_middle.json")
    queries = Logic_Formula[ Forall_Strategy(Set([:A, :B]), Globally(Not_Formula(Location_Formula(:Caught))))]
end

t2 = time();

properties = get_all_properties(queries)

game_tree::Node = build_triggers_game_tree(game, properties, termination_conditions)

t3 = time();

# results = evaluate(queries, game_tree, game.agents)

# t4 = time();

count = count_nodes(game_tree)
depth = depth_of_tree(game_tree)

t5 = time();

println("*************************")
println("Nodes = ", count, " Depth = ", depth)
# println("results = ", results)
println("Time to parse = $(t2 - t1)")
println("Time to build = $(t3 - t2)")
# println("Time to model check = $(t4 - t3)")
println("Time to count = $(t5 - t3)")
println("*************************")