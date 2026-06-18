# MIPS PWM Motor Controller

A complete 5-stage pipelined MIPS system that controls a PWM motor output through memory-mapped I/O.

## System Block Diagram

```text
+----------------------+      sw/lw       +----------------------+      duty/en      +----------------------+
| 5-stage MIPS CPU     | ---------------> | Data memory + MMIO   | ---------------> | PWM controller       |
| IF ID EX MEM WB      |                  | address decoder      |                  | counter + comparator |
| forwarding + stalls  | <--------------- | switches read port   |                  | pwm_out              |
+----------------------+      lw data     +----------------------+                  +----------------------+
```

## MMIO Address Map

| Address | Device | Direction | Notes |
| --- | --- | --- | --- |
| `0x0000+` | RAM | read/write | Normal data memory words |
| `0x0090` | switches | read-only | External 8-bit input from the testbench |
| `0x0098` | PWM duty | write-only | Low 8 bits set PWM duty cycle |
| `0x009C` | PWM enable | write-only | Bit 0 enables or disables PWM output |

## How To Build And Run

```sh
make
make run
make wave
```

`make run` builds the simulator and writes `wave.vcd`. `make wave` opens the VCD in GTKWave.

## What You Will See

The included `memfile.dat` implements option A: duty ramps from 0 toward 255, holds near max, ramps back down, holds at 0, then repeats. In the waveform, `dut.data_mem.pwm_duty` changes in steps and `pwm_out` becomes wider as duty increases and narrower as duty decreases.

## File Layout

```text
mips-pwm-motor-controller/
|-- README.md
|-- Makefile
|-- memfile.dat
|-- motor_profile.asm
|-- mips.v
|-- mips_tb.v
|-- datapath.v
|-- control_unit.v
|-- register_file.v
|-- alu.v
|-- data_memory.v
|-- pwm_controller.v
`-- docs/
    |-- design_report.md
    |-- test_report.md
    `-- waveform_profile.png
```
