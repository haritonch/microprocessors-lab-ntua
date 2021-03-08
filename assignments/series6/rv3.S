.globl main

.equ N, 5

.data
    A: .word 1,2,3,4,5
    B: .word 2,3,4,-5,6
.bss
    C: .space 4*N
.text

main:
    la t0, A    
    la t1, B
    la t2, C
    
    add t1, t1, 4*(N-1) # t1 stores B pointer
    add t3, t0, 4*N # stores A end for loop condition check
    
    # C[i] = |A[i] + B[n-i-1]| 
    # t0: A pointer
    # t1: B pointer
    # t2: C pointer
loop:
    lw t4, 0(t0) # t4 = A[i]
    lw t5, 0(t1) # t5 = B[N-i-1]
    add t6, t4, t5 # t6 = A[i] + B[N-i-1]
    bgt t6, zero, positive_sum # if t6 < 0
negative_sum:
    sub t6, zero, t6 # t6 = 0 - t6
positive_sum: # else do nothing

    sw t6, 0(t2) # C[i] = | A[i] + B[N-i-1] |

    addi t0, t0, 4 # increase A pointer
    addi t1, t1, -4 # decrease B pointer
    addi t2, t2, 4 # increase C pointer
    bgt t3, t0, continue # if A end > A pointer then continue
    j break  # else break
continue:    
    j loop
break:
    
    

.end