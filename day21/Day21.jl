using DataStructures
using Memoization
using StaticArrays
#Not very type stable. Better option would be to reserve something.

const MainKeyboard = Dict(
    '7' => CartesianIndex(1,1),
    '8' => CartesianIndex(1,2),
    '9' => CartesianIndex(1,3),
    '6' => CartesianIndex(2,3),
    '5' => CartesianIndex(2,2),
    '4' => CartesianIndex(2,1),
    '3' => CartesianIndex(3,3),
    '2' => CartesianIndex(3,2),
    '1' => CartesianIndex(3,1),
    '0' => CartesianIndex(4,2),
    'A' => CartesianIndex(4,3)
)

#due to how our coordinate system works, a (-1,0) actually points...upward!
const AuxKeyboard = Dict(
    'u' => CartesianIndex(1,2),
    'A' => CartesianIndex(1,3),
    'l' => CartesianIndex(2,1),
    'd' => CartesianIndex(2,2),
    'r' => CartesianIndex(2,3)
)

const InvAux = Dict(v => k for (k,v) in AuxKeyboard)

function load_data()
    rows = readlines("day21/day21input.txt")
    outp = Matrix{Char}(undef,(length(rows),length(rows[1])))
    nums = zeros(Int64,length(rows))
    for (index, r) in enumerate(rows)
        outp[index,:] = only.(split(r,""))
        numeric_match = eachmatch(r"\d+",r)
        numeric_part = join([u.match for u in numeric_match])
        nums[index] = parse(Int64,numeric_part)
    end
    return outp, nums
end

function get_path(sp,ep,gap)
    #once the enter button is pressed on a "higher" keyboard, all other ones must be above the button "A"
    Ny = abs((ep-sp).I[1])
    dy = sign((ep-sp).I[1])

    Nx = abs((ep-sp).I[2])
    dx = sign((ep-sp).I[2])

    xstep = dx > 0 ? 'r' : 'l'
    ystep = dy < 0 ? 'u' : 'd'

    if sp == gap || ep == gap
        return nothing
    elseif sp == ep
        return [Char[]]
    elseif dx == 0
        return [fill(ystep,Ny)]
    elseif dy == 0
        return [fill(xstep,Nx)]
    # horizinal move would hit gap from sp
    elseif gap == CartesianIndex(ep.I[1],sp.I[2])
        
        results = append!(fill(xstep,Nx),
                        fill(ystep,Ny))
        return [results]
    elseif gap == CartesianIndex(sp.I[1],ep.I[2])
        results = append!(fill(ystep, Ny),
                            fill(xstep,Nx))
        
        return [results]
    else
        results1 = append!(fill(ystep, Ny),
                        fill(xstep,Nx))
        results2 = append!(fill(xstep,Nx),
                        fill(ystep,Ny))
        return [results1,results2]
    end
end

function generate_paths(keyboard,gap)
    #given a keyboard Dict{Char,CartesianIndex}() will generate a path using the secondary keyboard
    results = Dict{Tuple{Char, Char},Vector{Vector{Char}}}()

    for i in keys(keyboard)
        for j in keys(keyboard)
            vi, vj = keyboard[i], keyboard[j]
            lval = get_path(vi,vj,gap)
            if !isnothing(lval)
                results[(i,j,)] = lval
            end
        end
    end

    return results
end

#ro effectively use memoization, all inputs should be immutable, eg strings,tuples or static-vectors
#TODO: read up on why this is
@memoize function solve_deep(code,layer::Int)
    if layer == 1
        return length(code)
    end

    movements = zip(vcat('A',code),code)

    #movements encode the key-pairs that we need to press sequentally. However, for some of these, there exists multiple paths, of which
    #we need to pick the shortest one (at the lowest level). Since the end-state of the recusrion is teh length of the code at the minamal level, we can just 
    #pick the individial shortest paths and sum them up (getting the needed quantity and the overall length of the lowest code)

    pot_paths = sum(minimum([solve_deep(SVector{length(lcode) + 1}(vcat(lcode,'A')),layer-1) for lcode in SecPaths[move]]) for move in movements)

    return pot_paths
end

function prep_code(code,layer)
    sp = append!(['A'],code)
    ep = code

    primary_moves = zip(sp,ep)
    potential_lengths = sum(minimum([solve_deep(SVector{length(ncode) + 1}(vcat(ncode,'A')),layer-1) for ncode in PrimPaths[move]]) for move in primary_moves)
    return potential_lengths
end


data, nums = load_data()
const PrimPaths = generate_paths(MainKeyboard,CartesianIndex(4,1))
const SecPaths = generate_paths(AuxKeyboard,CartesianIndex(1,1))

res1 = prep_code.(eachrow(data),4)
res2 = prep_code.(eachrow(data),27)

sol1 = sum(res1 .* nums)
sol2 = sum(res2 .* nums)

#TODO: maybe this can be done using Djikastra? Look into if original solution uisng CartesianIndeces is more efficient.


