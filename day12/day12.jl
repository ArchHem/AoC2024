using BenchmarkTools
using Plots

function load_data()
    
    rows = readlines("day12/day12input.txt")
    N_x = length(rows)
    N_y = length(rows[1])

    result = Matrix{Char}(undef,N_x,N_y)
    for (index, row) ∈ enumerate(rows)

        result[index,:] = only.(split(row,""))
    end
    return result
    
end

data = load_data()
#move to numeric datatype for processing
function to_numeric(data = data)
    distinct_chars = unique(data)
    ldict = Dict(distinct_chars .=> eachindex(distinct_chars))
    new_array = getindex.(Ref(ldict), data)

    return new_array


end

num_data = to_numeric(data)
is_visited = falses(size(data))

in_bounds(arr,idx::CartesianIndex) = all([idx[i] >= 1 && idx[i] <= size(arr,i) for i in eachindex(idx.I)])

#graph travelsal time....

function DFS_track!(id, position, data = num_data, is_visited = is_visited, area = [0], perim = [0])
    kernel = [CartesianIndex(1,0),CartesianIndex(0,1), CartesianIndex(-1,0),CartesianIndex(0,-1)]
    
    is_visited[position] = true
    area .+= 1

    for k in kernel
        #same cluster, not yet visited and in bounds (used to short-circuit)
        proposed = position + k
        b1 = in_bounds(data,proposed) && data[proposed] == id
        if b1 && !is_visited[proposed]
            DFS_track!(id,proposed,data,is_visited,area,perim)
        elseif !b1
            perim .+= 1
        end
    end

    return 
end

function full_sum_p1(data = num_data, is_visited = is_visited)
    total_sum = 0
    is_visited = copy(is_visited)
    for i in CartesianIndices(data)
        if !is_visited[i]
            area, perim = [0], [0]
            DFS_track!(data[i],i,data,is_visited,area,perim)
            total_sum += area[1]*perim[1]
        end
    end
    return total_sum

end

sol1 = full_sum_p1()

#and edge is defined : an area of the border facing the same kernel direction which runs across the "same" x or y coordinate

function DFS_p2!(id, position, data = num_data, is_visited = is_visited, area = [0], corners = [0]) #offset needs to be smaller than 1 and lr. 0
    kernel = [CartesianIndex(1,0),CartesianIndex(0,1), CartesianIndex(-1,0),CartesianIndex(0,-1)]
    
    #this is an ORDERED rotation
    rotate(x::CartesianIndex) = CartesianIndex((-x.I[2],x.I[1],))
    is_visited[position] = true
    area .+= 1

    outer_kernel, outer_negative = [CartesianIndex(1,0), CartesianIndex(0,1)], CartesianIndex(1,1)
    inner_kernel = [CartesianIndex(1,0),CartesianIndex(0,1)]
    #This entire code block could be ran only if we have non-local neighbors via any() call and a separate kernel
    for i in 1:4

        local_outer, local_outer_negative = position .+ outer_kernel, position + outer_negative
        local_inner = position .+ inner_kernel

        
        in_outer = [in_bounds(data,local_outer[j]) && data[local_outer[j]] == id for j in 1:2]
        in_negative = in_bounds(data,local_outer_negative) && data[local_outer_negative] != id

        is_outer = all(in_outer) && in_negative

        if is_outer
            corners .+= 1
        end
        

        #in different or out of bounds: all must be met to be an outer edge
        in_in  = [!in_bounds(data,local_inner[j]) || data[local_inner[j]] != id for j in 1:2]
        is_inner = all(in_in)

        if is_inner
            corners .+= 1
        end

        outer_kernel, outer_negative = rotate.(outer_kernel), rotate(outer_negative)
        inner_kernel = rotate.(inner_kernel)
    end
    

    
    for (index,k) in enumerate(kernel)
        #same cluster, not yet visited and in bounds (used to short-circuit)
        proposed = position + k
        b1 = in_bounds(data,proposed) && data[proposed] == id #is it in-bounds AND does it have the same ID?
        if b1 && !is_visited[proposed]
            DFS_p2!(id,proposed,data,is_visited,area,corners)
        end
    end
    
    #
    

    return 
end

function solve_p2(data = num_data, is_visited = is_visited)
    total_sum = 0
    is_visited = copy(is_visited)
    
    
    for i in CartesianIndices(data)
        if !is_visited[i]
            area, corners= [0], [0]
            
            DFS_p2!(data[i],i,data,is_visited,area,corners)

            total_sum += area[1]*corners[1]
        end
    end
    return total_sum
end

sol2 = solve_p2()

#Theorem used:
#https://en.wikipedia.org/wiki/Euler_characteristic

#for our 2d CASE, X = V - E + F Our polyhedra is has 1 face, and X = 1  This means that if we can determine 
#the number of corners, they must equal the number of edges.