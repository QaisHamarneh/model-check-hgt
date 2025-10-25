using Pkg

Pkg.activate(".")
Pkg.instantiate()

using QML
using Observables

qml_file = joinpath(dirname(@__FILE__), "gui.qml")

loadqml(qml_file, guiproperties = JuliaPropertyMap())

exec()
