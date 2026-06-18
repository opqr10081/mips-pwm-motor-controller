# Design Report: MIPS PWM Motor Controller

## 1. Introduction

This project builds a small embedded system around a 5-stage pipelined MIPS CPU. The CPU runs a MIPS assembly motor-profile program, writes ordinary `sw` instructions to memory-mapped I/O registers, and drives a PWM controller whose duty cycle changes over time. The result connects processor architecture, MMIO, and digital peripheral design in one simulation.

## 2. System Architecture

```text
+----------------------+      instruction fetch       +-------------------+
| instruction memory   | ---------------------------> | 5-stage MIPS CPU  |
| loads memfile.dat    |                              | IF ID EX MEM WB   |
+----------------------+                              +---------+---------+
                                                                  |
                                                                  | sw/lw address + data
                                                                  v
+----------------------+      switches read           +-------------------+
| testbench switches   | ---------------------------> | data memory/MMIO  |
+----------------------+                              | RAM + decoder     |
                                                        +---------+---------+
                                                                  |
                                                                  | duty[7:0], en
                                                                  v
                                                        +-------------------+
                                                        | PWM controller    |
                                                        | 8-bit counter/cmp |
                                                        +---------+---------+
                                                                  |
                                                                  v
                                                               pwm_out
```

The instruction memory is a ROM initialized from `memfile.dat`. The datapath is a classic IF/ID/EX/MEM/WB pipeline. The control unit decodes R-type, I-type, branch, jump, load, and store instructions. The register file supplies two asynchronous read ports and one synchronous write port. The ALU supports add, subtract, and, or, and signed less-than. The data-memory block contains RAM and MMIO address decoding. The PWM controller contains an 8-bit free-running counter and a comparator.

## 3. MMIO Design

| Address | Device | Direction | Notes |
| --- | --- | --- | --- |
| `0x0000+` | RAM | read/write | Normal data memory words |
| `0x0090` | switches | read-only | External 8-bit input from the testbench |
| `0x0098` | PWM duty | write-only | Low 8 bits set PWM duty cycle |
| `0x009C` | PWM enable | write-only | Bit 0 enables or disables PWM output |

`data_memory.v` decodes the full byte address in a `case` statement. Writes to `0x98` update `pwm_duty`, writes to `0x9c` update `pwm_enable`, and all other writes go to RAM. Reads are combinational so a load can receive memory or switch data during the MEM stage. Writes are synchronous because RAM and peripheral registers should update on a clock edge, which avoids glitches and makes the peripheral state easy to reason about in a waveform.

## 4. PWM Controller Design

The PWM module uses an 8-bit counter that increments every clock cycle. Its output is high when `en` is asserted and `counter < duty`; otherwise it is low. A duty value of 0 keeps the output low, 128 gives about 50 percent high time, and 255 gives 255 high cycles out of every 256 clocks.

The PWM period is:

```text
T_pwm = 256 * T_clk
```

With the testbench clock period of 10 ns, the PWM period is 2560 ns and the PWM frequency is about 390.625 kHz.

## 5. Software Algorithm

This implementation uses option A: ramp-up, hold at max, ramp-down, hold at 0, repeat. It was chosen because it exercises repeated MMIO writes, loops, branches, signed comparisons, and jumps while producing a waveform that is easy to verify visually.

```text
enable PWM
set duty = 0
repeat forever:
    while duty <= 255:
        write duty to PWM_DUTY
        delay
        duty += 16
    write 255 to PWM_DUTY
    delay longer
    while duty >= 0:
        write duty to PWM_DUTY
        delay
        duty -= 16
    write 0 to PWM_DUTY
    delay longer
```

The short delay loop counts down from 4 between duty updates so the simulation shows frequent but separated duty changes. The hold loops count down from 32 to make the maximum and zero-duty regions visible. The assembly includes NOPs after ALU results that feed ID-stage branch decisions, while the datapath also includes branch operand forwarding from later pipeline stages.

## 6. Reflection

The trickiest part was keeping the branch timing clear. Resolving branches in ID reduces penalty, but it also means branch operands may need values that are still moving through EX, MEM, or WB. If I had more time, I would add a broader self-checking instruction test suite that separately verifies each forwarding and hazard path before running the motor profile.
