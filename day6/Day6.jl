using BenchmarkTools
using StaticArrays
using DataStructures

function data_load(path = "day6/day6input.txt")
    rows = readlines(path)
    N_y = length(rows)
    N_x = length(rows[1])
    outp = fill(Int8(0),N_x,N_y)
    lhash = Dict("#" => Int8(1), "."=> Int8(0))
    #technically this is the wrong way access memory, but ....
    for (i,row) ∈ enumerate(rows)
        res = get.(Ref(lhash),split(row,""),Int8(2))
       
        
        outp[i,:] .= res

    end
    sindex = findfirst(==(Int8(2)), outp)
    outp[sindex] = Int8(0)
    return outp, sindex.I
end

data, startIndex = data_load()

#guy initially faces upwards
#can access current 

function run_path(data,init_loc)
    #discrete integration using euler step?
    N_x, N_y = size(data)
    tracker = zero(data)
    veloc = SVector((-1,0))
    rotator = SMatrix{2,2}([0 1;
              -1 0]) #rotates 90 °   clockwise
    isoutside = (x,y)-> x > N_x || y > N_y || x < 1 || y < 1
    isvalid = (x,y) -> data[x,y] == Int8(0)
    
    #could use actual stacks
    posStack = Vector{typeof(veloc)}()
    velocStack = Vector{typeof(veloc)}()

    loc = SVector(init_loc)
    while true
        tracker[loc...] = 1
        push!(posStack, loc)
        push!(velocStack, veloc)
            
        proposed_location = loc + veloc
        if isoutside(proposed_location...)
            break
        elseif !(isvalid(proposed_location...))
            veloc = rotator * veloc # no need to step
        else
            loc = proposed_location
        end
    end
    return tracker, posStack, velocStack
end

function has_loop(data,init_loc, init_veloc)
    #discrete integration using euler step?
    N_x, N_y = size(data)
    
    veloc = init_veloc
    rotator = SMatrix{2,2}([0 1;
              -1 0]) #rotates 90 °   clockwise
    isoutside = (x,y)-> x > N_x || y > N_y || x < 1 || y < 1
    isvalid = (x,y) -> data[x,y] == Int8(0)
    
    U = typeof(veloc)
    hashlocveloc = Dict{U,Set{U}}()

    loc = SVector(init_loc)
    while true
        #could use a hash with expanding keys for this tbh.
        if loc ∈ keys(hashlocveloc)
            lset = hashlocveloc[loc]
            #check if current visited location is in vveloc Set
            if veloc ∈ lset 
                return true
            else
                push!(lset,veloc)
            end
        else
            #first time visiting
            hashlocveloc[loc] = Set{U}(Ref(veloc))
        end
            
        proposed_location = loc + veloc
        if isoutside(proposed_location...)
            break
        elseif !(isvalid(proposed_location...))
            veloc = rotator * veloc # no need to step
        else
            loc = proposed_location
        end
    end
    return false
end



res, locs, velocs = run_path(data,startIndex)
sol1 = sum(res)

# an "optimized" bruteforce 
# would *checking only indeces o n the traversed
#A single traversel (without tracking loops, ie. same pos and 
#same velocity) takes 10 μs. The guard traverses around 31% of the map,
#so this is bruteforcable. 


#Unoptimized:

function sum_loop_unopt(arena,path,path_veloc)
    
    init_loc = path[begin]
    init_veloc = path_veloc[begin]
    loopcount = 0
    U = eltype(path)
    insert_pos = Set{U}()
    for i in eachindex(path)[begin+1:end]
        local_pos = path[i]
        local_veloc = path_veloc[i]
        
        #check if inserting an obstacle would result in a loop
        larena = copy(arena)
        larena[local_pos...] = Int8(1)

        if !(local_pos in insert_pos)
            loopcount += has_loop(larena,init_loc,init_veloc)
        end
        push!(insert_pos,local_pos)
    end
    return loopcount
end

function sum_loop_opt(arena,path,path_veloc)
    
    loopcount = 0
    U = eltype(path)
    insert_pos = Set{U}()
    for i in eachindex(path)[begin+1:end]
        local_pos = path[i]
        
        #check if inserting an obstacle would result in a loop
        
        arena[local_pos...] = Int8(1)

        #we can check from just starting the previous location.... this cuts down times.

        if !(local_pos in insert_pos)
            loopcount += has_loop(arena,path[i-1],path_veloc[i-1])
        end
        arena[local_pos...] = Int8(0)
        push!(insert_pos,local_pos)
    end
    return loopcount
end



res2 = @btime sum_loop_unopt(data,locs,velocs)
res3 = @btime sum_loop_opt(data,locs,velocs)





