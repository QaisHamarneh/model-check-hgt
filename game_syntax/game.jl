include("edge.jl")
using DataStructures

struct Game
    locations::Vector{Location}
    initial_location::Location
    variables:: Vector{Symbol}
    initial_valuation::OrderedDict{Symbol, Float64}
    agents:: Vector{Symbol}
    actions::Vector{Symbol}
    edges:: Vector{Edge}
end

# function Game(locations::Vector{Location}, 
#               initial_location::Location, 
#               variables::Vector{String},
#               initial_valuation::OrderedDict{String, Real}, 
#               agents::Vector{String}, 
#               actions::Vector{String},
#               edges::Vector{Edge},
#               initiate::Bool)::Game
#     game = Game(locations, initial_location, variables, initial_valuation, agents, actions, edges)
#     return game
# end
