include("edge.jl")
using DataStructures

struct Game
    name::String
    locations::Vector{Location}
    initial_location::Location
    variables:: Vector{Symbol}
    initial_valuation::OrderedDict{Symbol, Float64}
    agents:: Vector{Symbol}
    actions::Vector{Symbol}
    edges:: Vector{Edge}
end

function Game(name::String,
              locations::Vector{Location}, 
              initial_location::Location, 
              initial_valuation::OrderedDict{Symbol, Float64}, 
              agents::Vector{Symbol}, 
              actions::Vector{Symbol},
              edges::Vector{Edge})::Game
    game = Game(name, locations, initial_location, collect(keys(initial_valuation)), initial_valuation, agents, actions, edges)

    """ First edge in each location is a stutter edge that allows the game to stay in the same location without making any changes. """
    stutter_decision = Dict(agent => :nothing for agent in game.agents)
    for location in game.locations
        stutter_edge = Edge(:StutterEdge, 
                            location, 
                            location, 
                            Truth(true), 
                            stutter_decision, 
                            OrderedDict())
        push!(location.edges, stutter_edge)
    end

    for edge in game.edges
        push!(edge.start_location.edges, edge)
    end
    return game
end
