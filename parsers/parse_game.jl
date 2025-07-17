using JSON3
using DataStructures
include("../game_syntax/game.jl")
include("../parsers/parse_constraint.jl")

function read_json(file)
    open(file,"r") do f
        json_string = read(file, String)
        GameDict = JSON3.read(json_string)
        game_name = GameDict["Game"]
        locations = Vector{Location}()
        initial_location = nothing
        for loc in GameDict["Locations"]
            name = Symbol(loc["name"])
            invariant = parse_constraint(loc["invariant"])
            flow = Dict(Symbol(var) => parse_expression(flow) for (var, flow) in loc["flow"])
            if haskey(loc, "initial") && loc["initial"]
                initial_location = Location(name, invariant, flow)
            end
            push!(locations, Location(name, invariant, flow))
        end
        return locations
        agents = Symbol[]
        actions = Symbol[]
        initial_valuation = OrderedDict{Symbol, Float64}()
        edges = Edge[]
        for edge in GameDict["Edges"]
            name = Symbol(edge["name"])
            guard = parse_constraint(edge["guard"])
            flow = Dict(Symbol(var) => parse_expression(flow) for (var, flow) in loc["flow"])
            if haskey(loc, "initial") && loc["initial"]
                initial_location = Location(name, invariant, flow)
            end
            push!(edges, Edge(name, invariant, flow))
        end
    end
end

read_json("examples/simple_game.json")