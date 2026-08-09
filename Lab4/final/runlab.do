# Create work library
vlib work

# Compile Verilog
#     All Verilog files that are part of this design should have
#     their own "vlog" line below.
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
vlog "./cpu_testbench.sv"

# Call vsim to invoke simulator
#     Make sure the last item on the line is the name of the
#     testbench module you want to execute.
vsim -voptargs="+acc" -t 1ps -lib work cpu_testbench

# Source the wave do file
#     This should be the file that sets up the signal window for
#     the module you are testing.
do cpu_testbench_wave.do

# Set the window types
view wave
view structure
view signals

# Run the simulation
run -all

# End
