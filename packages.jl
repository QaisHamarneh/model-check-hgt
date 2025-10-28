using Pkg

Pkg.activate(".")
Pkg.instantiate()

Pkg.add("CxxWrap")

Pkg.compat("CxxWrap", "0.16")

dependencies = [
    "IterTools",
    "DifferentialEquations",
    "Match",
    "JSON3",
    "DataStructures",
    "Plots",
    "QML"
]

Pkg.add(dependencies)