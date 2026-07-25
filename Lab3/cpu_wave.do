# cpu_wave.do -- wave window setup for the single-cycle CPU testbench.
# Satisfies the submission requirement: "a wave file that illustrates all
# register contents, program counter, flags, data memory, clock and reset"
#
# NOTE: ModelSim/Questa represents SystemVerilog generate-block array
# indices with parentheses -- reg_bank(3), not reg_bank[3] -- because
# square brackets mean command substitution in Tcl. This file uses that
# syntax throughout.
#
# NOTE: PC and the flags are read here through cpu.sv's pc_out/instr_out/
# n_flag_out/v_flag_out output ports rather than the internal PC/N_flag/
# V_flag wires. A plain internal wire that just feeds straight into
# something else with no real logic of its own (which is exactly what PC
# and the flags do) is a common target for ModelSim's optimizer to delete
# even with +acc set, depending on tool version -- a port on the other
# hand can never be optimized away, so this is the safer reference.

add wave -divider "Clock / Reset"
add wave /cpu_testbench/clk
add wave /cpu_testbench/reset

add wave -divider "Fetch"
add wave -radix unsigned /cpu_testbench/dut/pc_out
add wave -radix binary   /cpu_testbench/dut/instr_out

add wave -divider "Control signals"
add wave /cpu_testbench/dut/ctrl/*

add wave -divider "Flags (N, V)"
add wave /cpu_testbench/dut/n_flag_out
add wave /cpu_testbench/dut/v_flag_out

add wave -divider "Register File (X0-X30, X31=XZR is hardwired 0)"
for {set i 0} {$i < 31} {incr i} {
    add wave -radix decimal /cpu_testbench/dut/rf/regs($i)
}

add wave -divider "ALU"
add wave -radix decimal /cpu_testbench/dut/main_alu/A
add wave -radix decimal /cpu_testbench/dut/main_alu/B
add wave /cpu_testbench/dut/main_alu/cntrl
add wave -radix decimal /cpu_testbench/dut/main_alu/result

# Data memory, first 32 bytes, shown directly as wave-pane signals (not
# just the separate Memory List window) so it actually shows up in
# whatever you export/screenshot as "the wave file."
add wave -divider "Data Memory (first 32 bytes)"
for {set i 0} {$i < 32} {incr i} {
    add wave -radix hexadecimal /cpu_testbench/dut/dmem/mem($i)
}

# Bonus: ModelSim can also show the *entire* memory live in a dedicated
# window, which is handy while debugging even though it isn't part of
# the wave pane itself:
view memory
add memory /cpu_testbench/dut/dmem/mem

wave zoom full
configure wave -namecolwidth 250
configure wave -valuecolwidth 120
