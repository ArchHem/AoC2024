using BenchmarkTools
using DataStructures
using Graphs
using Plots, GraphRecipes

#The input is a fully connected, directed graph; this can be verified 

function data_loader(T::Type{<:Integer} = Int32)
    #could use actual stacks....
    stack1, stack2 = Vector{T}([]), Vector{T}([])
    stack3 = Vector{Vector{T}}([])

    #we will need to switch when we encounter an empty node
    rows = readlines("day5/day5input.txt")
    reg = r"\d+"
    passed = false
    for (i,row) ∈ enumerate(rows)
        if length(row) == 0
            passed = true
            continue
        end
        if !passed
            valids = collect(eachmatch(reg,row))
            values = parse.(T,getfield.(valids,:match))
            push!(stack1,values[1])
            push!(stack2,values[2])
        else
            valids = collect(eachmatch(reg,row))
            values = parse.(T,getfield.(valids,:match))
            push!(stack3,values)
        end

    end
    return stack1, stack2, stack3

end

function get_middle_elem(x)
    N = length(x)
    return @views x[N ÷ 2 + 1]
end


#X | Y implies that X must come BEFORE Y
#We can create a datastructure that allows for quick access for each number and before which one they must occur.
#This is a hash-of-sets.

#The creation of is it follows

function create_access(x1::T, x2::T) where T
    inputs = Set(x1) #create set of uniqe elements in x1 ) O(n)
    u = eltype(x2)
    outp = Dict{u,Set{u}}()
    for elem ∈ inputs #O(n^2) :(
        bindex = elem .== x1
        values = Set(x2[bindex])
        outp[elem] = values
    end
    #the following returns the set of elements that CAN NOT occur after the key it was called on.
    return outp
end

#we Aim to buil d a function taht given input A and B return TRUE if A < B. In other words, 
#A MUST occur before B. This can be achieved by the above tool. For key A it returns the value of B before it MUST occur.
#Note that this is not true (we could have A|B A|C C|D which implies A|D), 
#but every element will be indirectly compared until such is resolved so its a not problem. (Prove this?)

#The data only includes 49 unique elements and all the rules that need to imply their order.
x1, x2, sequences = data_loader(Int32)
const hash_of_sets1 = create_access(x1,x2)
custom_is_less = (e1, e2) -> e2 ∈ hash_of_sets1[e1]

bs1 = issorted.(sequences, lt = custom_is_less)
result_1_comp = sum(get_middle_elem.(sequences[bs1]))
result_2_comp = sum(get_middle_elem.(sort.(sequences[.~bs1], lt = custom_is_less)))

#For part 2 and 1 instead we can use graphs.

function build_graph(x1::T,x2::T) where T
    @assert length(x1) == length(x2)
    
    d1 = Set(x1)
    d2 = Set(x2)   
    #Paranoid unions - these can be skipped most likely.
    
    all_uniques = union(d1,d2)
    number_of_vertices = length(all_uniques)
    
    hash1 = Dict([(value, index) for (index, value) in enumerate(all_uniques)])
    hash2 = Dict([(hash1[key], key) for key in keys(hash1)])
    #hash1 associates each key : value with its index in the graph, hash2 the other way around
    u = eltype(x1)
    result = DiGraph{u}(number_of_vertices)
    
    for i ∈ eachindex(x1)
        
        add_edge!(result,hash1[x1[i]],hash1[x2[i]])
        
    end
    #cheeky input: this leaves us with a (perfect) circle.
    ind = topological_sort(transitivereduction(result))
    

    return ind, hash1, hash2
    
end

function input_filter(sequence,x1,x2)
    setofinputs = Set(sequence)
    filter1 = x1 .∈ Ref(setofinputs)
    filter2 = x2 .∈ Ref(setofinputs)
    #Why is this an and not a ||? This could be not guaranteed per the descriptipn
    total_filter = filter1 .&& filter2
    return @views x1[total_filter], @views x2[total_filter]
end

function combined_sorter(sequence,x1,x2)
    lx1, lx2 = input_filter(sequence,x1,x2)
    sorted_ind, hash1, hash2 = build_graph(lx1,lx2)
    
    hash3 = Dict([(value, index) for (index,value) in enumerate(sorted_ind)])
    return sorted_ind, hash1, hash2, hash3
end

function sort_seq(sequence, x1, x2)
    ind, h1, h2, h3 = combined_sorter(sequence,x1,x2)
    #se hashes to associate with old indeces
    #value -> graph id -> index within sorted array
    local_isless = (e1,e2) -> h3[h1[e1]] < h3[h1[e2]]
    return sort(sequence,lt = local_isless)
end

function is_sorted_seq(sequence, x1, x2)
    ind, h1, h2, h3 = combined_sorter(sequence,x1,x2)
    #se hashes to associate with old indeces
    #value -> graph id -> index within sorted array
    local_isless = (e1,e2) -> h3[h1[e1]] < h3[h1[e2]]
    return issorted(sequence,lt = local_isless)
end

#eg
#g, h1, h2 = combined_sorter(sequences[1],x1,x2)
#We can use this for part 1 easily., via reverseving the hash.
#In fact, we can use a custom less_than function to do the two exercises at once

#Part1

b1 = is_sorted_seq.(sequences,Ref(x1),Ref(x2))
sol_1 = sum(get_middle_elem.(sequences[b1]))
sol_2 = sum(get_middle_elem.(sort_seq.(sequences[.~b1],Ref(x1),Ref(x2))))