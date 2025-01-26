using DataStructures

#opied P1 due to dict solution being a pain
#credit: https://topaz.github.io/paste/#XQAAAQCnBQAAAAAAAAAzHUn/qWH7EwabQb6KPFaed8/5egnYUFUeWNzIz8zSD1ywC6YSgmOGW/U26fVrJPSm3n7lG13ae4N+dY6PtBLySoNnyeSTOhX5QHC/fceEPfWqmtkTyyfCl4XYjPyYHIf54Lc3fqetvRMKRib0TWyVTW+EAqvs9QE/SEqC5I1jG/5+8Qf7CFD0BjKvJMD+Nc/C2tVmC5zLYc8OBj5TcmgXKB6ShEoz/2jwEL/mW3GGnBOp9CUg9h83L0p/mytrlTN047T4EJYCXaHeF8sw7U3IsnIPei6s8S6Le04PQx5NKB+N2VAVMLmr1m7FuLgxZlbDoPISG9Uiaplx15iFORTugRaBh37Icl1zDJ1cR5Wl3E5pU1GiaUiYfkUhec3r3CryNhs+zd78jtIJ6YwKnNiVL70ylYoYrxJ01WgILDwkUthsjU4HtYpgSj8DwIFYdJY7ON6iy0mlRgeaomfBqfyOjkXyeHAa7pg3k0K5YbTRete0Gi6JEBQ11p6qspMxQYAwJnovhne2W+6l9URFB0+HdP+YJKyTqc982katqY7sKpoqeSbNpZomQggk1fwjqrssyzDrnIWCEba4677z9NnVKOEfHfowv+Eu8DcQUlXjQBX2bW+sszW2YYBSV2fHisTMyS3Ur+zinxmHL/8wyCidJGcZHznJaO4GjlirnL5X3CaaoGsY3dffxEDdVejh1md5t33GQc+q0xZ8umAUmVLILaZFQhRP7Zz7Qf+jA2P4

function load_data()
    init = read("day17/day17input.txt",String)
    
    values, operands  = split(init,r"\n\s*\n")
    registers = getfield.(collect(eachmatch(r"\d+",values)), :match)
    instructions = getfield.(collect(eachmatch(r"\d+",operands)),:match)

    registers = parse.(Int64,registers)
    instructions = parse.(Int64,instructions)


    return registers, instructions
end

registers, program = load_data()

function run(program, registers)
    A,B,C = registers
    ptr = 0
    output = Int[]

    while ptr < length(program)
        opcode, operand = program[ptr .+ (1:2)]

        combo = if operand == 4
            A
        elseif operand == 5
            B
        elseif operand == 6
            C
        else
            operand
        end

        if opcode == 0
            A = A >> combo
        elseif opcode == 1
            B = xor(B, operand)
        elseif opcode == 2
            B = combo & 0b111
        elseif opcode == 3 && A != 0
            ptr = operand
            continue
        elseif opcode == 4
            B = xor(B, C)
        elseif opcode == 5
            push!(output, combo & 0b111)
        elseif opcode == 6
            B = A >> combo
        elseif opcode == 7
            C = A >> combo
        end

        ptr += 2
    end

    return output
end

output = run(program, registers)

#based on descri. it looks like 
#while a !=0
#   res = H(a)
#   yield res (opcode 5)
#   a = a >> 3
#   where H(a) is some very complicated function 

function checker!(current_A, iter, program, storage)
    
    if iter == 0 
        if run(program,[current_A,UInt64(0),UInt64(0)]) == program
            push!(storage,current_A)
        end
        return 
    end

    for i in 0:7
        testA = (current_A << 3) + i
        testRes = run(program,[testA,UInt64(0),UInt64(0)])
        
        #technically we could jusr return after the first 5 and terminate there.
        if testRes[1] == program[iter]
            
            
            checker!(testA, iter-1, program, storage)
            


        end
    end

    return nothing

end

st = UInt64[]
checker!(UInt64(0),length(program),program,st)



res2 = Int64(minimum(st))