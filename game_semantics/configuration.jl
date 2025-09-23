include("../game_syntax/game.jl")

struct Configuration
    location::Location
    valuation::Valuation
end

function initial_configuration(game::Game)::Configuration
    Configuration(game.initial_location, 
                  game.initial_valuation)
end