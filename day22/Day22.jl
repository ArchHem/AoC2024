using DataStructures
using Memoization

function load_data()
    lines = readlines("day22/day22input.txt")
    n = length(lines)
    results = zeros(Int64,n)
    for (i,l) in enumerate(lines)
        results[i] = parse(Int64,l)
    end
    return results
end

function mix(x::T,y::T) where T<:Integer
    result = x ⊻ y
    return result
end

function prune(x::T) where T<:Integer
    result = mod(x,16777216)
    return result
end

function crypto_step(x::T) where T<:Integer
    y = 64 * x
    x = mix(x,y)
    x = prune(x)
    y = x ÷ 32
    x = mix(x,y)
    x = prune(x)
    y = 2048 * x
    x = mix(x,y)
    x = prune(x)
    return x
end 

multi_stepper(x,n) = begin
    for i in 1:n
        x = crypto_step(x)
    end

    return x
end

function lastdigit(x::T) where T<:Integer
    y = mod(x,T(10))
    return y
end

data = load_data()
res1 = multi_stepper.(data,2000)
sol1 = sum(res1)

#not optimal to broadcast, but will do.
function get_changes_p2(x::Vector{T},n=2000) where T
    results = zeros(Int8,n+1,length(x))
    results[1,:] = lastdigit.(x)
    for i in 1:n
        x1 = crypto_step.(x)
        results[i+1,:] = lastdigit.(x1)
        x = x1
    end
    return results
end

function solve_p2(d)
    N = 19
    n = size(d)[1]-1
    maxfound = zeros(Int16,N,N,N,N)
    lookup = falses(N,N,N,N)
    diffs = @views d[2:end,:] .- d[1:end-1,:]
    @inbounds for j in axes(d,2)
        fill!(lookup,false)
        ldiff = @views diffs[:,j]
        @inbounds for i in 4:n
            #Using CartesianIndeces allocates, unfortunately. While its a small amount, it very quickly adds up. 
            #Could look into alternative indeixng methods or preallocations (could use static indexing...)
            i1,i2,i3,i4 = @views ldiff[i-3:i] .+ Int8(10)

            #a potential solution is to use CartesianIndex(NTuple{4,Int64}(x)) where x is just changes: this wont allocate
            
            if !lookup[i1,i2,i3,i4]
                #first time it sees the sequence it sells.
                lookup[i1,i2,i3,i4] = true
                #this is off-set from the differences by 1
                maxfound[i1,i2,i3,i4] += d[i+1,j]
            end
        end
    end
    return maximum(maxfound)
end

function solve_p2_alt(d)
    N = 19
    n = size(d)[1]-1
    maxfound = zeros(Int16,N,N,N,N)
    lookup = falses(N,N,N,N)
    diffs = @views d[2:end,:] .- d[1:end-1,:]
    @inbounds for j in axes(d,2)
        fill!(lookup,false)
        ldiff = @views diffs[:,j]
        @inbounds for i in 4:n
            
            changes = @views ldiff[i-3:i] .+ Int8(10)
            lindex = CartesianIndex(NTuple{4,Int64}(changes))
            
            
            if !lookup[lindex]
                #first time it sees the sequence it sells.
                lookup[lindex] = true
                #this is off-set from the differences by 1
                maxfound[lindex] += d[i+1,j]
            end
        end
    end
    return maximum(maxfound)
end


res2 = get_changes_p2(data)
sol2 = solve_p2(res2)


