using Test
using QML
using Observables

counter = 0
const oldcounter = Observable(0)

function increment_counter()
  global counter, oldcounter
  oldcounter[] = counter
  counter += 1
end

# absolute path in case working dir is overridden
qml_file = joinpath(dirname(@__FILE__), "qml", "listview.qml")

# Load the QML file
loadqml(qml_file, guiproperties = JuliaPropertyMap("oldcounter" => oldcounter))

# Run the application
exec()
