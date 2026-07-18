# cpu_wave.do -- wave window setup for the single-cycle CPU testbench.
# Satisfies the submission requirement: "a wave file that illustrates all
# register contents, program counter, flags, data memory, clock and reset"
#
# NOTE: ModelSim/Questa represents SystemVerilog generate-block array
# indices with parentheses -- reg_bank(3), not reg_bank[3] -- because
# square brackets mean command substitution in Tcl. This file uses that
# syntax throughout.

add wave -divider "Clock / Reset"
add wave /cpu_testbench/clk
add wave /cpu_testbench/reset

add wave -divider "Fetch"
add wave -radix unsigned /cpu_testbench/dut/PC
add wave -radix binary   /cpu_testbench/dut/instr

add wave -divider "Control signals"
add wave /cpu_testbench/dut/ctrl/*

add wave -divider "Flags (N, V)"
add wave /cpu_testbench/dut/N_flag
add wave /cpu_testbench/dut/V_flag

add wave -divider "Register File (X0-X30, X31=XZR is hardwired 0)"
for {set i 0} {$i < 31} {incr i} {
    add wave -radix decimal /cpu_testbench/dut/rf/regs($i)
}

add wave -divider "ALU"
add wave -radix decimal /cpu_testbench/dut/main_alu/A
add wave -radix decimal /cpu_testbench/dut/main_alu/B
add wave /cpu_testbench/dut/main_alu/cntrl
add wave -radix decimal /cpu_testbench/dut/main_alu/result

# datamem's "mem" is a 1024-byte unpacked array (a memory, not a bus), so it
# doesn't belong in the waveform view the way a signal does. ModelSim can
# still show its full contents live via the Memory List window:
view memory
add memory /cpu_testbench/dut/dmem/mem

wave zoom full
configure wave -namecolwidth 250
configure wave -valuecolwidth 120
