# runlab.do -- ModelSim/Questa script for the single-cycle LEGv8 CPU (Lab #3)
#
# Usage: vsim -c -do runlab.do
# or, from ModelSim's Transcript window (working dir = folder with these files):
#     do runlab.do

quit -sim

# ---- Library setup ----
vlib work
vmap work work

# ---- Compile design files ----
# Order matters: lower-level modules first.
vlog -sv register.sv      ;# D_FF, reg64bit
vlog -sv mux_lib.sv       ;# mux2_1, mux8_1, mux32_1, mux64x32to1, mux64_2to1, mux5_2to1
                           ;#   (replaces your two old mux files -- do NOT also
                           ;#    vlog the originals, mux2_1 would be redefined)
vlog -sv decoder.sv       ;# dec1_2, dec5_32
vlog -sv regfile.sv       ;# regfile (lab 1)

vlog -sv add_sub.sv       ;# add, addchain, add64, not64, sub64
vlog -sv bitwise.sv       ;# xor64, and64, or64
vlog -sv flags.sv         ;# zeroflag, negativeflag
vlog -sv alu.sv           ;# alu (lab 2)

vlog -sv flagreg.sv       ;# N/V flag storage (lab 3, new)
vlog -sv imm_extend.sv    ;# immediate sign/zero-extend unit (lab 3, new)
vlog -sv control_unit.sv  ;# main control unit (lab 3, new)

vlog -sv math.sv          ;# provided (mult/shifter) -- not used by this ISA subset,
                           ;#   included since it was part of the provided files
vlog -sv datamem.sv        ;# provided
vlog -sv instructmem.sv    ;# provided -- edit its `define BENCHMARK to pick a program

vlog -sv cpu.sv            ;# top-level CPU datapath (lab 3, new)

# ---- Compile the testbench ----
vlog -sv cpu_testbench.sv

# ---- Elaborate ----
# +acc keeps internal/generate-block signals visible in the wave viewer.
vsim -voptargs="+acc" work.cpu_testbench

# ---- Source the wave setup ----
do cpu_wave.do

# ---- Set the window types ----
view wave
view structure
view signals

# ---- Run ----
run -all

# ---- Tidy up the view ----
wave zoom full
