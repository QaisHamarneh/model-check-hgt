using JSON3
using DataStructures
include("../game_syntax/game.jl")
include("../parsers/parse_constraint.jl")

function parse_game(json_file)
    open(json_file,"r") do f
        json_string = read(json_file, String)
        GameDict = JSON3.read(json_string)
        game_name = GameDict["Game"]
        locations = Location[]
        initial_location = nothing
        for loc in GameDict["locations"]
            name = Symbol(loc["name"])
            invariant::Constraint = parse_constraint(loc["invariant"])
            flow::Dict{Symbol, ExprLike} = Dict(Symbol(var) => parse_expression(flow) for (var, flow) in loc["flow"])
            location = Location(name, invariant, flow)
            if haskey(loc, "initial") && loc["initial"]
                initial_location = location
            end
            push!(locations, location)
        end
        agents = Symbol[Symbol(agent) for agent in GameDict["agents"]]
        actions = Symbol[Symbol(action) for action in GameDict["actions"]]
        initial_valuation::OrderedDict{Symbol, Float64} = OrderedDict(Symbol(var) => value for (var, value) in GameDict["initial_valuation"])
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
            decision::Dict{Symbol, Symbol} = Dict(Symbol(agent) => Symbol(action) for (agent, action) in edge["decision"])
            guard::Constraint = parse_constraint(edge["guard"])
            jump::OrderedDict{Symbol, ExprLike} = OrderedDict(Symbol(var) => parse_expression(jump) for (var, jump) in edge["jump"])
            push!(edges, Edge(name, start_location, target_location, guard, decision, jump))
        end

        triggers = Constraint[parse_constraint(trigger) for trigger in GameDict["triggers"]]
        initial_triggers::Dict{Symbol, Pair{Constraint, Symbol}} = Dict(Symbol(agent) => (parse_constraint(trigger) => Symbol(action)) for (agent, (trigger, action)) in GameDict["initial_triggers"])
        return Game(game_name, locations, initial_location, initial_valuation, agents, actions, edges, triggers, initial_triggers, true)
    end
end


# bouncing_ball::Game = parse_game("examples/simple_game.json")