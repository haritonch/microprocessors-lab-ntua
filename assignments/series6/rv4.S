#define GPIO_LEDs 0x80001404
#define GPIO_INOUT  0x80001408

.globl main

.text

main:
    li t0, 0xff
    li a0, GPIO_INOUT
    sw t0, 0(a0) # set LEDs as output

fill:
    li a0, GPIO_LEDs
    li t0, 8 # t0 = #(shifts needed)
    li t2, 0 # t2 = LEDs
    sw t2, 0(a0) # initialize LEDs
outter_loop_fill:
    li t3, 0 # t3 = #(shifts done)
    li t1, 1 # t1 = moving LED
    addi t0, t0, -1 # t0 = t0 - 1
    bgt t0, zero, inner_loop_fill
    or t2, t1, t2
    sw t2, 0(a0) # output LEDs
    j break_outter_fill
inner_loop_fill:
    or t2, t1, t2
    sw t2, 0(a0) # output LEDs
    ble t0, t3, break_inner_fill
    sub t2, t2, t1 # prevents moving LED from sticking
    slli t1, t1, 1 # shift moving LED left
    addi t3, t3, 1
    j inner_loop_fill
break_inner_fill:
    j outter_loop_fill
break_outter_fill:

unfill:
    li a0, GPIO_LEDs
    li t0, 8 # t0 = #(shifts needed)
    li t2, 0 # t2 = LEDs
    not t2, t2
    sw t2, 0(a0) # initialize LEDs
    not t2, t2
outter_loop_unfill:
    li t3, 0 # t3 = #(shifts done)
    li t1, 0x80 # t1 = moving LED
    addi t0, t0, -1 # t0 = t0 - 1
    bgt t0, zero, inner_loop_unfill
    or t2, t1, t2
    not t2, t2
    sw t2, 0(a0) # output LEDs
    not t2, t2
    j break_outter_unfill
inner_loop_unfill:
    or t2, t1, t2
    not t2, t2
    sw t2, 0(a0) # output LEDs
    not t2, t2
    ble t0, t3, break_inner_unfill
    sub t2, t2, t1 # prevents moving LED from sticking
    srli t1, t1, 1 # shift moving LED left
    addi t3, t3, 1
    j inner_loop_unfill
break_inner_unfill:
    j outter_loop_unfill
break_outter_unfill:
    j fill

.end