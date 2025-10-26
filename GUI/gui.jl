using Pkg

Pkg.activate(".")
Pkg.instantiate()

using QML
using Observables

include("../parsers/parser.jl")

function is_valid_constraint(constr, vars)
    constr = String(constr)
    variables = Vector{String}()
    for i in 1:length(vars)
        push!(variables, vars[i])
    end
    try
        parse(constr, Bindings(Set(), Set(), Set(variables)), constraint)
        return true
    catch
        return false
    end
end

@qmlfunction is_valid_constraint

qml_file = joinpath(dirname(@__FILE__), "gui.qml")

loadqml(qml_file, guiproperties = JuliaPropertyMap())

exec()
