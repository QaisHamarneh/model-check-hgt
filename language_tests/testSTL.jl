using StringParserPEG

# Define a simple arithmetic CFG
calc1 = Grammar("""
  start => number | (number & op & number)
  op => plus | minus
  number => (-(space) & r([0-9]+)r) 
  plus => (-(space) & '+')
  minus => (-(space) & '-')
  space => r([ \\t\\n\\r]*)r
""")

# (ast, pos, err) = parse(calc1, "4+5")
# println(ast)  
# println(pos)  
# println(err) 

# # Function to check if input matches grammar
function matches_expr(input::String)
    try
        (ast, pos, err) = parse(calc1, input)
        println("Parsed AST: ", ast)
        println("Position: ", pos)
        println("Error: ", err)
        return ast !== nothing
    catch
        return ast
    end
end

# Example usage
println("************")
println(matches_expr("1+2"))         # true
println("************")
println(matches_expr("3 + 4 * 5"))   # true
println("************")
println(matches_expr("- 5"))       # false
println("************")