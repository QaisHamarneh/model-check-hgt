using JSON3
using DataStructures
include("../game_syntax/game.jl")
include("parser.jl")

function parse_game(json_file)
    open(json_file,"r") do f
        json_string = read(json_file, String)
        FileDict = JSON3.read(json_string)
        GameDict = FileDict["Game"]
        game_name = GameDict["name"]
        locations = Location[]
        initial_location = nothing
        for loc in GameDict["locations"]
            name = Symbol(loc["name"])
            invariant::Constraint = to_logic(parse_tokens(tokenize(loc["invariant"]), constraint))
            flow::ReAssignment = Dict{Symbol, ExprLike}()
            if ! isempty(loc["flow"])
                flow = Dict(Symbol(var) => to_logic(parse_tokens(tokenize((flow)), expression))
                                            for (var, flow) in loc["flow"])
            end
            location = Location(name, invariant, flow)
            if haskey(loc, "initial") && loc["initial"]
                initial_location = location
            end
            push!(locations, location)
        end
        agents = Set{Agent}([Symbol(agent) for agent in GameDict["agents"]])
        actions = Set{Action}([Symbol(action) for action in GameDict["actions"]])
        initial_valuation::Valuation = Dict{Symbol, Float64}()
        if ! isempty(GameDict["initial_valuation"])
            initial_valuation = OrderedDict(Symbol(var) => value for (var, value) in GameDict["initial_valuation"])
        end
        edges = Edge[]
        for edge in GameDict["edges"]
            name = Symbol(edge["name"])
            start_location = nothing
            target_location = nothing
            start_location_ind = findfirst(loc -> loc.name == Symbol(edge["start_location"]), locations)
            target_location_ind = findfirst(loc -> loc.name == Symbol(edge["target_location"]), locations)
            if start_location_ind === nothing || target_location_ind === nothing
                error("Edge $(name) references non-existent locations:", edge["start_location"], " - ", edge["target_location"])
            else
                start_location = locations[start_location_ind]
                target_location = locations[target_location_ind]
            end
            decisions::Vector{Decision} = Pair{Agent, Action}[Symbol(agent) => Symbol(action) for (agent, action) in edge["decision"]]
            if length(decisions) != 1
                error("Edge $(name) must have exactly one decision (agent-action pair). Found: ", decisions)
            end
            guard::Constraint = to_logic(parse_tokens(tokenize(edge["guard"]), constraint))
            jump::ReAssignment = Dict{Symbol, ExprLike}()
            if ! isempty(edge["jump"])
                jump = Dict(Symbol(var) => to_logic(parse_tokens(tokenize(jump), expression))
                            for (var, jump) in edge["jump"])
            end
            push!(edges, Edge(name, start_location, target_location, guard, decisions[1], jump))
        end
        triggers::Dict{Agent, Vector{Constraint}} = Dict(Symbol(agent) => 
            Constraint[to_logic(parse_tokens(tokenize(trigger), constraint))
                for trigger in agents_triggers] 
                for (agent, agents_triggers) in GameDict["triggers"])

        game = Game(game_name, locations, initial_location, initial_valuation, agents, actions, edges, triggers, true)

        termination_conditions = Dict{String, Any}()
        termination_conditions["max-time"] = Float64(FileDict["termination-conditions"]["time-bound"])
        termination_conditions["max-steps"] = Int64(FileDict["termination-conditions"]["max-steps"])
        termination_conditions["state-formula"] = to_logic(parse_tokens(tokenize(FileDict["termination-conditions"]["state-formula"]), state))
        queries::Vector{Strategy_Formula} = State_Formula[to_logic(parse_tokens(tokenize(query), strategy)) for query in FileDict["queries"]]
        return game, termination_conditions, queries

    end
end


# game, termination_conditions, queries = parse_game("examples/3_players_1_ball.json")

# println("********************")