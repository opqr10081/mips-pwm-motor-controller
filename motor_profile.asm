; Option A motor-speed profile: ramp up, hold max, ramp down, hold zero, repeat.
    addi $t4, $zero, 152         # 0x0000: 200c0098
    addi $t5, $zero, 156         # 0x0004: 200d009c
    addi $t6, $zero, 1           # 0x0008: 200e0001
    sw $t6, 0($t5)               # 0x000c: adae0000
    addi $t0, $zero, 0           # 0x0010: 20080000
    addi $t1, $zero, 255         # 0x0014: 200900ff
main_loop:
    sw $t0, 0($t4)               # 0x0018: ad880000
    addi $t2, $zero, 4           # 0x001c: 200a0004
delay_up:
    addi $t2, $t2, -1            # 0x0020: 214affff
    nop                          # 0x0024: 00000000
    bne $t2, $zero, delay_up     # 0x0028: 1540fffd
    nop                          # 0x002c: 00000000
    addi $t0, $t0, 16            # 0x0030: 21080010
    slt $t7, $t1, $t0            # 0x0034: 0128782a
    nop                          # 0x0038: 00000000
    beq $t7, $zero, main_loop    # 0x003c: 11e0fff6
    nop                          # 0x0040: 00000000
    addi $t0, $zero, 255         # 0x0044: 200800ff
    sw $t0, 0($t4)               # 0x0048: ad880000
    addi $t2, $zero, 32          # 0x004c: 200a0020
hold_max:
    addi $t2, $t2, -1            # 0x0050: 214affff
    nop                          # 0x0054: 00000000
    bne $t2, $zero, hold_max     # 0x0058: 1540fffd
    nop                          # 0x005c: 00000000
ramp_down:
    sw $t0, 0($t4)               # 0x0060: ad880000
    addi $t2, $zero, 4           # 0x0064: 200a0004
delay_down:
    addi $t2, $t2, -1            # 0x0068: 214affff
    nop                          # 0x006c: 00000000
    bne $t2, $zero, delay_down   # 0x0070: 1540fffd
    nop                          # 0x0074: 00000000
    addi $t0, $t0, -16           # 0x0078: 2108fff0
    slt $t7, $t0, $zero          # 0x007c: 0100782a
    nop                          # 0x0080: 00000000
    beq $t7, $zero, ramp_down    # 0x0084: 11e0fff6
    nop                          # 0x0088: 00000000
    addi $t0, $zero, 0           # 0x008c: 20080000
    sw $t0, 0($t4)               # 0x0090: ad880000
    addi $t2, $zero, 32          # 0x0094: 200a0020
hold_zero:
    addi $t2, $t2, -1            # 0x0098: 214affff
    nop                          # 0x009c: 00000000
    bne $t2, $zero, hold_zero    # 0x00a0: 1540fffd
    nop                          # 0x00a4: 00000000
    j main_loop                  # 0x00a8: 08000006
    nop                          # 0x00ac: 00000000
