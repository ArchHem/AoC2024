using StaticArrays
using DataStructures

#For p2, for each lock (or keys, depending on counts) for each column, store how many columns we have that are larger than k:
#This avoid iterating every key at every step.

function load_data(N_x::T = 5,N_y::T = 7) where T<:Integer
    input = read("day25/day25input.txt", String)
    basehash = Dict('.' => 0, '#' => 1)
    input_chunks = split(input,r"\n\n")
    keys = SVector{N_x,Int64}[]
    locks = SVector{N_x,Int64}[]
    
    for chunk in input_chunks
        
        numeric_ = getindex.(Ref(basehash), collect(replace(chunk,"\n" =>"")))
        numeric_ = permutedims(reshape(numeric_, N_x, N_y),(2,1,))
        
        numeric_ = SMatrix{N_y,N_x}(numeric_)
        #not correct memory order... 

        fr, lr = numeric_[1,:],numeric_[end,:]
        
        if sum(fr) > sum(lr)
            
            #we store how many 
            colsums = sum(numeric_, dims = 1)
            push!(locks, colsums)
            
        else
            
            colsums = sum(numeric_, dims = 1)
            push!(keys, colsums)
            
        end

        #we eql. amounts of keys and locks

    end

    return keys, locks
end

function solve_p1_brute()
    keys, locks= load_data()

    #every key and lock is uniqe, but we could could Set() explictly to enforce it anyway.
    #Maybe this can be computed explicily from the registries instead?
    #O(n^2).... not good, is there a better way?

    #we could perhaps store the locks in a radix-sort like structure, eg. a struct(i, k) where:

    #For the i-th index it has a pointer to every lock that has at most k height in index i -> no O() speedup

    #Realistically, what we need would look like this:

    #A function (oracle) F that tells how many locks fit a given key in O(1) or O(log(n)) time, I dont see how this can be done

    res1 = 0
    for k in keys
        for l in locks
            #all keys are 7 height
            if all(k .+ l .< 8)
                res1 += 1
            end
        end
    end
    return res1
end

sol1 = solve_p1_brute()