using DataStructures, Graphs, GraphRecipes, Plots

#this seems like a topological sort problem at first glance

function build_hash(x::AbstractVector)
    counter = 1::Int64
    t = eltype(x)
    fdict = Dict{Int64,t}()
    bdict = Dict{t,Int64}()
    for elem in x
        if !(elem in keys(bdict))
            fdict[counter] = elem 
            bdict[elem] = counter
            counter += 1
        end
    end
    return fdict, bdict
end

function data_loader()
    raw = read("day24/day24input.txt", String)
    p1, p2 = split(raw,r"\n\s*\n")
    
    init_vals = [String(e.match) for e in eachmatch(r"\s+\d", p1)]
    
    init_keys = [String(e.match) for e in eachmatch(r"[a-z]\d+",p1)]
    basestate = Bool.(parse.(Int64,init_vals))
    pdict = Dict(init_keys .=> basestate)

    #process p2

    operands = [String(e.match) for e in eachmatch(r"[A-Z]{2,3}",p2)]
    results = [String(e.match) for e in eachmatch(r"(?<=->\s)[a-z0-9]{3}",p2)]
    second_inputs = [String(e.match) for e in eachmatch(r"(?<=OR\s|AND\s|XOR\s)[a-z0-9]{3}", p2)]
    primary_input = [String(e.match) for e in eachmatch(r"[a-z0-9]{3}(?=\sOR|\sAND|\sXOR)",p2)]
    fdict, bdict = build_hash(vcat(init_keys,primary_input,second_inputs,results))
    
    states = falses(length(fdict))

    for k in init_keys
        states[bdict[k]] = pdict[k]
    end

    

    opStruct = Dict{Int64,Tuple{Int64,Int64,String}}() #this is actually kinda horrible for performance, not O() wise. Dont care!
    for i in eachindex(results)
        #map output to income ids
        opStruct[bdict[results[i]]] = (bdict[primary_input[i]],bdict[second_inputs[i]],operands[i])
    end
    
    
    

    return fdict, bdict, states, opStruct
end

function kahn_algo(x::AbstractGraph)
    #https://en.wikipedia.org/wiki/Topological_sorting

    ine = inneighbors.(Ref(x),vertices(x))
    starters = collect(vertices(x))[isempty.(ine)]

    lx = deepcopy(x)
    L = Int64[]
    S = Set(starters)

    while !isempty(S)
        n = pop!(S)
        push!(L,n)
        #apparently outneighbors is reference so we should not modify it directly.
        for m in copy(outneighbors(lx,n))
            edge = Edge(n,m)
            rem_edge!(lx,edge)
            if isempty(inneighbors(lx,m))
                push!(S,m)
            end
        end
    end
    #error handling because idk
    
    if !isempty(edges(lx))
        throw(ErrorException("Loop"))
    end

    return L
end

function execute_operand(s, a, b)
    #small lookup, no need to hash.
    if s == "OR"
        return a || b
    elseif s == "XOR"
        return a ⊻ b
    elseif s == "AND"
        return a && b
    end
end

function solve_p1_p2()
    fdict, bdict, state, ops = data_loader()
    nnodes = length(state)
    state1, state2 = copy(state), copy(state)
    #build the way we need to carry out the 

    g = SimpleDiGraph(nnodes)
    
    


    for o in keys(ops)
        x,y, str = ops[o]
        add_edge!(g,x,o)
        add_edge!(g,y,o)
    end

    
    
    operand_id_set = keys(ops)

    opOrder2 = kahn_algo(g)
    opOrder1 = topological_sort(g)
    
    #now, follow toposort and carry out the opset
    
    for i in 1:length(opOrder1)
        
        if opOrder1[i] in operand_id_set

            e = opOrder1[i]
            
            x,y,str = ops[e]
            
            state1[e] = execute_operand(str,state1[x],state1[y])

        end
        if opOrder2[i] in operand_id_set

            e = opOrder2[i]
            
            x,y,str = ops[e]
            
            state2[e] = execute_operand(str,state2[x],state2[y])

        end
    end

    #sanity check, should be empty
    u = findall(.!(state1 .== state2))
    #println(getindex.(Ref(fdict),u))

    #find nodes starting with z
    stringkeys = filter((x)->occursin(r"z\d{2}",x),collect(keys(bdict)))
    sorted_keys = sort(stringkeys, rev = true)
    
    indeces = getindex.(Ref(bdict),sorted_keys)
    bitvals = state1[indeces]

    N = length(bitvals)

    decim = sum([bitvals[i]*2^(N-i) for i in 1:N])

    #for p2, we can use the fact that the addition-graph of two N-bit binary numbers is known:
    
    #https://en.wikipedia.org/wiki/Adder_%28electronics%29

    #In short for all non-last digits:

    #For a full dder, we have (input X_i, Y_i and previous Carry-on bit C_i)

    # X_i ⊻ Y_i = A_i
    # X_i AND Y_i = L_C_i
    # A_i ⊻ C_i = S_i
    # A_i AND C_i = B_i
    # B_i OR L_C_i = C_i+1

    #This can realized as:

    #The 46th bit is special, as it is constructed from the carry-on-bit of the 45th, via:

    # B_44 OR L_C_44 = Z45

    # The first bit is just a simple haf-adder, that is, 

    # X_0 ⊻ Y_0 = Z_0
    # X_0 AND Y_0 = C_0

    #We can resonctruct this graph exactly

    #technically it not guaranteed that only input bits start with x
    #better use a regex
    zstringkeys = filter((x)->occursin(r"z\d{2}",x),collect(keys(bdict)))
    zsorted_keys = sort(zstringkeys)
    
    xstringkeys = filter((x)->occursin(r"x\d{2}",x),collect(keys(bdict)))
    xsorted_keys = sort(xstringkeys)
    ystringkeys = filter((x)->occursin(r"y\d{2}",x),collect(keys(bdict)))
    ysorted_keys = sort(ystringkeys)

    zindeces = getindex.(Ref(bdict),zsorted_keys)
    xindeces = getindex.(Ref(bdict),xsorted_keys)
    yindeces = getindex.(Ref(bdict),ysorted_keys)

    #pretty sure we dont need to sort this and we could just get this via iteration.
    interim_indeces = sort(collect(setdiff(Set(collect(1:nnodes)),Set(vcat(xindeces,yindeces,zindeces)))))

    #lets write out the first gate:
    CG = DiGraph(nnodes)

    #C_1
    add_edge!(CG,xindeces[1],interim_indeces[1])
    add_edge!(CG,yindeces[1],interim_indeces[1])
    #Z_1
    add_edge!(CG,xindeces[1],zindeces[1])
    add_edge!(CG,yindeces[1],zindeces[1])

    count_index = 2
    leftover_index = 1

    for i in 2:(length(xindeces)-1)
        
        #A_i
        add_edge!(CG,xindeces[i],interim_indeces[count_index])
        add_edge!(CG,yindeces[i],interim_indeces[count_index])
        a_index = count_index
        count_index += 1

        #L_c_i
        add_edge!(CG,xindeces[i],interim_indeces[count_index])
        add_edge!(CG,yindeces[i],interim_indeces[count_index])
        L_c_index = count_index
        count_index += 1

        #B_i <-(A_i, L_c_i)
        add_edge!(CG,interim_indeces[a_index],interim_indeces[count_index])
        add_edge!(CG,interim_indeces[L_c_index],interim_indeces[count_index])
        B_index = count_index
        count_index += 1

        #S_i = (A_i, C_i)
        add_edge!(CG,interim_indeces[a_index],zindeces[i])
        add_edge!(CG,interim_indeces[leftover_index],zindeces[i])

        #C_i = (B_i, L_c_i)

        add_edge!(CG,interim_indeces[B_index],interim_indeces[count_index])
        add_edge!(CG,interim_indeces[L_c_index],interim_indeces[count_index])
        leftover_index = count_index
        count_index += 1

    end
    
    #last index
    N_i = length(xindeces)
    #A_i
    add_edge!(CG,xindeces[N_i],interim_indeces[count_index])
    add_edge!(CG,yindeces[N_i],interim_indeces[count_index])
    a_index = count_index
    count_index += 1

    #L_c_i
    add_edge!(CG,xindeces[N_i],interim_indeces[count_index])
    add_edge!(CG,yindeces[N_i],interim_indeces[count_index])
    L_c_index = count_index
    count_index += 1

    #B_i <-(A_i, L_c_i)
    add_edge!(CG,interim_indeces[a_index],interim_indeces[count_index])
    add_edge!(CG,interim_indeces[L_c_index],interim_indeces[count_index])
    B_index = count_index
    count_index += 1

    #S_i = (A_i, C_i)
    add_edge!(CG,interim_indeces[a_index],zindeces[N_i])
    add_edge!(CG,interim_indeces[leftover_index],zindeces[N_i])

    #Z_last = (B_i, L_c_i)

    add_edge!(CG,interim_indeces[B_index],zindeces[N_i+1])
    add_edge!(CG,interim_indeces[L_c_index],zindeces[N_i+1])


    #detect swapped edges: use CG as computed above

    #for each gate, check if it produces the correct outputs or not.  If not, check "up" the graph (i.e. traceverse it upward using DFS) to see if a sawp can fix it
    #This is guarabteed to work, but runs in O(k^2). If we mutate the graph, we cant use memoizatio either.

    #TODO Reimplement the above

    #A heuretic which I had seen and I cant prove is to check within each full adder. 
    # Certain kinds of logic gates can only lie in certain parts of a circuit (they must retain topologocal order for no circles to exist, ergo no inter-ciruit messups)

    #Since we KNOW that the swapped graph has no cricles, 
    #I suspect that the a swap can only occur WITHIN a full adder (as otherwise it would destroz the topological order) This remarkably runs in O(k) if true.

    #TODO: Prove the above.
    invalids = String[]
    is_output(x) = occursin(r"z\d{2}",x)
    is_input(x) = occursin(r"x\d{2}",x) || occursin(r"y\d{2}",x)

    #use where a particular 
    for o in keys(ops)
        x,y, opcode = ops[o]
        
        u1, u2, u3 = fdict[x],fdict[y],fdict[o]

        if is_output(u3)
            if opcode != "XOR" && u3 != "z45"
                
                push!(invalids,u3)
            
            #the first bits remained gets generated via a direct AND and gets used in second bit
            elseif opcode == "XOR" && !(u1 == "x00" || u1 == "y00" || u3 == "z01")
                _,_,prevop1 = ops[x]
                _,_,prevop2 = ops[y]

                #previous operations.... does not work for first bits
                if prevop1 == "AND"
                    println(fdict[x])
                    push!(invalids,fdict[x])
                end

                if prevop2 == "AND"
                    println(fdict[y])
                    push!(invalids,fdict[y])
                end

            end
        end

        if is_input(u1) && is_input(u2) && !(opcode in ["AND","XOR"])
            push!(invalids,u3)
        end

        if opcode == "XOR"
            if !((is_input(u1) && is_input(u2)) || is_output(u3))
                push!(invalids,u3)
            end
        end

        if opcode == "OR"
            _,_,prevop1 = ops[x]
            _,_,prevop2 = ops[y]

            #previous operations....
            if prevop1 != "AND"
                push!(invalids,fdict[x])
            end

            if prevop2 != "AND"
                push!(invalids,fdict[y])
            end
        end
    end
    #due to uniqueness we could use a set, but we do not have many duplicates, so its not worth the overhead
    return decim, join(sort(unique(invalids)),",")
end

sol1, sol2 = solve_p1_p2()