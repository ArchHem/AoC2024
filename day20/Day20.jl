using DataStructures


function load_data()
    rows = readlines("day20/day20input.txt")
    output = zeros(Int64,length(rows),length(rows[1]))
    ldict = Dict('#'=>0, 'S'=>2, 'E'=>3,'.'=>1)
    for (index, r) in enumerate(rows)
        output[index,:] = getindex.(Ref(ldict), only.(split(r,"")))
    end
    startpos, endpos = findfirst(==(2),output), findfirst(==(3),output)
    output[startpos] = 1
    output[endpos] = 1
    return output, startpos, endpos
end

data, sp, ep = load_data()

function generate_neighbors(x)
    dirs = CartesianIndex.([1,0,-1,0],[0,1,0,-1])
    return x .+ dirs
end

function is_in(x,A)
    return all([x.I[i] > 0 && x.I[i] <= size(A,i) for i in 1:length(x.I)])
end

function generate_distances(data, sp = sp)
    #use BFS for graph traversal

    #We want to measure distance from start & end and generate transmission kernels

    #nodes of value 0 are unreachable
    
    distances = fill(typemax(Int64)-1,size(data))
    distances[sp] = 0

    que = Deque{CartesianIndex{2}}()
    push!(que,sp)
    visited = falses(size(data))
    visited[sp] = true
    

    while !isempty(que)
        currnode = popfirst!(que)
        nn = generate_neighbors(currnode)

        for np in nn
            if is_in(np,data) && data[np] == 1 && !visited[np]
                distances[np] = distances[currnode] + 1
                push!(que,np)
                visited[np] = true
            end
        end
    end

    return distances
end

function generate_kernel(x)
    k1 = CartesianIndex.([2,0,-2,0,1,-1,1,-1],[0,2,0,-2,1,1,-1,-1])
    return x .+ k1
end

#technically extracting the path is also viable.... could benchmark later, smaller memory needs but rpolly slower lookup even if both O(1)

#p
function solve_p1(data, sp = sp)
    sd = generate_distances(data, sp)

    #normally, the shortest distance between e and s would be sd[i] + ed[i]

    #if a cheat connects 

    #I strongly suspect there is only one viable path here, so technically we could just get the path distance at the end.
     
    gains = Int64[]
    lmax = typemax(Int64)-1
    
    for index in CartesianIndices(data)
        if sd[index] != lmax
            nn = generate_kernel(index)
            
            for np in nn
                if is_in(np,data) && data[np] == 1 && sd[np] > sd[index]
                    gain = sd[np] - sd[index] - 2 #2 steps could be used otherwise
                    push!(gains, gain)
                end
            end
        end
    end
    return gains
end

gains1 = solve_p1(data, sp)
sol1 = sum(abs.(gains1) .>= 100)

#Ok now lets use the single path heurestic...
#just to show how its done for part, we extract the (simple) path

function get_path_p2(data, sp = sp)
    path = CartesianIndex{2}[]
    distances = fill(typemax(Int64)-1,size(data))
    distances[sp] = 0

    que = Deque{CartesianIndex{2}}()
    push!(que,sp)
    visited = falses(size(data))
    visited[sp] = true
    push!(path,sp)

    while !isempty(que)
        currnode = popfirst!(que)
        nn = generate_neighbors(currnode)

        for np in nn
            if is_in(np,data) && data[np] == 1 && !visited[np]
                distances[np] = distances[currnode] + 1
                push!(que,np)
                visited[np] = true
                push!(path,np)
            end
        end
    end
    return path
end

function generate_diamond(x,n = 20)
    #generates a full diamond and the correspondong cartesian distances
    #technically we could pre-aloocate....
    results = CartesianIndex{2}[]
    distances = Int64[]
    #manhattianian distance is: abs(x) + abs(y) = n

    for i in -n:n
        maxj = n-abs(i)
        for j in -maxj:maxj
            push!(results,CartesianIndex(i,j))
            push!(distances,abs(i)+abs(j))
        end
    end
    return x .+ results, distances
end

const translatror = Dict(
    CartesianIndex(1,0) => 0,
    CartesianIndex(0,1) => 1,
    CartesianIndex(-1,0) => 2,
    CartesianIndex(0,-1) => 3
)

function generate_wavefront(x, orientation, n=20)
    #generate a wavefront of a diamond facing a particular direction.
    rotator = [0 1; -1 0]
    results = Vector{CartesianIndex{2}}(undef,2*n+1)
    loc_matrix = rotator^translatror[orientation]
    for i in -n:n
        j = n-abs(i)
        
        local_vec = loc_matrix * [i,j]
        results[i+n+1] = CartesianIndex(local_vec[2],local_vec[1])

    end

    return x .+ results

end

function solve_p2(path)
    N = length(path)
    pathdist = collect(0:N-1)
    prev_loc = path[1]
    #map indeces to distances....
    path = OrderedDict{CartesianIndex{2},Int64}(path .=> pathdist)
    
    
    counter = 0
    firstdiamond, distances = generate_diamond(prev_loc)

    

    is_in = in.(firstdiamond,Ref(keys(path)))
    
    gains = getindex.(Ref(path), firstdiamond[is_in]) .- distances[is_in] .- path[prev_loc]
    #I dont think this needs to be ordered...
    gains_dict = Dict(firstdiamond[is_in] .=> gains)
    counter += sum(values(gains_dict) .>= 100)

    

    

    for node in collect(keys(path))[2:N]
        
        curr_loc = node
        displ = curr_loc - prev_loc
        wave = generate_wavefront(curr_loc,displ)
        downwave = generate_wavefront(prev_loc,-1*displ)
        
        dist = 20
        #problem with this method that it does-not recount the "non-facing" parts of the previous gains.... hopefully thix fixes it.
        is_in = in.(wave,Ref(keys(path)))
        delete!.(Ref(gains_dict), downwave)
        

        #is there a better way to shift the distances?
        foreach(k -> gains_dict[k] = path[k] - path[curr_loc] - sum(abs.((k - curr_loc).I)), keys(gains_dict))
        new_gains = getindex.(Ref(path), wave[is_in]) .- dist .- path[curr_loc]
        push!.(Ref(gains_dict), wave[is_in] .=> new_gains)
        
        
        counter += sum(values(gains_dict) .>= 100)
        
        prev_loc = curr_loc

    end

    return counter

end

function solve_p2_bforce(path)
    N = length(path)
    pathdist = collect(0:N-1)
   
    path = OrderedDict{CartesianIndex{2},Int64}(path .=> pathdist)
    
    counter = 0
   
    for node in keys(path)
        
        curr_loc = node
        wave, distances = generate_diamond(curr_loc)
        
        
        is_in = in.(wave,Ref(keys(path)))
        
        new_gains = getindex.(Ref(path), wave[is_in])  .- path[curr_loc] .- distances[is_in]
        
        
        counter += sum(values(new_gains) .>= 100)
        delete!(path,curr_loc)

    end

    return counter

end

path = get_path_p2(data,sp)
sol2 = solve_p2(path)
sol2b = solve_p2_bforce(path)
