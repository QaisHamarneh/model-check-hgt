include("../essential_definitions/constraint.jl")
using Match
using DataStructures

abstract type STL_Formula end

struct STL_Truth <: STL_Formula
    value::Bool
end

struct Proposition <: STL_Formula
    proposition::Symbol
end

struct STL_Constraint <: STL_Formula
    constraint::Constraint
end

struct STL_And <: STL_Formula
    left::STL_Formula
    right::STL_Formula
end

struct STL_Or <: STL_Formula
    left::STL_Formula
    right::STL_Formula
end

struct STL_Not <: STL_Formula
    formula::STL_Formula
end

struct Until <: STL_Formula
    left::STL_Formula
    right::STL_Formula
    interval_begin::Float64
    interval_end::Float64
end

struct Always <: STL_Formula
    formula::STL_Formula
    interval_begin::Float64
    interval_end::Float64
end

struct Eventually <: STL_Formula
    formula::STL_Formula
    interval_begin::Float64
    interval_end::Float64
end