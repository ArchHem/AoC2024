using BenchmarkTools
using DataStructures

#This seems like a defrag question? We can use some kind of abstract repr. or bucketing

ListNode = DataStructures.ListNode

mutable struct chunk{T<:Integer} 
    id::Union{T,Nothing}
    length::T
end

chunk(id::U,l::T) where {T,U} = chunk{T}(id,l)
Base.show(io::IO, x::chunk) = println(io, "L: $(x.length), ID: $(x.id)")
#best managed via doubly linked list.
function data_loader(T::Type{<:Integer} = Int64)
    row = readline("day9/day9input.txt")
    row = split(row,"")
    
    ls = parse.(T,row)
    result = Vector{chunk{T}}()
    for i in eachindex(ls)
        u = i - 1
        id = u % 2 == 0 ? div(u,2) : nothing
        l = ls[i]
        push!(result,chunk(id,l))
    end
    #L = sum(getfield.(result,:length))
    result = MutableLinkedList{chunk{Int64}}(result...)
    return result
    

end

#
function insert_after!(x::ListNode, y::ListNode)
    x_next = x.next
    x.next = y
    y.prev = x
    y.next = x_next
    x_next.prev = y
    return x
end


#O(n)
function defrag(data = data)
    #use 2 pointer technique
    
    head = data.node
    
    T = typeof(head.next.data.length)
    
    lpointer = head.next.next
    lcounter = 1
    
    rpointer = head.prev
    rcounter = length(data)

    #we have 3 cases:

    #Current end-node fits into the cache perfectly. Move both pointers, swap their occupancy. 
    #Current end-node does not fit entirely into cache hole. Move left pointer, update "length" of right node, insert zero chunk next to it.
    #Current end-node undefits the cache hole. Create a new cache hole right of the current one, move left pointer there.

    
    while rcounter > lcounter
        
        if lpointer.data.length == rpointer.data.length
            
            #swap node id's
            lpointer.data.id, rpointer.data.id = rpointer.data.id, lpointer.data.id
            #move pointers.
            lcounter += 2
            rcounter -= 2
            lpointer = lpointer.next.next
            rpointer = rpointer.prev.prev
            


        elseif lpointer.data.length < rpointer.data.length
            
            #case when does not fit into chunk
            lpointer.data.id = rpointer.data.id
            L1 = rpointer.data.length
            L2 = lpointer.data.length
            cache_diff = L1 - L2
            rpointer.data.length = cache_diff
            insert_after!(rpointer,ListNode{chunk{T}}(chunk(nothing,cache_diff)))

            lcounter += 2
            lpointer = lpointer.next.next

            #We need not move the right pointer. 
        elseif lpointer.data.length > rpointer.data.length
            
            id_right = rpointer.data.id
            id_left = lpointer.data.id
            lpointer.data.id = id_right
            rpointer.data.id = id_left
            L1 = rpointer.data.length
            L2 = lpointer.data.length
            cache_diff = L2 - L1 #leftover cache
            lpointer.data.length = L1
            insert_after!(lpointer,ListNode{chunk{T}}(chunk(nothing,cache_diff)))
            lcounter += 1
            lpointer = lpointer.next

            rcounter -= 1
            rpointer = rpointer.prev.prev
        end

    end

    #now, we can simplify the last chunk into once single one; this could be done even during the run

    return head

end

#specialiyed... not general
function deep_copy(list)

    array = [elem for elem ∈ list]
    new_arr = [chunk(elem.id, elem.length) for elem ∈ array]
    res = MutableLinkedList{chunk{Int64}}(new_arr...)
    return res

end

data = data_loader()

res = defrag(deep_copy(data))

function checkSum(x)
    head = x.next
    currid = 0
    sum_local = 0
    
    while !(isnothing(head.data.id))
        saindex = currid
        enindex = currid + head.data.length - 1
        
        range_of_indeces = saindex:enindex
        
        if head.data.length > 0
            sum_local += sum(range_of_indeces .* head.data.id)
        end
        
        currid = enindex + 1
        head = head.next
    end

    return sum_local
        
end



res1 = checkSum(res)

function bForce_p2(data)
    
    rpoint = data.node.prev  # Start from the rightmost node (largest ID)
    lpoint_reference = data.node.next  # First real node (leftmost hole)
    
    N = length(data)  
    remaining_chunks = N

    # Iterate through the list, starting from the rightmost chunk
    while remaining_chunks > 1
        # Skip unused nodes on the right
        if isnothing(rpoint.data.id)
            rpoint = rpoint.prev
            remaining_chunks -= 1
            continue
        end

        
        curr_length = rpoint.data.length
        left_ptr = lpoint_reference  # Reset left pointer to leftmost hole
        left_index = 1

        
        while left_index < remaining_chunks
            
            if !isnothing(left_ptr.data.id)
                left_ptr = left_ptr.next
                left_index += 1
                continue
            end

            
            if left_ptr.data.length == curr_length
                left_ptr.data.id, rpoint.data.id = rpoint.data.id, nothing
                break

            #eft hole is larger than needed
            elseif left_ptr.data.length > curr_length
                left_ptr.data.id = rpoint.data.id
                rpoint.data.id = nothing
                
                leftover_length = left_ptr.data.length - curr_length
                left_ptr.data.length = curr_length
                insert_after!(left_ptr, ListNode{chunk{Int64}}(chunk(nothing, leftover_length)))
                remaining_chunks += 1
                break
            end

            
            left_ptr = left_ptr.next
            left_index += 1
        end

        
        rpoint = rpoint.prev
        remaining_chunks -= 1
    end
    return data
end


function checksum_2(solution)
    head = solution.node.next
    currid = 0
    sum_local = 0

    counter = 1
    N = length(solution)
    while counter <= N
        
        saindex = currid
        enindex = currid + head.data.length - 1
        
        range_of_indeces = saindex:enindex
        
        if !isnothing(head.data.id)
            sum_local += sum(range_of_indeces .* head.data.id)
        end
        
        currid = enindex + 1
        head = head.next
        counter += 1
    end

    return sum_local
end

sol2 = bForce_p2(deep_copy(data))
csum2 = checksum_2(sol2)


#optimized solution uses buckets of heaps, which track keep of leftmost nodes in each category.
#Alternative to look into: AVL


println("Done")
