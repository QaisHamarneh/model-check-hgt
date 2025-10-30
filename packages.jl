using Pkg

Pkg.activate(".")

Pkg.add("CxxWrap")
Pkg.compat("CxxWrap", "0.16")

dependencies = [
    "DifferentialEquations",
    "IterTools",
    "Match",
    "JSON3",
    "DataStructures",
    "Plots",
    "QML"
]

Pkg.add(dependencies)
