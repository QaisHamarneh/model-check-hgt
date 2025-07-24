using DataStructures

function round3(num::Float64)::Float64
    return round(num, digits=3)
end

function valuation_from_vector(valuation::OrderedDict{Symbol, Float64}, vector::Vector{Float64})::OrderedDict{Symbol, Float64}
    new_valuation::OrderedDict{Symbol, Float64} = OrderedDict()
    for (i, (var, _)) in enumerate(valuation)
        new_valuation[var] = vector[i]
    end
    return new_valuation
end

function find_set(set::Vector, 
                     relation)
    minimums = []
    for element in set
        is_minimal = true
        for other_element in set
            if element != other_element && relation(other_element, element)
                is_minimal = false
                break
            end
        end
        if is_minimal
            push!(minimums, element)
        end
    end
    return minimums
end
