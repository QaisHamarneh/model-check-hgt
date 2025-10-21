# Alternatively, execute the git command directly in the shell or download the zip file
# import LibGit2
# isdir("QmlJuliaExamples") || LibGit2.clone("https://github.com/barche/QmlJuliaExamples.git", "QmlJuliaExamples")
# cd("basic") # or images, opengl or plots instead of the basic subdirectory

# As an alternative to next three lines,
# 1) Start Julia with `julia --project`
# 2) Run `instantiate` from the pkg shell.
using Pkg
Pkg.activate(".")
Pkg.instantiate()

# readdir() # Print list of example files
include("listview.jl") # Or any of the files in the directory