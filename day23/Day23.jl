using Graphs
using DataStructures
using GraphRecipes, Plots

function data_loader()
    lines = readlines("day23/day23input.txt")
    n = length(lines)
    o1, o2 = Vector{String}(undef,n), Vector{String}(undef,n)
    for i in 1:n
        o1[i], o2[i] = split(lines[i],"-")
    end
    return o1, o2
end

const o1,o2 = data_loader()

function build_hashes(o1,o2)
    
    forward_hash = Dict{String,Int64}()
    backward_hash = Dict{Int64,String}()
    counter = 1
    for i in eachindex(o1,o2)
        e1, e2 = o1[i], o2[i]
        if !(e1 in keys(forward_hash))
            forward_hash[e1] = counter
            backward_hash[counter] = e1
            counter += 1
        end

        if !(e2 in keys(forward_hash))
            forward_hash[e2] = counter
            backward_hash[counter] = e2
            counter += 1
        end

    end
    return forward_hash, backward_hash
    
end

const h1, h2 = build_hashes(o1,o2)

get_edges(x1,x2) = [(h1[e1],h1[e2]) for (e1,e2) in zip(x1,x2)]
edgelist = get_edges(o1,o2)
const n_vertices = maximum(values(h1))

function build_graph(edgelist = edgelist, n = n_vertices)
    g = SimpleGraph(n)
    for e in edgelist
        add_edge!(g,e[1],e[2])
    end
    return g
end

const connection = build_graph()

#graphplot(connection)

#Every PC has 13 connections it seems

#find every PC's index that begins with t

const is_valid = Set(vcat(o1[getindex.(o1,1) .== 't'], o2[getindex.(o2,1) .== 't']))
const num_ids = [getindex(h1,ele) for ele in is_valid]

function solve_p1(g,ids = num_ids)
    #find all three-set of valid IDs
    adjacency = g.fadjlist
    adjacency = Dict(collect(1:length(adjacency)) .=> [Set(e) for e in adjacency])
    valids = Set{Set{Int64}}()
    
    for id in ids
        p1 = adjacency[id]
        for id2 in p1
            p2 = adjacency[id2]
            for id3 in p2
                posible = Set([id,id2,id3])
                if length(posible) == 3 && (id in adjacency[id3])
                    push!(valids,posible)
                end
            end
        end
    end
    return valids
end

res1 = solve_p1(connection)
sol1 = length(res1)

#these are the vertices that interest us...

#After some reading, we can use the Bron-Korsch algorithm to find all cliques of size n = 3.

#https://en.wikipedia.org/wiki/Bron–Kerbosch_algorithm

#non pivoting version

function BronKerbosch!(R, P, X, tracker, g = connection, minlength = 1)

    if isempty(P) && isempty(X) && length(R) > minlength
        push!(tracker,copy(R))
        return 
    end
    #P and X are disjoint: their union is the elements that when added to R form a clique still
    for v in copy(P)
        neighbors = Set(g.fadjlist[v])
        BronKerbosch!(push!(copy(R),v),intersect(P,neighbors),intersect(X,neighbors), tracker, g, minlength)
        delete!(P,v)
        push!(X,v)
    end
end

function get_cliques(g = connection)
    P = Set(collect(1:length(g.fadjlist)))
    R, X = Set{Int64}(), Set{Int64}()
    tracker = Vector{Set{Int64}}()
    BronKerbosch!(R,P,X,tracker,g)
    return tracker
end

res2 = get_cliques() #for sanity check call
#res2_test = maximal_cliques(connection)

vid = argmax(length.(res2)) #assume there is only one maximal one
interm = res2[vid]
stringRes = getindex.(Ref(h2),[interm...])
sol2 = join(sort(stringRes),",")





