include("../game_syntax/game.jl")

struct Configuration
    location::Location
    valuation::OrderedDict{Symbol, Float64}
end

function str(config::Configuration)::String
    return "⟨ $(config.location.name) , $(config.valuation)⟩"
end

function initial_configuration(game::Game)::Configuration
    Configuration(game.initial_location, 
                  game.initial_valuation)
end