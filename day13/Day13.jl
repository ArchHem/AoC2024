using DataStructures

function data_loader()
    str = read("day13/day13input.txt", String)
    chunks = split(str, r"\n\s*\n+")

    
    cleaned_chunks = filter(!isempty, strip.(chunks))

    N = length(chunks)
    res = zeros(Int64,N,6)

    for (i,c) in enumerate(cleaned_chunks)
        #each line of chunk has x number or 2x numbers, 6x rows
        
        lmatches = eachmatch.(r"\d+", c)
        local_str = [m.match for m in lmatches]
        res[i,:] .= parse.(Int64,local_str)
        
    end

    return res
end

data = data_loader()

const AButton = data[:,1:2]
const BButton = data[:,3:4]
const Target = data[:,5:6]

#Press A 3:
#Press B 1:

#Maximum of 100 pushes per button
#Minimiye cost...

#https://en.wikipedia.org/wiki/Linear_programming 

#https://en.wikipedia.org/wiki/Integer_programming

#Minimize: 

#3*N_1 + N2 = K

#Subject to N1*(A) + N2*(B) = T
# (N1,N2) <= 100

#Would need to move to standard form: could use JUMP, GLPK

#BUT this problem is sufficently small that we can brutforce it via 100x100 matrices.

function bruteforce_p1(A,B,T)

    N1grid, N2grid = ones(Int64,100)' .* collect(1:100), ones(Int64,100) .* collect(1:100)'

    restraint_x = N1grid .* A[1] + N2grid .* B[1]
    restraint_y = N1grid .* A[2] + N2grid .* B[2]

    is_valid = restraint_x .== T[1] .&& restraint_y .== T[2]
    costs = 3 .* N1grid + 1 .* N2grid
    valid_costs = costs[is_valid]

    if isempty(valid_costs)
        return 0
    else
        return minimum(valid_costs)
    end
end

costs = map(bruteforce_p1,eachslice(AButton,dims = 1),eachslice(BButton,dims = 1),eachslice(Target,dims = 1))
sol1 = sum(costs)


#brutefocing is NOT feasible for p2, we need to use JUMP and GLPK

using JuMP, GLPK

const new_target = Target .+ 10000000000000

function solve_ILP(A,B,T)
    model = Model(GLPK.Optimizer)
    @variables(model, begin
        N_A >= 0, Int
        N_B >= 0, Int
    end)

    @objective(model, Min, N_A*3 + N_B)
    @constraint(model, N_A*A[1]+N_B*B[1] == T[1])
    @constraint(model, N_A*A[2]+N_B*B[2] == T[2])
    optimize!(model)

    if termination_status(model) == MOI.OPTIMAL
        #This is cast to float for reasons unknown... we can round here to limit stuff higher up
        
        return round(Int64,objective_value(model))
    else
        return 0
    end
end

costs2 = map(solve_ILP,eachslice(AButton,dims = 1),eachslice(BButton,dims = 1),eachslice(new_target,dims = 1))
#returns floats for some reason
sol2 = sum(costs2)


#We could also implement https://en.wikipedia.org/wiki/Interior-point_method

#But the best solution by fasr is simply linalg. because the minimization condition DOES NOT matter for any non-parallel cases!

#We want target st. T = N1 * A 
#We just need to check if the interesect of the lines N1*A_x + N2 * B_x = T_x, N1*A_y + N2 * B_y = T_y
#in the N1-N2 plain occurs at integer value of not. Since we can only  a single intersect, this will guarantee teh correct root.

#Potential edge case if A == B

function solve_p2_optimal(A,B,T)
    local_T = Rational{Int64}.(T)
    matrix_to = zeros(Rational{Int64},2,2)
    matrix_to[:,1] .= A
    matrix_to[:,2] .= B

    #floating-point limitations require us to use an EXACT representation...

    #rationals....

    solution = matrix_to \ local_T
    

    
    if all(solution .% 1 .== 0)
        weights = [3,1]
        
        return round(Int64,sum(weights .* solution))
    else
        return 0
    end
end

costs3 = map(solve_p2_optimal,eachslice(AButton,dims = 1),eachslice(BButton,dims = 1),eachslice(new_target,dims = 1))
#returns floats for some reason
sol3 = sum(costs3)