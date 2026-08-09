`timescale 1ns/10ps

// Extra-credit control-hazard testbench.
//
// Before compiling this, uncomment `define FLUSH_ON_BRANCH near the top of
// cpu.sv -- same one-line-toggle convention as the `define BENCHMARK
// selection in instructmem.sv -- so every taken branch squashes its
// delay-slot instruction instead of always executing it.  Must also be run
// against test03_CbzB.arm (set the `define BENCHMARK line in
// instructmem.sv).  With FLUSH_ON_BRANCH left commented out (the default),
// this reproduces the required 1-delay-slot behavior (X2 ends at 4); with
// it uncommented, branches resolve dynamically with 0 delay slots, so X2
// should end at 0.

module cpu_testbench_extracredit();

  parameter ClockDelay = 5000;
  parameter NumCycles = 800;

  logic clk, reset;
  logic n_flag_out, v_flag_out;

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

//		test03_CbzB: X0/X1/X3/X4/X5 don't depend on FLUSH_ON_BRANCH; X2
//		(the delay-slot counter) is 4 with it off, 0 with it on.
`ifdef FLUSH_ON_BRANCH
    assert(dut.rf.regs[0] == 64'd1 && dut.rf.regs[1] == 64'd0 &&
           dut.rf.regs[2] == 64'd0 && dut.rf.regs[3] == 64'd1 &&
           dut.rf.regs[4] == 64'd31 && dut.rf.regs[5] == 64'd0);
`else
    assert(dut.rf.regs[0] == 64'd1 && dut.rf.regs[1] == 64'd0 &&
           dut.rf.regs[2] == 64'd4 && dut.rf.regs[3] == 64'd1 &&
           dut.rf.regs[4] == 64'd31 && dut.rf.regs[5] == 64'd0);
`endif

    $stop;
  end
endmodule
