include("../essential_definitions/evolution.jl")
include("configuration.jl")


function continuous_transition(start_config::Configuration, time::Real)::Configuration
    Configuration(start_config.location, 
                  continuous_evolution(start_config.valuation, start_config.location.flow, time),
                    start_config.global_clock + time
                 )
end


function discrete_transition(start_config::Configuration, edge::Edge)::Configuration
    Configuration(edge.target_location, 
                  discrete_evolution(start_config.valuation, edge.jump),
                  start_config.global_clock
                 )
end