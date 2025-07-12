ll = [['a', 'b', 'c'], ['g', 'h', 'i', 'j'], ['x', 'y', 'z']] 

using IterTools

for combo in product(ll...)
    println(combo)
end
println("********")
# for i in 1:3*4*3
#     j = i
#     for k in 3:-1:1
#         len = 1
#         for kk in 1:k-1
#             len *= length(ll[kk])
#         end
#         println("i: $i -> ", ll[k][div(j, len) + 1])
#         j = j - div(j, len) * len
#     end
#     println("********")
# end