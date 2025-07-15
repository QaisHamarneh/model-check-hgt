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

# function Game(locations::Vector{Location}, 
#               initial_location::Location, 
#               variables::Vector{String},
#               initial_valuation::Dict{String, Real}, 
#               agents::Vector{String}, 
#               actions::Vector{String},
#               edges::Vector{Edge},
#               initiate::Bool)::Game
#     game = Game(locations, initial_location, variables, initial_valuation, agents, actions, edges)
#     return game
# end
