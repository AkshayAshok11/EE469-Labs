# Extra-credit run: control/branch hazard detection (dynamic flush).
#
# Before running this:
#   1. Uncomment `define FLUSH_ON_BRANCH near the top of cpu.sv.
#   2. Set instructmem.sv's active `define BENCHMARK line to
#      "../benchmarks/test03_CbzB.arm" -- this is the file the extra credit
#      is graded against (X2 should end at 0, vs. 4 with FLUSH_ON_BRANCH
#      left commented out, run via the default runlab.do).

# Create work library
vlib work

# Compile Verilog
vlog "./alu.sv"
vlog "./cpucontrol.sv"
vlog "./datamem.sv"
vlog "./extend.sv"
vlog "./instructmem.sv"
vlog "./mux.sv"
vlog "./registerfile.sv"
vlog "./forwarding.sv"
vlog "./pipe_regs.sv"
vlog "./cpu.sv"
vlog "./cpu_testbench_extracredit.sv"

# Call vsim to invoke simulator
vsim -voptargs="+acc" -t 1ps -lib work cpu_testbench_extracredit

# Source the wave do file
do cpu_testbench_wave.do

# Set the window types
view wave
view structure
view signals

# Run the simulation
run -all

# End
