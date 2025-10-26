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