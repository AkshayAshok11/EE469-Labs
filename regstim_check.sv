// Self-checking wrapper around the given regstim.sv stimulus,
// per the lab's note: "alter the testing as necessary to make
// sure your unit works." The original regstim.sv is left untouched
// for the TA demo; this is an extra verification pass.

`timescale 1ns/10ps

module regstim_check();

	parameter ClockDelay = 5000;

	logic	[4:0] 	ReadRegister1, ReadRegister2, WriteRegister;
	logic [63:0]	WriteData;
	logic 			RegWrite, clk;
	logic [63:0]	ReadData1, ReadData2;

	integer i;
	integer errors;
	logic [63:0] expected;

	regfile dut (.ReadData1, .ReadData2, .WriteData,
					 .ReadRegister1, .ReadRegister2, .WriteRegister,
					 .RegWrite, .clk);

	initial $timeformat(-9, 2, " ns", 10);

	initial begin // Set up the clock
		clk <= 0;
		forever #(ClockDelay/2) clk <= ~clk;
	end

	initial begin
		errors = 0;

		// Try to write the value 0xA0 into register 31.
		// Register 31 should always be at the value of 0.
		RegWrite <= 5'd0;
		ReadRegister1 <= 5'd0;
		ReadRegister2 <= 5'd31;
		WriteRegister <= 5'd31;
		WriteData <= 64'h00000000000000A0;
		@(posedge clk);

		$display("%t Attempting overwrite of register 31, which should always be 0", $time);
		RegWrite <= 1;
		@(posedge clk);
		#1;
		if (ReadData2 !== 64'h0) begin
			$display("  FAIL: reg31 readback (RD2) = %h, expected 0", ReadData2);
			errors = errors + 1;
		end else
			$display("  PASS: reg31 stayed 0");

		// Write a value into each register.
		$display("%t Writing pattern to all registers.", $time);
		for (i=0; i<31; i=i+1) begin
			RegWrite <= 0;
			ReadRegister1 <= i-1;
			ReadRegister2 <= i;
			WriteRegister <= i;
			WriteData <= i*64'h0000010204080001;
			@(posedge clk);

			RegWrite <= 1;
			@(posedge clk);
		end

		// Go back and verify that the registers retained the data.
		$display("%t Checking pattern.", $time);
		for (i=0; i<32; i=i+1) begin
			RegWrite <= 0;
			ReadRegister1 <= i-1;
			ReadRegister2 <= i;
			WriteRegister <= i;
			WriteData <= i*64'h0000000000000100+i;   // RegWrite=0, so this must NOT be written
			@(posedge clk);
			#1;
			if (i == 31) begin
				if (ReadData2 !== 64'h0) begin
					$display("  FAIL: reg[%0d] (RD2) = %h, expected 0 (hardwired zero)", i, ReadData2);
					errors = errors + 1;
				end else
					$display("  PASS: reg[%0d] (RD2) = 0 as expected", i);
			end else begin
				expected = i*64'h0000010204080001;
				if (ReadData2 !== expected) begin
					$display("  FAIL: reg[%0d] (RD2) = %h, expected %h", i, ReadData2, expected);
					errors = errors + 1;
				end else
					$display("  PASS: reg[%0d] (RD2) = %h", i, ReadData2);
			end
		end

		if (errors == 0)
			$display("ALL REGFILE CHECKS PASSED");
		else
			$display("%0d FAILURES", errors);

		$finish;
	end
endmodule
