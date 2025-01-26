using DataStructures

function load_data()
    ldict = Dict("#"=>1, "."=> 0, "E" => 0, "S" => 0)
    rows = readlines("day16/day16input.txt")
    Ny, Nx = length(rows), length(rows[1])
    outp = zeros(Int64,Ny,Nx)
    for (index,r) in enumerate(rows)
        lrow = split(r,"")
        trow = getindex.(Ref(ldict),lrow)
        outp[index,:] = trow
    end
    return outp

end

#its Djikastraing time

data = load_data()

function generate_neighbors(node)
    #given input vector, generate all neighbors that are reachable, thru rotation and simple movement.

    velocs = CartesianIndex.([0,1,0,-1],[1,0,-1,0])

    z = node.I[3]
    upz = mod(z,4) + 1
    lowz = mod(z-2,4) + 1
    currveloc = velocs[z]
    y, x = node.I[1], node.I[2]
    neighbors = CartesianIndex.([y + currveloc.I[1],y,y],[x + currveloc.I[2],x,x],[z,upz,lowz])
    return neighbors
end

function solve_p1(data,stepscore = 1, turnscore = 1000)
    l_inf = typemax(Int64)
    velocs = CartesianIndex.([0,1,0,-1],[1,0,-1,0])
    init_loc = CartesianIndex(size(data)[1]-1,2,1) #facest east
    endY, endX =  2, size(data)[2]-1
    goal_locs = CartesianIndex.(endY .* ones(Int64,4), endX .* ones(Int64,4), collect(1:4)) #can be facing any direction

    ldata = repeat(data,1,1,4)
    traversable = findall(==(0),ldata)

    distances = Dict(traversable .=> l_inf)
    distances[init_loc] = 0
    
    N = length(traversable)

    #mapping structure
    precursors = Dict(traversable .=> [Set{CartesianIndex{3}}() for i in 1:N])

    pq = PriorityQueue{CartesianIndex{3},Int64}()

    for d in traversable
        pq[d] = distances[d]
    end
    #let our space be 3 dimensional, where the 3rd dimension marks orientation.

    while !isempty(pq)
        currnode= dequeue!(pq)
        potential_neighbors = generate_neighbors(currnode)
        
        for np in potential_neighbors
            
            if haskey(pq,np)
                
                cost = np.I[3]==currnode.I[3] ? stepscore : turnscore
                cost += distances[currnode]

                if distances[np] >= cost
                    
                    
                    if distances[np] > cost
                        precursors[np] = Set{CartesianIndex{3}}()
                        
                    end

                    distances[np] = cost
                    
                    pq[np] = cost
                    push!(precursors[np],currnode)
                    
                
                end
            end
        end
        
    end
    return distances, precursors, goal_locs
end

function solve_p2(precursors,goal)
    path_nodes = Set{CartesianIndex{2}}()

    lstack = Stack{CartesianIndex{3}}()
    push!(lstack,goal)
    while !isempty(lstack)
        lnode = pop!(lstack)
        push!(path_nodes,CartesianIndex(lnode.I[1],lnode.I[2]))
        if lnode in keys(precursors) && !isempty(precursors[lnode])
            
            push!(lstack,precursors[lnode]...)
        end
    end
    return path_nodes
end

data = load_data()
d, precursors, goals = solve_p1(data)

distances = [d[key] for key in goals]
minkey = argmin(k -> d[k], goals)
sol_p1 = minimum(distances)

pres2 = solve_p2(precursors,minkey)
sol2 = length(pres2)