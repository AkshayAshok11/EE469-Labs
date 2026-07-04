# runlab.do -- ModelSim/Questa script for the ARM 32x64 Register File (Lab #1)
#
# Usage (from ModelSim's Transcript window, with the working directory
# set to the folder containing these files):
#     do runlab.do
# or from the command line:
#     vsim -c -do runlab.do

quit -sim

# ---- Library setup ----
vlib work
vmap work work

# ---- Compile design files ----
# register.sv provides D_FF (unmodified) and reg64bit.
# mux.sv provides mux2_1, mux32_1, mux64x32to1.
# decoder.sv provides dec1_2 and dec5_32.
vlog -sv register.sv
vlog -sv mux.sv
vlog -sv decoder.sv
vlog -sv regfile.sv

# ---- Compile the official testbench ----
vlog -sv regstim.sv

# ---- Elaborate ----
# +acc keeps internal/generate-block signals visible in the wave viewer.
vsim -voptargs="+acc" work.regstim

# ---- Run ----
# The stimulus ends with $stop; run -all executes the entire test.
run -all

# ---- Tidy up the view ----
wave zoom full
configure wave -namecolwidth 220
configure wave -valuecolwidth 120
