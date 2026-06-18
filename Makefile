IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave

SRC = mips_tb.v mips.v datapath.v control_unit.v register_file.v alu.v data_memory.v pwm_controller.v

.PHONY: all sim run wave clean

all: sim

sim: $(SRC) memfile.dat
	$(IVERILOG) -g2012 -Wall -o sim.out $(SRC)

run: sim
	$(VVP) sim.out

wave: run
	$(GTKWAVE) wave.vcd

clean:
	powershell -NoProfile -Command "Remove-Item -Force sim.out,wave.vcd -ErrorAction SilentlyContinue"
