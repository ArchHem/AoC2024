using BenchmarkTools



function load_data()
    rows = readlines("Day4/day4input.txt")
    #pre-allocate
    #for ease of usage, this function casts the input to a matrix of symbols
    N_x = length(rows[1])
    N_y = length(rows)
    result = fill(:NA,N_y,N_x)
    for (index, row) ∈ enumerate(rows)
        result[index,:] .= Symbol.(collect(row))
    end
    return result
end


const data = load_data()
const guide_sym = [:X, :M, :A, :S]

#the algorthm proceeds as follows
#it iterates thru the entire array i, j
#at each index it determines which could be valid directions based on edge cases (too close to edge boundarz, etc).
#check all directions using CartesianIndeces for a valid string
#adds one to a counter for each found

function is_inside(N_y, N_x, j, i)
    b1 = 0 < j && N_y >= j 
    b2 = 0 < i && N_x >= i
    return b1 && b2
end

function determine_directions(N_y,N_x,j,i,L)
    
    
    is_valid = trues(3,3)
    iterlength = L - 1
    
    results = fill(CartesianIndex.(i:i,j:j),3,3)
    #Giving the loop unroller a day off
    for j_l in -1:1
        for i_l in -1:1
            lbool = is_inside(N_y,N_x,j + j_l * iterlength, i + i_l * iterlength)
            is_valid[i_l + 2, j_l + 2] = lbool
            if lbool
                istep = i_l > 0 ? 1 : -1
                jstep = j_l > 0 ? 1 : -1
                irange = i:istep:i+i_l*iterlength
                jrange = j:jstep:j+j_l*iterlength
                results[i_l + 2 , j_l + 2] = CartesianIndex.(irange,jrange)
                
            end
        end

    end
    is_valid[2,2] = false #we can never "stay" in one place (perhaps if L was one....)
    return results, is_valid


end

function count_xmas(data = data, vec_of_symbs = guide_sym)
    found = 0
    L = length(vec_of_symbs)
    
    start_sym = vec_of_symbs[1]
    N_x, N_y = size(data)
    #loop galore
    for j in 1:N_x
        for i in 1:N_y
            if data[i,j] == start_sym
                local_indeces, local_bools = determine_directions(N_y,N_x,j,i,L)

                for index ∈ eachindex(local_indeces,local_bools)
                    
                    if local_bools[index]
                        local_index = local_indeces[index]
                        candidate = @views data[local_index]
                        if candidate == vec_of_symbs
                            found += 1
                        end
                        
                    end
                end
                
            end
        end
    end

    return found

end

count_first = count_xmas()

#Part 2

#This is actually easier, as we need not check for the edge cases

MAS = [:M, :A, :S]

function MAS_kernel(i,j)
    #this can be hardcoded
    #this is pretty much writing diagonal kernels
    i1 = CartesianIndex.((i-1):1:(i+1),(j-1):1:(j+1))
    i2 = CartesianIndex.((i+1):-1:(i-1),(j-1):1:(j+1))
    i3 = CartesianIndex.((i+1):-1:(i-1),(j+1):-1:(j-1))
    i4 = CartesianIndex.((i-1):1:(i+1),(j+1):-1:(j-1))
    #it could be generated similarly to the above example
    return (i1,i2,i3,i4)

end

function MAS_counter(data = data, target = :A, target_symbols = MAS)
    occ = 0
    N_x, N_y = size(data)
    for j in 2:N_y-1
        for i in 2:N_x-1
            
            if data[i,j] == target
                lsum = 0
                indeces = MAS_kernel(i,j)
                #if we want every last bit of perfromace, this loop can be terminated when we cross 2.
                #Another perfroamce boost would be to only generate 2 pair of cartesianindeces, get the 
                #symbol-vectors and check their reverse; this would have better locality (?)
                for index in indeces
                    candidate = @views data[index]
                    lsum += candidate == target_symbols
                end
                #geometry dictates that ONLY 2 matches are whats considered valid. (word is not symmetric)
                occ += lsum == 2
            end
        end
    end
    return occ
end

final_count = MAS_counter()