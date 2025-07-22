include("../essential_definitions/evolution.jl")
include("configuration.jl")


function continuous_transition(start_config::Configuration, time::Real)::Configuration
    Configuration(start_config.location, 
                  continuous_evolution(start_config.valuation, start_config.location.flow, time),
                  start_config.triggers
                 )
end