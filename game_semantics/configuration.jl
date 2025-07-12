include("../game_syntax/game.jl")

struct Configuration
    location::Location
    valuation::Dict{String, Real}
end

function str(config::Configuration)::String
    return "⟨ $(config.location.name) , $(config.valuation)⟩"
end

function initial_configuration(game::Game)::Configuration
    Configuration(game.initial_location, 
                  game.initial_valuation)
end