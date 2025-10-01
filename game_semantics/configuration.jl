include("../game_syntax/game.jl")

struct Configuration
    location::Location
    valuation::Valuation
    global_clock::Float64
end

function initial_configuration(game::Game)::Configuration
    Configuration(game.initial_location, 
                  game.initial_valuation,
                  0.0)
end