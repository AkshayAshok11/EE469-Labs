`timescale 1ns/10ps

// Stores the Negative and oVerflow flags produced by the ALU, but only
// latches new values when FlagWrite is asserted (i.e. on ADDS/SUBS).
// Built exactly like reg64bit (D_FF + mux2_1 per bit) just narrower,
// so it reuses the same verified primitives instead of a plain
// behavioral always_ff register.
module flagreg (
  output logic N_out, V_out,
  input  logic N_in, V_in,
  input  logic FlagWrite,
  input  logic clk, reset
);
  logic N_next, V_next;

  mux2_1 mN (.out(N_next), .i0(N_out), .i1(N_in), .sel(FlagWrite));
  mux2_1 mV (.out(V_next), .i0(V_out), .i1(V_in), .sel(FlagWrite));

  D_FF dffN (.q(N_out), .d(N_next), .reset(reset), .clk(clk));
  D_FF dffV (.q(V_out), .d(V_next), .reset(reset), .clk(clk));
endmodule
