using BenchmarkTools


function data_load()
    rows = readlines("day8/day8input.txt")
    N_x = length(rows)
    N_y = length(rows[1])
    
    result = Matrix{Char}(undef,N_x,N_y)
    for (index, row) ∈ enumerate(rows)
        
        result[index,:] = only.(split(row,""))
    end
    return result
end


const data = data_load()

#O(n)
function mapper(data = data, except = only("."))
    result = Dict{Char,Vector{CartesianIndex{2}}}()
    for j in axes(data,2)
        for i in axes(data,1)
            elem = data[i,j]
            if elem != except
                if !haskey(result,elem)
                    result[elem] = [CartesianIndex(i,j)]
                else
                    push!(result[elem],CartesianIndex(i,j))
                end
            end
        end
    end
    return result
end

const access = mapper()

#no eachindex() implemented...
in_bounds(arr,idx::CartesianIndex) = all([idx[i] >= 1 && idx[i] <= size(arr,i) for i in eachindex(idx.I)])

#nasty piracy

Base.transpose(x::CartesianIndex{N}) where N = x

#for each unique pair within these sets, we want the antinodes: (i1,j1), (i2,j2) -> d = (i1-i2,j1-j2)

# and (i1,j1) +/- d are the actual antinodes. Perform a check, and add into a storage grid if its valid.

#To vectorize the OP: V = [(i1,i2), (i2,i3)]......
#diffMatrix = V - V^T -> then the possible antinodes are located at diffMatrix + V's every offdiagonal element will yield the position of the antinodes

function set_antinode_locs(data = data, access = access)
    
    outp = Set{CartesianIndex{2}}()
    for key in keys(access)
        lvec = access[key]
        
        diffMatrix = lvec .- transpose(lvec)
        added_ver = diffMatrix .+ lvec
        
        for j in axes(added_ver,2)
            for i in axes(added_ver,1)
                
                 if i != j && in_bounds(data, added_ver[i,j])
                    
                    push!(outp,added_ver[i,j])
                end
            end
        end

    end
    return outp
end

outp_set = set_antinode_locs()
sol1 = length(outp_set)

#for part 2, we need to check if ANY element of diffmatrix * N + V is still inside the OG matrix or not. 
#this can be done using 2x while loops and using any()

#However, this might get expensive pretty fast. A simple trple inner loops is likely to be MUCH faster as it can truncate 
#out-of-bounds acess attempts much faster

function set_antinode_lines(data = data, access = access)
    
    outp = Set{CartesianIndex{2}}()
    for key in keys(access)
        lvec = access[key]
        N = length(lvec)
        for i in eachindex(lvec)
            for j in i+1:N
                ldiff = @views lvec[i]-lvec[j]
                lloc1 = lvec[i]
                lloc2 = lvec[i]
                
                push!(outp,lloc1)
                
                #"positive" direction
                while in_bounds(data,lloc1)
                    
                    push!(outp,lloc1)
                    lloc1 = lloc1 + ldiff
                    
                end
                

                while in_bounds(data,lloc2)
                    push!(outp,lloc2)
                    lloc2 = lloc2 - ldiff
                    
                end
                


            end
        end

    end
    return outp
end

outp_set2 = set_antinode_lines()
sol2 = length(outp_set2)


