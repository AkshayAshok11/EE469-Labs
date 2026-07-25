// Test bench for the single-cycle CPU
`timescale 1ns/10ps

// Runs whichever benchmark is currently selected in instructmem.sv (see
// its `define BENCHMARK line near the top of that file). To check a
// different benchmark, edit that line, recompile, and rerun -- same
// workflow as the lab handout describes. Check the result either in the
// wave window (see cpu_wave.do) or in the register/flag/memory dump this
// testbench prints at the end, against that benchmark's own "Expected
// results" comment.

module cpu_testbench ();

	parameter ClockDelay = 10000;	// Your regfile's gate delays (#50 per gate, several
									// decoder/mux levels deep) need a clock much longer
									// than you'd expect -- "a VERY long clock is fine."
	parameter NumCycles  = 800;	// Long enough for every provided benchmark to finish
									// (test11_Sort needs the most, ~601 cycles). Every
									// benchmark ends in a self-loop, so finishing early
									// just means idling there harmlessly for the rest.

	logic clk, reset;

	cpu dut (.clk, .reset);

	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

	// Force %t's to print in a nice format.
	initial $timeformat(-9, 2, " ns", 10);

	integer i;
	initial begin // Stimulus
		reset <= 1;
		@(posedge clk);
		@(posedge clk);
		reset <= 0;

		for (i = 0; i < NumCycles; i = i + 1)
			@(posedge clk);

		$display("---- Final register file ----");
		for (i = 0; i < 31; i = i + 1)
			$display("X%0d = %0d", i, $signed(dut.rf.regs[i]));
		$display("X31 = 0 (XZR, hardwired)");

		$display("---- Flags ----");
		$display("N = %b   V = %b", dut.N_flag, dut.V_flag);

		$display("---- Data memory (first 32 bytes) ----");
		for (i = 0; i < 32; i = i + 8)
			$display("Mem[%0d] = 0x%h%h%h%h%h%h%h%h", i,
				dut.dmem.mem[i+7], dut.dmem.mem[i+6], dut.dmem.mem[i+5], dut.dmem.mem[i+4],
				dut.dmem.mem[i+3], dut.dmem.mem[i+2], dut.dmem.mem[i+1], dut.dmem.mem[i]);

		$stop;
	end
endmodule
