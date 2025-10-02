include("edge.jl")
using DataStructures

struct Game
    name::String
    locations::Vector{Location}
    initial_location::Location
    initial_valuation::Valuation
    agents:: Set{Agent}
    actions::Set{Action}
    edges:: Vector{Edge}
    triggers:: Dict{Agent, Vector{Constraint}}
end

function Game(  name::String,
                locations::Vector{Location}, 
                initial_location::Location, 
                initial_valuation::Valuation, 
                agents::Set{Agent}, 
                actions::Set{Action},
                edges::Vector{Edge},
                triggers:: Dict{Agent, Vector{Constraint}},
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