using CSV
using DataFrames
using DataStructures
using BenchmarkTools

data = CSV.read("day1/day1input.txt", DataFrame; header = false, delim = "   ")
rename!(data,[:l1,:l2])



l1 = data[!,:l1]
l2 = data[!,:l2]

function count_distance(x::T,y::T) where T
    heap1 = BinaryMinHeap(x)
    heap2 = BinaryMinHeap(y)
    sum = 0
    while length(heap1) > 0
        p1 = pop!(heap1)
        p2 = pop!(heap2)
        dist = abs(p1-p2)
        sum += dist
    end
    return sum
end

function sort_counter(x::T,y::T) where T
    xs = sort(x)
    ys = sort(y)

    dist = sum(abs.(xs .- ys))
    return dist
end

#part 1
res1 = count_distance(l1,l2)
res2 = sort_counter(l1,l2)
#part 2

#this is basically building a frequency table of the left and right tabels


function freq_solution(l1::T,l2::T) where T
    left_dict = Dict()
    right_dict = Dict()

    #O(n)
    for elem ∈ l1
        if elem ∈ keys(left_dict)
            left_dict[elem] += 1
        else
            left_dict[elem] = 1
        end
    end

    for elem ∈ l2
        # we could even speed up more by NOT hashing stuff that is not 
        #present in left dict in case we dont need to check later
        if elem ∈ keys(right_dict)
            right_dict[elem] += 1
        else
            right_dict[elem] = 1
        end
    end

    #Now, traverse and count
    lsum = 0
    for key ∈ keys(left_dict)
        
        if key ∈ keys(right_dict)

            elem = key
            lcount = left_dict[key]
            rcount = right_dict[key]
            lsum += elem * lcount * rcount
        end 

    end

    return lsum
end
sim_score = freq_solution(l1,l2)