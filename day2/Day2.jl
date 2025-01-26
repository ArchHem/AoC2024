using CSV
using DataFrames
using DataStructures
using BenchmarkTools

function data_loader(path)
    lfile = readlines(path)
    lparse(x) = parse.(Int64,x)
    res = map(lparse, split.(lfile," "))
    return res
end

#data = data_loader("day2/scott_input.txt")
data = data_loader("day2/day2input.txt")

is_valid_l(x) = begin u = abs(x)
    res = u <= 3 & u >= 1 ? true : false
    return res
end

#a solution is valid if within allocated difference and is strictly increasing or decreasing

function is_valid_v(x)
    #"vectorized" check; always executes N operations

    checker = @views x[2:end] .- x[1:end-1]
    signs = sign.(checker)
    #could be done "more" efficently on average, but same O(n) scaling
    numsigns = length(Set(signs))
    
    if numsigns > 1
        return false
    end

    validities = is_valid_l.(checker)

    return all(validities)

end

function is_valid_t(x)
    #explicit traversion - runs, on average, less steps but might still be slower (SIMD....)
    #also uses less memory and is non-allocating....
    x1 = x[1]

    #initalize
    prev_sign = sign(x[2]-x[1])

    for i in 2:length(x)
        x2 = x[i]
        
        diff = x2 - x1
        v1 = is_valid_l(diff)
        lsign = sign(diff)
        v2 = lsign == prev_sign
        
        if !(v1 & v2)
            return false
        
        end
        x1 = x2

    end
    return true

end

results1 = is_valid_v.(data)
results2 = is_valid_t.(data)

num_of_valids1 = sum(results1)
num_of_valids2 = sum(results2)

#We are now allowed to remove a single "bad" instance to fix the reactor. This is hard to implement 
#in a vectorized manner.

function cut_valid(array, index_to_check)
    N = length(array)
    bindex = trues(N)
    bindex[index_to_check] = false
    subarr = @views array[bindex]
    res = is_valid_t(subarr)
    return res
end

function damp_is_valid(x)
    
    #two unfortunate edge cases cases occur if removing the first or last node would fix the array
    #we can "fix" this by checking if deleting the current elemnt or its neighbor would fix the neighboorhood

    #this still demands a manual check for the first node

    if cut_valid(x,1)
        return true
    end
    
    x1 = x[1]

    #initalize
    prev_sign = sign(x[2]-x[1])

    for i in 2:length(x)
        x2 = x[i]
        
        diff = x2 - x1
        v1 = is_valid_l(diff)
        lsign = sign(diff)
        v2 = lsign == prev_sign
        x1 = x2
        if !(v1 & v2)
            #we may be exploit locality, somehow; rerunning on the array again is bad, 
            #but sinc eit can happen only once, the algo remains O(n)

            #a local check would ehck a 4 neighboorhood; if it find thats the resulting subarray is valid,
            #it would proceed this loop but without the posibility of further deletions
            
            
            lres1 = cut_valid(x,i)
            
            lres2 = cut_valid(x,i-1)
            
            #if either of these removals fixes the arrays;

            return lres1 | lres2
            
            
        
        end
        

    end
    return true

end

    
results3 = damp_is_valid.(data)
num_of_valids3 = sum(results3)
















