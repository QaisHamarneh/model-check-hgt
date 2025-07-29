include("edge.jl")
using DataStructures

struct Game
    name::String
    locations::Vector{Location}
    initial_location::Location
    initial_valuation::OrderedDict{Symbol, Float64}
    agents:: Vector{Symbol}
    actions::Vector{Symbol}
    edges:: Vector{Edge}
    triggers:: Vector{ExprLike}
end

function Game(name::String,
              locations::Vector{Location}, 
              initial_location::Location, 
              initial_valuation::OrderedDict{Symbol, Float64}, 
              agents::Vector{Symbol}, 
              actions::Vector{Symbol},
              edges::Vector{Edge},
              triggers::Vector{ExprLike},
              initiate::Bool)::Game
    game = Game(name, 
                locations, 
                initial_location, 
                initial_valuation, 
                agents, 
                actions, 
                edges, 
                triggers)

    """ First edge in each location is a stutter edge that allows the game 
        to stay in the same location without making any changes. """

    for edge in game.edges
        push!(edge.start_location.edges, edge)
    end
    return game
end

function string(game::Game)::String
    return "Game: $(game.name) with $(length(game.locations)) locations, $(length(game.agents)) agents, $(length(game.agents)) actions, $(length(game.edges)) edges."
end