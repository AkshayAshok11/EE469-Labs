onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_testbench/clk
add wave -noupdate /cpu_testbench/reset
add wave -noupdate -radix unsigned /cpu_testbench/dut/PC
add wave -noupdate /cpu_testbench/dut/N_flag
add wave -noupdate /cpu_testbench/dut/V_flag
add wave -noupdate -radix unsigned /cpu_testbench/dut/dmem/mem
add wave -noupdate -radix unsigned /cpu_testbench/dut/rf/regs
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {46566342 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 100
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {167772160 ps}
