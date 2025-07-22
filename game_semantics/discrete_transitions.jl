include("../essential_definitions/evolution.jl")
include("configuration.jl")

function discrete_transition(start_config::Configuration, edge::Edge, new_triggers::Dict{Symbol, Pair{Constraint, Symbol}})::Configuration
    Configuration(edge.target_location, 
                  discrete_evolution(start_config.valuation, edge.jump),
                  new_triggers
                 )
end