using DataStructures

function load_data()
    init = read("day15/day15input.txt",String)
    
    grid, instr = split(init,r"\n\s*\n")
    grid_rows = split(grid,r"\n")
    N_y = length(grid_rows)
    N_x = length(grid_rows[1])
    arena_res = Matrix{Char}(undef,N_y,N_x)
    for (index,r) in enumerate(grid_rows)
        
        arena_res[index,:] .= only.(split(r,""))
    end
    instr = replace(instr, r"\n" => "")
    instr = split(instr,"")
    ldict = Dict("^"=>CartesianIndex(-1,0),"v"=>CartesianIndex(1,0),">" => CartesianIndex(0,1), "<" => CartesianIndex(0,-1))

    operations = getindex.(Ref(ldict),instr)

    #now process the arena into numerical format.
    gridDict = Dict('.'=> 0, '#'=>2, 'O' => 1,'@'=>-1)
    
    grid = getindex.(Ref(gridDict),arena_res)

    return grid, operations
end

grid, operations  = load_data()

function attempt_move(direction,location,arena)
    if arena[location + direction] == 0
        #pushable location
        return location + direction
    elseif arena[location + direction] == 2
        return false
    else
        return attempt_move(direction, location+direction,arena)
    end
end

function execute_move!(direction,endindex, location, arena)
    #push everything along direction to end index (which is empty)
    diry, dirx = direction.I
    y1, x1 = location.I
    y2, x2 = endindex.I
    dy = sign(y2-y1) == 0 ? 1 : sign(y2-y1)
    dx = sign(x2-x1) == 0 ? 1 : sign(x2-x1)
    to_replace = CartesianIndex.((y1+diry):dy:y2,(x1+dirx):dx:x2)
    replacer = CartesianIndex.(y1:dy:(y2-diry),x1:dx:(x2-dirx))
    arena[to_replace] .= arena[replacer]
    arena[location] = 0
    return location + direction
end

function solve_p1!(arena,operations)
    loc = findfirst(==(-1),arena)
    
    for op in operations
        bl = attempt_move(op,loc,arena)
        if bl != false
            loc = execute_move!(op,bl,loc,arena)
        end
    end
    return arena
end

resp1 = solve_p1!(copy(grid),operations)

function calc_p1(sol1)
    lsum = 0
    boxlocs = findall(==(1),sol1)
    
    for l in boxlocs
        y,x = l.I 
        lsum += (y-1)*100 + (x-1)
    end
    return lsum
end

sol1 = calc_p1(resp1)

const translation_dict = Dict(0=>0, 2=>2, 1 =>1, -1 => 0)
function turn_into_p2(arena)
    Ny,Nx = size(arena)
    outp = zeros(Int64,Ny,2Nx)
    bindings = zeros(Int64,Ny,2Nx)
    for i in 1:Nx
        outp[:,2i-1] .= @views arena[:,i]
        outp[:,2i] .= getindex.(Ref(translation_dict), @view arena[:,i])
        @. bindings[:,2i-1] = ifelse(arena[:,i] == 1,1,0)
        @. bindings[:,2i] = ifelse(arena[:,i] == 1,-1,0)
    end

    return outp, bindings
end

#use BFS to check if entire thing can be moved

function is_movable_p2(direction,location,arena,bindings, final_to_move = Deque{CartesianIndex{2}}())
    visited = Set{CartesianIndex{2}}()
    if direction.I[1] == 0
        #horizontal, easy
        if arena[location + direction] == 0
            push!(final_to_move,location)
            return final_to_move
        elseif arena[location + direction] == 2
            return false
        else
            push!(final_to_move,location)
            return is_movable_p2(direction, location+direction,arena,bindings, final_to_move)
        end

    else
        #shitty BFS
        attempted_locs = Deque{CartesianIndex{2}}()
        
        push!(attempted_locs,location + direction)
        push!(final_to_move,location)
        
        while !isempty(attempted_locs)
            
            currloc = popfirst!(attempted_locs)
            
            if arena[currloc] == 2
                return false
            elseif arena[currloc] == 0
                #if its empty it means that it MIGHT be possible to push up the stack.
                continue

            else
                #this is a box. to make sure to mark as visited.
                

                if currloc in visited
                    continue
                end
                push!(final_to_move,currloc)

                push!(visited,currloc)

                bound_index = CartesianIndex(currloc.I[1],currloc.I[2] + bindings[currloc])
                
                
                
                pushfirst!(attempted_locs,bound_index) #we want that the bound index to be evaluated IMMIDATETLY!!!
                push!(attempted_locs,currloc + direction)
                
                
            end

        end
        return final_to_move
    end
end

function solve_p2!(grid, bindings, operations)

    loc = findfirst(==(-1),grid)
    for op in operations
        
        bl = is_movable_p2(op,loc,grid,bindings)
        if bl != false
            
            loc = loc + op
            #this means BL is a stack of things we need to move.
            while !isempty(bl)
                currloc = pop!(bl)
                bindings[currloc + op] = @views bindings[currloc]
                grid[currloc + op] = @views grid[currloc]

                bindings[currloc] = 0
                grid[currloc] = 0
            end
        end
    end
    return grid, bindings


end

function get_point_p2(binding)
    leftedges = findall(==(1),binding)
    lsum = 0
    for l in leftedges
        y,x = l.I 
        lsum += (y-1)*100 + (x-1)
    end
    return lsum
    
    #determine mininum distance to vertical edges of the box
end


grid_p2, binder_p2 = turn_into_p2(grid)
fgrid, fbinding = solve_p2!(copy(grid_p2),copy(binder_p2),operations)
sol2 = get_point_p2(fbinding)
