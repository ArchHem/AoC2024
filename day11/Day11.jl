using DataStructures
using Memoize
using BenchmarkTools

function data_loader()
    input = readline("day11/day11input.txt")
    
    numbers = split(input, " ")
    result = parse.(Int64,numbers)
    return result
end

#order of elements does NOt matter, we can use dict to abtract it away.

@memoize function update(x::Integer)
    if x== 0
        return [1]
        
    elseif ndigits(x) % 2 == 0
        divisor = 10^div(ndigits(x),2)
        last_digits = x % divisor
        first_digits = div(x-last_digits,divisor)
        
        return [first_digits,last_digits]
    else
        return [2024 * x]
    end
end

function build_freq(x,dict = Dict{Int64,Int64}())
    for elem ∈ x
        if !(elem in keys(dict))
            dict[elem] = 1
        else
            dict[elem] += 1
        end
    end
    return dict
end

function blink_f(dict)
    newdict = Dict{Int64,Int64}()
    for key in keys(dict)
        n = dict[key]
        new_elems = update(key)
        #hope this gets unrolled....
        for elem in new_elems
            if elem in keys(newdict)
                newdict[elem] += n
            else
                newdict[elem] = n
            end
        end
    end
    return newdict
end

function n_blink(dict,n = 25)
    x = dict
    for i in 1:n
        x = blink_f(x)
    end
    return x
end

data = data_loader()
storage = build_freq(data)
res1 = n_blink(storage)
sol1 = sum(values(res1))

res2 = n_blink(storage, 75)
sol2 = sum(values(res2))



#Option B: memoize a recursive blinker, found on reddit, NOT my own

#Thus function returns the NUMBER of stones spawned by depth number of blinks, given some initial input stone

@memoize function blink(stone, depth)
    #If we are at depth 0 (no blinks), this process will not spawn any more stones. 
    if depth == 0
        return 1
    end
    
    #if our stone has a value of 0, we get a stone of value and a remaining blinking equal to current_blinks - 1
    if stone == 0
        return blink(1, depth - 1)
    else
        digits = ceil(Int, log10(stone+1))
        if iseven(digits)
            n = 10^(digits >> 1)
            return blink(stone ÷ n, depth - 1) + blink(stone % n, depth - 1)
        else
            return blink(stone * 2024, depth - 1)
        end
    end
end

sol2alternative = sum(blink.(copy(data), 75))



