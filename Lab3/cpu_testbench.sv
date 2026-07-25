// Test bench for the single-cycle CPU
`timescale 1ns/10ps

// Runs every provided benchmark in turn and checks the final register/
// flag/memory state with assert, the same way alustim.sv checks the ALU:
// no manual eyeballing of a register dump, just pass/fail. Expected
// values below are copied from the "Expected results" comment at the
// top of each benchmark file.

module cpu_testbench ();

	parameter ClockDelay = 10000;	// Your regfile's gate delays (#50 per gate, several
									// decoder/mux levels deep) need a clock much longer
									// than you'd expect -- "a VERY long clock is fine."

	logic clk, reset;

	cpu dut (.clk, .reset);

	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

	// Force %t's to print in a nice format.
	initial $timeformat(-9, 2, " ns", 10);

	// Loads a new program into instruction memory, clears data memory so
	// each benchmark starts from a clean slate, then resets and runs the
	// CPU for the given number of cycles.
	integer m;
	task run_program(string filename, integer cycles);
		begin
			$readmemb(filename, dut.imem.mem);
			for (m = 0; m < 1024; m = m + 1)
				dut.dmem.mem[m] = 8'h00;

			reset = 1;
			@(posedge clk);
			@(posedge clk);
			reset = 0;

			repeat (cycles) @(posedge clk);
		end
	endtask

	initial begin

		$display("%t testing ADDI and B", $time);
		run_program("../benchmarks/test01_AddiB.arm", 15);
		assert(dut.rf.regs[0] == 0);
		assert(dut.rf.regs[1] == 1);
		assert(dut.rf.regs[2] == 2);
		assert(dut.rf.regs[3] == 3);
		assert(dut.rf.regs[4] == 4);

		$display("%t testing ADDS and SUBS", $time);
		run_program("../benchmarks/test02_AddsSubs.arm", 15);
		assert(dut.rf.regs[0] == 64'd1);
		assert(dut.rf.regs[1] == -64'd1);
		assert(dut.rf.regs[2] == 64'd2);
		assert(dut.rf.regs[3] == -64'd3);
		assert(dut.rf.regs[4] == -64'd2);
		assert(dut.rf.regs[5] == -64'd5);
		assert(dut.rf.regs[6] == 64'd0);
		assert(dut.rf.regs[7] == -64'd6);
		assert(dut.N_flag == 1 && dut.V_flag == 0);

		$display("%t testing CBZ and B", $time);
		run_program("../benchmarks/test03_CbzB.arm", 25);
		assert(dut.rf.regs[0] == 1);
		assert(dut.rf.regs[1] == 0);
		assert(dut.rf.regs[3] == 1);
		assert(dut.rf.regs[4] == 31);
		assert(dut.rf.regs[5] == 0);

		$display("%t testing LDUR and STUR", $time);
		run_program("../benchmarks/test04_LdurStur.arm", 15);
		assert(dut.rf.regs[0] == 1);
		assert(dut.rf.regs[1] == 2);
		assert(dut.rf.regs[2] == 3);
		assert(dut.rf.regs[3] == 8);
		assert(dut.rf.regs[4] == 11);
		assert(dut.rf.regs[5] == 1);
		assert(dut.rf.regs[6] == 2);
		assert(dut.rf.regs[7] == 3);
		assert(dut.dmem.mem[0] == 1);	// low byte is enough -- every expected value here fits in one byte
		assert(dut.dmem.mem[8] == 2);
		assert(dut.dmem.mem[16] == 3);

		$display("%t testing B.LT", $time);
		run_program("../benchmarks/test05_Blt.arm", 15);
		assert(dut.rf.regs[0] == 1);
		assert(dut.rf.regs[1] == 1);

		$display("%t testing BL and BR", $time);
		run_program("../benchmarks/test06_BlBr.arm", 20);
		assert(dut.rf.regs[0] == 1);
		assert(dut.rf.regs[1] == 0);
		assert(dut.rf.regs[3] == 1);
		assert(dut.rf.regs[4] == 52);
		assert(dut.rf.regs[5] == 64);
		assert(dut.rf.regs[29] == 20);
		assert(dut.rf.regs[30] == 68);

		$display("%t testing data-hazard forwarding cases", $time);
		run_program("../benchmarks/test10_forwarding.arm", 100);
		assert(dut.rf.regs[0] == 0);
		assert(dut.rf.regs[1] == 8);
		assert(dut.rf.regs[2] == 0);	// 0 on a single-cycle CPU (4 on a pipelined one)
		assert(dut.rf.regs[3] == 5);
		assert(dut.rf.regs[4] == 7);
		assert(dut.rf.regs[5] == 2);
		assert(dut.rf.regs[6] == -64'd2);
		assert(dut.rf.regs[7] == -64'd2);
		assert(dut.rf.regs[8] == 0);
		assert(dut.rf.regs[9] == 1);
		assert(dut.rf.regs[10] == -64'd4);
		assert(dut.rf.regs[14] == 5);
		assert(dut.rf.regs[15] == 8);
		assert(dut.rf.regs[16] == 9);
		assert(dut.rf.regs[17] == 1);
		assert(dut.rf.regs[18] == 99);
		assert(dut.dmem.mem[0] == 8);
		assert(dut.dmem.mem[8] == 5);

		$display("%t testing bubble sort", $time);
		run_program("../benchmarks/test11_Sort.arm", 700);
		assert(dut.rf.regs[11] == 1);
		assert(dut.rf.regs[12] == 2);
		assert(dut.rf.regs[13] == 3);
		assert(dut.rf.regs[14] == 4);
		assert(dut.rf.regs[15] == 5);
		assert(dut.rf.regs[16] == 6);
		assert(dut.rf.regs[17] == 7);
		assert(dut.rf.regs[18] == 8);
		assert(dut.rf.regs[19] == 9);
		assert(dut.rf.regs[20] == 10);

		$display("%t testing recursive Fibonacci", $time);
		run_program("../benchmarks/test12_Fibonacci.arm", 300);
		assert(dut.rf.regs[0] == 6);
		assert(dut.rf.regs[1] == 8);
		assert(dut.rf.regs[28] == 8);
		assert(dut.rf.regs[30] == 196);

		$display("%t All benchmarks passed.", $time);
		$stop;
	end
endmodule
