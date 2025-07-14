include("edge.jl")

struct Game
    locations::Vector{Location}
    initial_location::Location
    variables:: Vector{String}
    initial_valuation::Dict{String, Real}
    agents:: Vector{String}
    actions::Vector{String}
    edges:: Vector{Edge}
end

function Game(locations::Vector{Location}, 
              initial_location::Location, 
              variables::Vector{String},
              initial_valuation::Dict{String, Real}, 
              agents::Vector{String}, 
              actions::Vector{String},
              edges::Vector{Edge},
              initiate::Bool)::Game
    game = Game(locations, initial_location, variables, initial_valuation, agents, actions, edges)
    fill_location_edges(game)
    return game
end


location_edges::Dict{Location, Vector{Edge}} = Dict()

function fill_location_edges(game::Game)
    for location in game.locations
        location_edges[location] = []
    end
    for edge in game.edges
        push!(location_edges[edge.start_location], edge)
    end
end
