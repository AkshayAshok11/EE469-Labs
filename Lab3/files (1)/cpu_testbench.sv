`timescale 1ns/10ps

// =====================================================================
// cpu_testbench.sv
//
// Top-level testbench for the single-cycle CPU. To run a different
// benchmark, edit the `define BENCHMARK line in instructmem.sv (as
// described in that file) and re-run.
//
// Clock: your regfile is built from #50-delay gates several decoder/mux
// levels deep, so the clock period here is intentionally huge -- this
// is the "a VERY long clock is fine" advice from the lab handout.
// Bump ClockDelay up further if you add more logic and start seeing X's.
//
// NumCycles: set generously so every benchmark program has time to
// finish. Bump this up if a program needs more instructions.
// =====================================================================

module cpu_testbench ();

  parameter ClockDelay = 10000;
  parameter NumCycles  = 40; // Bump this up if a benchmark needs more instructions
                             // than this to finish. Most of these benchmarks end
                             // in a self-loop (B to itself); if a program instead
                             // just falls off its last instruction, keeping
                             // NumCycles close to the program length avoids
                             // running PC past the end of instruction memory
                             // (harmless, but instructmem.sv's assertion will
                             // complain loudly once it does).

  logic        clk, reset;
  logic [63:0] pc_out;
  logic [31:0] instr_out;

  cpu dut (
    .clk(clk),
    .reset(reset),
    .pc_out(pc_out),
    .instr_out(instr_out)
  );

  // Force %t's to print in a nice format.
  initial $timeformat(-9, 2, " ns", 10);

  // ---- Clock ----
  initial begin
    clk = 0;
    forever #(ClockDelay/2) clk = ~clk;
  end

  // ---- VCD dump (portable wave dump in addition to the ModelSim .do file) ----
  initial begin
    $dumpfile("cpu.vcd");
    $dumpvars(0, cpu_testbench);
  end

  // ---- Reset + run ----
  integer i;
  initial begin
    reset = 1;
    @(posedge clk);
    @(posedge clk);
    reset = 0;

    for (i = 0; i < NumCycles; i = i + 1) begin
      @(posedge clk);
      #1; // let combinational logic settle before printing
      $display("%t  PC=%0d  instr=%b", $time, pc_out, instr_out);
    end

    // ---- Final register file dump ----
    $display("\n---- Final register file ----");
    for (i = 0; i < 31; i = i + 1)
      $display("X%0d = %0d (0x%h)", i, $signed(dut.rf.regs[i]), dut.rf.regs[i]);
    $display("X31 = 0 (XZR, hardwired)");

    $display("\n---- Flags ----");
    $display("N = %b   V = %b", dut.N_flag, dut.V_flag);

    $display("\n---- Data memory (first 64 bytes) ----");
    for (i = 0; i < 64; i = i + 8)
      $display("Mem[%0d..%0d] = 0x%h%h%h%h%h%h%h%h",
        i, i+7,
        dut.dmem.mem[i+7], dut.dmem.mem[i+6], dut.dmem.mem[i+5], dut.dmem.mem[i+4],
        dut.dmem.mem[i+3], dut.dmem.mem[i+2], dut.dmem.mem[i+1], dut.dmem.mem[i]);

    $stop;
  end
endmodule
