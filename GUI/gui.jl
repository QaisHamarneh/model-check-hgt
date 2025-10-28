include("../packages.jl")

using QML

include("../parsers/parser.jl")

function is_valid_expression(expr, vars)
    expr = String(expr)
    variables = Vector{String}()
    for i in 1:length(vars)
        push!(variables, vars[i])
    end
    try
        parse(expr, Bindings(Set(), Set(), Set(variables)), expression)
        return true
    catch
        return false
    end
end

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

@qmlfunction is_valid_expression is_valid_constraint

qml_file = joinpath(dirname(@__FILE__), "gui.qml")

loadqml(qml_file, guiproperties = JuliaPropertyMap())

exec()
