`timescale 1ns/10ps

module cpu_testbench();

	parameter ClockDelay = 5000;
	parameter NumCycles = 800;

	logic			clk, reset;
	logic			n_flag_out, v_flag_out;

	integer i;

	cpu dut (.clk, .reset, .n_flag_out, .v_flag_out);

	initial $timeformat(-9, 2, " ns", 10);

	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

	initial begin
		reset <= 1;
		@(posedge clk);
		@(posedge clk);
		reset <= 0;

		$display("%t Reset released, running program.", $time);
		for (i=0; i<NumCycles; i=i+1) begin
			@(posedge clk);
		end

		$display("%t Stopped after %0d cycles.  Final PC = %0d (0x%h)", $time, NumCycles, dut.PC, dut.PC);

//		test01_AddiB
//		assert(dut.rf.regs[0] == 64'd0 && dut.rf.regs[1] == 64'd1 &&
//		       dut.rf.regs[2] == 64'd2 && dut.rf.regs[3] == 64'd3 &&
//		       dut.rf.regs[4] == 64'd4);
//
//		test02_AddsSubs
//		assert(dut.rf.regs[0] == 64'd1  && dut.rf.regs[1] == -64'd1 &&
//		       dut.rf.regs[2] == 64'd2  && dut.rf.regs[3] == -64'd3 &&
//		       dut.rf.regs[4] == -64'd2 && dut.rf.regs[5] == -64'd5 &&
//		       dut.rf.regs[6] == 64'd0  && dut.rf.regs[7] == -64'd6 &&
//		       dut.N_flag == 1 && dut.V_flag == 0);
//
//		test03_CbzB
//		assert(dut.rf.regs[0] == 64'd1 && dut.rf.regs[1] == 64'd0 &&
//		       dut.rf.regs[2] == 64'd0 && dut.rf.regs[3] == 64'd1 &&
//		       dut.rf.regs[4] == 64'd31 && dut.rf.regs[5] == 64'd0);
//
//		test04_LdurStur
//		assert(dut.rf.regs[0] == 64'd1 && dut.rf.regs[1] == 64'd2 &&
//		       dut.rf.regs[2] == 64'd3 && dut.rf.regs[3] == 64'd8 &&
//		       dut.rf.regs[4] == 64'd11 && dut.rf.regs[5] == 64'd1 &&
//		       dut.rf.regs[6] == 64'd2 && dut.rf.regs[7] == 64'd3 &&
//		       {dut.dmem.mem[7],dut.dmem.mem[6],dut.dmem.mem[5],dut.dmem.mem[4],
//		        dut.dmem.mem[3],dut.dmem.mem[2],dut.dmem.mem[1],dut.dmem.mem[0]} == 64'd1 &&
//		       {dut.dmem.mem[15],dut.dmem.mem[14],dut.dmem.mem[13],dut.dmem.mem[12],
//		        dut.dmem.mem[11],dut.dmem.mem[10],dut.dmem.mem[9],dut.dmem.mem[8]} == 64'd2 &&
//		       {dut.dmem.mem[23],dut.dmem.mem[22],dut.dmem.mem[21],dut.dmem.mem[20],
//		        dut.dmem.mem[19],dut.dmem.mem[18],dut.dmem.mem[17],dut.dmem.mem[16]} == 64'd3);
//
//		test05_Blt
//		assert(dut.rf.regs[0] == 64'd1 && dut.rf.regs[1] == 64'd1);
//
//		test06_BlBr
//		assert(dut.rf.regs[0] == 64'd1 && dut.rf.regs[1] == 64'd0 &&
//		       dut.rf.regs[2] == 64'd0 && dut.rf.regs[3] == 64'd1 &&
//		       dut.rf.regs[4] == 64'd52 && dut.rf.regs[5] == 64'd64 &&
//		       dut.rf.regs[29] == 64'd20 && dut.rf.regs[30] == 64'd68);
//
//		test10_forwarding
//		assert(dut.rf.regs[0] == 64'd0  && dut.rf.regs[1] == 64'd8 &&
//		       dut.rf.regs[3] == 64'd5  && dut.rf.regs[4] == 64'd7 &&
//		       dut.rf.regs[5] == 64'd2  && dut.rf.regs[6] == -64'd2 &&
//		       dut.rf.regs[7] == -64'd2 && dut.rf.regs[8] == 64'd0 &&
//		       dut.rf.regs[9] == 64'd1  && dut.rf.regs[10] == -64'd4 &&
//		       dut.rf.regs[14] == 64'd5 && dut.rf.regs[15] == 64'd8 &&
//		       dut.rf.regs[16] == 64'd9 && dut.rf.regs[17] == 64'd1 &&
//		       dut.rf.regs[18] == 64'd99 &&
//		       {dut.dmem.mem[7],dut.dmem.mem[6],dut.dmem.mem[5],dut.dmem.mem[4],
//		        dut.dmem.mem[3],dut.dmem.mem[2],dut.dmem.mem[1],dut.dmem.mem[0]} == 64'd8 &&
//		       {dut.dmem.mem[15],dut.dmem.mem[14],dut.dmem.mem[13],dut.dmem.mem[12],
//		        dut.dmem.mem[11],dut.dmem.mem[10],dut.dmem.mem[9],dut.dmem.mem[8]} == 64'd5);
//
//		test11_Sort (bubble sort should leave the array 1..10 in order)
//		assert(dut.rf.regs[11] == 64'd1 && dut.rf.regs[12] == 64'd2 &&
//		       dut.rf.regs[13] == 64'd3 && dut.rf.regs[14] == 64'd4 &&
//		       dut.rf.regs[15] == 64'd5 && dut.rf.regs[16] == 64'd6 &&
//		       dut.rf.regs[17] == 64'd7 && dut.rf.regs[18] == 64'd8 &&
//		       dut.rf.regs[19] == 64'd9 && dut.rf.regs[20] == 64'd10);
//
//		test12_Fibonacci
		assert(dut.rf.regs[0] == 64'd6 && dut.rf.regs[1] == 64'd8 &&
		       dut.rf.regs[28] == 64'd8 && dut.rf.regs[30] == 64'd196);

		$stop;
	end
endmodule