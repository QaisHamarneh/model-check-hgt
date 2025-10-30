x = [1, 2, 3]

function change_array!(arr)
    for i in eachindex(arr)
        pop!(arr)
    end
    for j in [4, 5, 6]
        push!(arr, j)
    end
end

change_array!(x)
println(x)  # What is the content of x after the function call?


mutable struct Point
    x::Float64
    y::Float64
end

function move_point!(p::Point, dx::Float64, dy::Float64)
    p.x += dx
    p.y += dy
end

p = Point(1.0, 2.0)
move_point!(p, 3.0, 4.0)
println("Point after move: (", p.x, ", ", p.y, ")")  # What are the coordinates of p after the function call?