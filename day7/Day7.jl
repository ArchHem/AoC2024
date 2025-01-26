using BenchmarkTools
using DataStructures

function data_load(T::Type{<:Integer} = Int64)
    path = "day7/day7input.txt"
    rows = readlines(path)
    outp1 = Vector{T}()
    outp2 = Vector{Vector{T}}()
    for (i,row) ∈ enumerate(rows)
        f1, f2 = split(row,": ")
        
        res1 = parse(T,f1)
        
        res2 = split(f2," ")
        
        strs = parse.(T,res2)


        
        
        push!(outp1,res1)
        push!(outp2,strs)
    end
    return outp1, outp2
end

starts, inputs = data_load()

#A brute force approach needs to check for 2^(N-1) operation-vectors
#It can be implemented using recursion

#A way to reduce complexity is to check some "predictor" of the operation, such as last digits or divisibility ops. 

#In the bellow function, the dic element is a function f(target,last_element_of_array) 
#these functions return TRUE if this pair is possibly valid. 

conc(x::T,y::T) where T <:Integer = parse(T,string(x,y))
invconc(x::T,y::T) where T <:Integer = begin
    last_digits = floor(T,log10(y)) + 1
    result = x ÷ 10^last_digits
    return result
end

lvalid(x::T,y::T) where T <:Integer = x % 10 == y % 10

const invDict = Dict(:* => (x,a) ->  x%a == zero(x), :+ => (x,a) ->  x  > a, :c => (x,y) -> conc(invconc(x,y),y) == x)

function is_valid_p1(target::T,array) where T
    if length(array) == 1
        return target == @views array[begin]
    end

    endstate = @views array[end]

    cond1 = invDict[:+](target, endstate)
    cond2 = invDict[:*](target, endstate)

    state1, state2 = false, false
    s  = @views array[begin:end-1]
    if cond1
        
        state1 = is_valid_p1(target - endstate, s)
    end
    if cond2
        
        state2 = is_valid_p1(target ÷ endstate, s)
    end

    return state1 || state2
    
end

function is_valid_p2(target::T,array) where T
    if length(array) == 1
        return target == @views array[begin]
    end

    endstate = @views array[end]

    cond1 = invDict[:+](target, endstate)
    cond2 = invDict[:*](target, endstate)
    cond3 = lvalid(target, endstate) && invDict[:c](target, endstate)

    state1, state2, state3 = false, false, false
    s  = @views array[begin:end-1]
    if cond1
        
        state1 = is_valid_p2(target - endstate, s)
    end

    if cond2
        
        state2 = is_valid_p2(target ÷ endstate, s)
    end

    if cond3
        
        state3 = is_valid_p2(invconc(target,endstate), s)
    end
    
    return state1 || state2 || state3
    
end

b_p1 = is_valid_p1.(starts,inputs)
res_p1 = sum(starts[b_p1])

b_p2 = is_valid_p2.(starts,inputs)
res_p2 = sum(starts[b_p2])




