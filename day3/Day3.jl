using BenchmarkTools

function data_loader()
    lfile = readlines("day3/day3input.txt")
    res = join(lfile)
    return res
end

#a valid multiplication instruction looks like mul(num1,num2) where num2 are integers.

#first time regex user...

data = data_loader()

function evaluator(data,T::Type{U}) where U <:Integer
    reg = r"mul\(\d+,\d+\)"
    #these two are for sub-string matching
    lreg1 = r"\(\d+"
    lreg2 = r"\d+\)"

    valids = eachmatch(reg,data) #this is an iterator of all regex matches.
    #pre-allocation would be much better; we dont know length of iterator.
    nums1 = Array{T}([])
    nums2 = Array{T}([])
    for elem ∈ valids
        lstring = elem.match
        num1 = match(lreg1,lstring).match
        num2 = match(lreg2,lstring).match
        push!(nums1,parse(T,num1[2:end]))
        push!(nums2,parse(T,num2[1:end-1]))
    end
    return nums1, nums2
end

#for the second part, we are only interested in parts of the strings that lie between do() and don't() 
#this can achieved via string slicing the "dont" domains
#if the last such identified object is dont, exclude the rest of the domain

function get_valid_substring(data)
    doreg = r"do\(\)"
    dontreg = r"don\'t\(\)"

    l1 = 4

    v1 = eachmatch(doreg,data)
    v2 = eachmatch(dontreg,data)

    do_start = Array{Int64}([])
    dont_start = Array{Int64}([])

    for elem ∈ v1
        push!(do_start,elem.offset)
    end

    for elem ∈ v2
        push!(dont_start,elem.offset)
    end

    is_valid = trues(length(data))
    primdex = 1
    end_index = 1
    N = length(data)
    ldata = split(data,"")
    
    
    for value ∈ dont_start
        
        start_index = value
        if start_index > end_index
            local_arr = @views do_start[primdex:end]
            local_index = findfirst(x -> x > start_index,  local_arr)
           
            end_index = isnothing(local_index) ? N : local_arr[local_index] + l1 - 1
            is_valid[start_index:end_index] .= false
            primdex += 1
            
        end
    end

    ldata = join(ldata[is_valid])


    return ldata

    #now, the problem becomes one of intervals...
end

function alt_regex(data)
    ldata = data*"do()"
    
    lregex = r"(?<=don't\(\))(.*?)(?=do\(\))"
    regmatch = eachmatch(lregex,ldata)
    result = join([elem.match for elem ∈ regmatch])
    return result
end

num1, num2 = evaluator(data,Int64)
result = sum(num1 .* num2)

newnum1, newnum2 = evaluator(get_valid_substring(data),Int64)
newres = sum(newnum1 .* newnum2)

rnum1, rnum2 = evaluator(alt_regex(data),Int64)
negative_result = sum(rnum1 .* rnum2)

actual_result = result - negative_result

