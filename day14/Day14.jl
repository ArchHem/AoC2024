
#positve x: to the right
#positive y: downward.

function load_data()
    #refex galore

    rows = readlines("day14/day14input.txt")
    N = length(rows)
    outp = zeros(Int,4,N)
    for (index,r) ∈ enumerate(rows)
        rmatches = collect(eachmatch(r"-?\d+",r))
        outp[:,index] .= parse.(Int64, getfield.(rmatches,:match))
    end
    return outp
end

data = load_data()
data[1:2,:] .+= 1

#it is not mentioned, but the last tile wraps back into the first.... 
arena0 = zeros(Int64,101,103)
arena = copy(arena0)

function fake_mod(x,u)
    #I do not think this function is generally correct.
    interm = mod(x,u)
    res = interm == 0 ? u : interm
    return res

end


function evolve_position!(posveloc, steps, arena = arena)
    Nx, Ny = size(arena)
    unbound_future = @. @views posveloc[1:2] + steps * posveloc[3:4]
    bound_future  = fake_mod.(unbound_future, [Nx, Ny])
    
    arena[bound_future[1],bound_future[2]] += 1
    return 
end

function apply_p1!(posvelocs, steps, arena = arena)

    N = size(posvelocs)[2]

    for i in 1:N
        input = @views posvelocs[:,i]
        evolve_position!(input,steps,arena)
    end
    return arena
end

function quadrant_summer(arena)
    Nx, Ny = size(arena)
    dx, dy = Nx % 2, Ny % 2
    N_x2, N_y2 = div(Nx,2), div(Ny,2)
    
    q1 = @views sum(arena[1:N_x2,1:N_y2])
    q2 = @views sum(arena[N_x2+1+dx:end,1:N_y2])
    q3 = @views sum(arena[1:N_x2,N_y2+1+dy:end])
    q4 = @views sum(arena[N_x2+1+dx:end,N_y2+1+dy:end])
    return q1*q2*q3*q4

end

res1 = apply_p1!(data,100,arena)
sol1 = quadrant_summer(arena)


#cant be bothered to write a checker: we can check for minimal spatial image entrioy.
using StatsBase
in_bounds(arr,idx::CartesianIndex) = all([idx[i] >= 1 && idx[i] <= size(arr,i) for i in eachindex(idx.I)])

function kernel_gen(arena,location,size)
    kernel = Vector{CartesianIndex{2}}([])
    for j in -size:size
        for i in -size:size
            local_loc = CartesianIndex(location.I .+ (i,j))
            if in_bounds(arena,local_loc)
                push!(kernel,local_loc)
            end
        end
    end
    return kernel
end

function kernel_entropy(arena, size = 1)

    entropy = 0.0
    for i in CartesianIndices(arena)
        lkernel = kernel_gen(arena,i,size)
        local_values = getindex.(Ref(arena),lkernel)
        freqs = countmap(local_values)
        norm = sum(values(freqs))
        for v in values(freqs)
            p = v/norm
            entropy -= p * log2(p)
        end
    end
    return entropy
end

using Plots


#this is a brutal overkill.... we could just use spread ox x-y frequencies or skewness
function entropy_checker(posvelocs,arena,size = 1, iternum = 1000)
    entropies = Vector{Float64}([])
    for i in 1:iternum
        println(i/iternum)
        local_arena = copy(arena)
        apply_p1!(posvelocs,i,local_arena)
        push!(entropies,kernel_entropy(local_arena,size))
    end
    return entropies
end

entropies = entropy_checker(copy(data),copy(arena0),2,10000)

test_arena = copy(arena0)
christmass_index = findmin(entropies)[2]

christmass_tree = apply_p1!(data,christmass_index,test_arena)





