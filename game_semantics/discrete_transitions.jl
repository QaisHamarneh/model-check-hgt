include("../essential_definitions/evolution.jl")
include("configuration.jl")

function discrete_transition(start_config::Configuration, edge::Edge)::Configuration
    Configuration(edge.target_location, 
                  discrete_evolution(start_config.valuation, edge.jump)
                 )
end