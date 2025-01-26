using DataStructures, Memoize

function load_data()
    patterns, reqs = split(read("day19/day19input.txt",String),r"\n\s*\n")
    patterns = String.(split(patterns,", "))
    reqs = String.(split(reqs, r"\n"))
    return patterns, reqs
end

pat, reqs = load_data()


#if we wanted to be performant we could transform these to numerics.

@memoize function is_valid(req, pat = pat)
    
    if length(req) == 0
        return true
    end
    
    for pattern in pat
        n = length(pattern)
        if length(req) >= n && (req[1:n] == pattern) #is the beginning of the current string a valid substring?
            if is_valid(req[n+1:end],pat)
                return true
            end
            
        end
    end
    return false
    
end

#meoize messed things up w counting
function count_p2(req, memory, pat = pat, mutator = [0])
    
    if length(req) == 0
        mutator .+= 1
        return 
    end
    
    
    for pattern in pat
        n = length(pattern)
        if length(req) >= n && (req[1:n] == pattern) #is the beginning of the current string a valid substring?
            remains = req[n+1:end]
            if haskey(memory,remains)
                mutator .+= memory[remains]
            else
                #calculate how many times can the remaining substring be arranged
                c1 = mutator[1]
                count_p2(remains,memory,pat,mutator)
                memory[remains] = mutator[1] - c1
            end
        end
    end
    return 
end



valids = is_valid.(reqs, Ref(pat))
sol1 = sum(valids)

tracker = [[0] for _ in eachindex(reqs)]
memories = [Dict{String,Int64}() for _ in eachindex(reqs)]
count_p2.(reqs, memories, Ref(pat), tracker)
sol2 = sum(getindex.(tracker,1))




