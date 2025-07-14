using JSON3





function read_json(file)
    open(file,"r") do f
        json_string = read(file, String)
        JSON3.read(json_string)
    end
end

read_json("examples/simple_game.json")