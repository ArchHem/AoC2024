using DataStructures

function load_data()
    lines = readlines("day18/day18input.txt")
    Ny = length(lines)
    results = zeros(Int64,Ny,2)
    for (index,row) in enumerate(lines)
        results[index,:] = parse.(Int64,split(row,","))
    end
    results = results[:,end:-1:1]
    return results .+ 1
end


total_data = load_data()

#Part 1 

#Djikastra time

function generate_neighbors(x)
    dirs = CartesianIndex.([1,0,-1,0],[0,1,0,-1])
    return x .+ dirs
end

function is_in(x,A)
    return all([x.I[i] > 0 && x.I[i] <= size(A,i) for i in 1:length(x.I)])
end

function solve_p1(bytes)
    process_data = CartesianIndex.(bytes[:,1],bytes[:,2])
    

    grid = zeros(Int64,71,71)
    grid[process_data] .= 1
    goal = CartesianIndex(71,71)
    
    distances = fill(typemax(Int64)-1,71,71)
    distances[1,1] = 0

    que = Deque{CartesianIndex{2}}()
    push!(que,CartesianIndex(1,1))
    visited = falses(71,71)
    visited[1,1] = true
    

    while !isempty(que)
        currnode = popfirst!(que)
        nn = generate_neighbors(currnode)

        for np in nn
            if is_in(np,grid) && grid[np] == 0 && !visited[np]
                distances[np] = distances[currnode] + 1
                push!(que,np)
                visited[np] = true
            end
        end
    end

    

    return distances[goal]

end

sol1 = solve_p1(total_data[1:1024,:])
#Part 2: two way to solve it

#Either do a binary search on the input space of part1 (introducing log(N) scaling where N is the max length of the byte-vector)

#Or think about this is a 3d pathfinding problem where we may only travel into the upper "lightcone". 
#This would require an abstract datastructure however and I am not sure if I can implemenet it.

#Option b: track the shortest path (if such exists) thru a dictionary of indeces and ONLY redo the calcs if a new bit has fallen into the current path.

function solve_p2_binary(data = total_data)
    to_find = typemax(Int64)-1
    left = 1
    right = size(total_data)[1]
    while left < right
        mid = floor(Int64,(left + right)/2)
        val = solve_p1(data[1:mid,:])

        if val == to_find
            right = mid
        elseif val < to_find
            left = mid + 1
        end
    end
    #format to output req.
    return reverse(total_data[left,:] .-1 )
end

sol2 = solve_p2_binary()

