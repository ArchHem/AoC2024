using DataStructures

in_bounds(arr,idx::CartesianIndex) = all([idx[i] >= 1 && idx[i] <= size(arr,i) for i in eachindex(idx.I)])

function load_data(T = Int32)
    
    rows = readlines("day10/day10input.txt")
    N_x = length(rows)
    N_y = length(rows[1])

    result = Matrix{T}(undef,N_x,N_y)
    for (index, row) ∈ enumerate(rows)

        result[index,:] = parse.(T,(split(row,"")))
    end
    return result
    
end

data = load_data()

#DFS
function check_path!(u::CartesianIndex,recursor::Set{CartesianIndex{2}}, heights = data)
    up = CartesianIndex(1,0)
    right = CartesianIndex(0,1)

    current_value = heights[u]
    if current_value == 9
        push!(recursor,u)
        return recursor
    end
    kernel = [u + up, u + right, u - up, u - right]

    for k in kernel
        if in_bounds(heights,k) && heights[k] - current_value == 1
            check_path!(k, recursor,heights)
        end
    end
    return recursor
end

function sum_paths(data = data)
    zero_indeces = findall(==(0),data)
    sets = [Set{CartesianIndex{2}}() for j in eachindex(zero_indeces)]
    path_scores = check_path!.(zero_indeces, sets, Ref(data))

    return sum(length.(path_scores))
end

function check_path_p2!(u::CartesianIndex,recursor::Set{Vector{CartesianIndex{2}}}, path::Vector{CartesianIndex{2}}, heights = data)
    up = CartesianIndex(1,0)
    right = CartesianIndex(0,1)

    current_value = heights[u]
    if current_value == 9
        #techn
        push!(recursor,path)
        return recursor
    end
    kernel = [u + up, u + right, u - up, u - right]

    for k in kernel
        if in_bounds(heights,k) && heights[k] - current_value == 1
            lpath = copy(path)
            push!(lpath,k)
            #dont add to set, as only add if it reaches a nine. Instead, feed it to next function's iteration.
            check_path_p2!(k, recursor, lpath, heights)
        end
    end
    return recursor
end


function sum_paths_p2(data = data)
    zero_indeces = findall(==(0),data)
    sets = [Set{Vector{CartesianIndex{2}}}() for j in eachindex(zero_indeces)]
    paths = [Vector{CartesianIndex{2}}() for j in eachindex(zero_indeces)]
    path_scores = check_path_p2!.(zero_indeces, sets, paths, Ref(data))

    return sum(length.(path_scores))
end
#to find number of DISTINCT tails, use vector-of-traversed-indeces as a set or dict elements.

sol1 = sum_paths()
sol2 = sum_paths_p2()



