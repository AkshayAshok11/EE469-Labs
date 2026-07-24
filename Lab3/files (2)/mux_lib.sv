`timescale 1ns/10ps

// =====================================================================
// mux_lib.sv
//
// NOTE FOR THE STUDENT:
// Your lab1 regfile used a file with mux2_1/mux32_1/mux64x32to1, and your
// lab2 ALU used a *separate* file with its own mux2_1/mux8_1. Both files
// define "module mux2_1" identically -- if you vlog both files into the
// same project you'll get a duplicate-module compile error. This file
// replaces BOTH of your old mux files: it defines mux2_1 exactly once,
// then everything else (mux8_1, mux32_1, mux64x32to1) plus two new muxes
// the CPU datapath needs (mux64_2to1, mux5_2to1). Only vlog this file --
// don't also vlog your two original mux files.
// =====================================================================

module mux2_1 (out, i0, i1, sel);
  output wire out;
  input wire i0, i1, sel;
  wire n_sel, a0, a1;

  not #50 g1 (n_sel, sel);
  and #50 g2 (a0, i0, n_sel);
  and #50 g3 (a1, i1, sel);
  or  #50 g4 (out, a0, a1);
endmodule


module mux8_1 (
  output logic out,
  input  logic [7:0] in,
  input  logic [2:0] sel
);
  logic [3:0] lvl1;
  logic [1:0] lvl2;

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin : L1
      mux2_1 m (.out(lvl1[i]), .i0(in[2*i]), .i1(in[2*i+1]), .sel(sel[0]));
    end
    for (i = 0; i < 2; i = i + 1) begin : L2
      mux2_1 m (.out(lvl2[i]), .i0(lvl1[2*i]), .i1(lvl1[2*i+1]), .sel(sel[1]));
    end
  endgenerate

  mux2_1 mfinal (.out(out), .i0(lvl2[0]), .i1(lvl2[1]), .sel(sel[2]));
endmodule


module mux32_1 (
  output logic out,
  input  logic [31:0] in,
  input  logic [4:0] sel
);

  logic [15:0] lvl0;
  logic [7:0] lvl1;
  logic [3:0] lvl2;
  logic [1:0] lvl3;

  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : L0
      mux2_1 m (.out(lvl0[i]), .i0(in[2*i]), .i1(in[2*i+1]), .sel(sel[0]));
    end
    for (i = 0; i < 8; i = i + 1) begin : L1
      mux2_1 m (.out(lvl1[i]), .i0(lvl0[2*i]), .i1(lvl0[2*i+1]), .sel(sel[1]));
    end
    for (i = 0; i < 4; i = i + 1) begin : L2
      mux2_1 m (.out(lvl2[i]), .i0(lvl1[2*i]), .i1(lvl1[2*i+1]), .sel(sel[2]));
    end
    for (i = 0; i < 2; i = i + 1) begin : L3
      mux2_1 m (.out(lvl3[i]), .i0(lvl2[2*i]), .i1(lvl2[2*i+1]), .sel(sel[3]));
    end
  endgenerate

  mux2_1 mfinal (.out(out), .i0(lvl3[0]), .i1(lvl3[1]), .sel(sel[4]));

endmodule


module mux64x32to1 (
    output logic [63:0] out,
    input  logic [63:0] regs [0:31],
    input  logic [4:0] sel
);

  genvar b, r;
  generate
    for (b = 0; b < 64; b = b + 1) begin : bitslice
      logic [31:0] col;
      for (r = 0; r < 32; r = r + 1) begin : gather
        assign col[r] = regs[r][b];
      end
      mux32_1 m (.out(out[b]), .in(col), .sel(sel));
    end
  endgenerate

endmodule


// ---------------------------------------------------------------------
// New for lab3: a 64-bit-wide 2-to-1 mux, built the same gate-level way
// as everything else -- one mux2_1 per bit. Used all over the CPU
// datapath (ALUSrc, MemToReg, PCSrc, etc.)
// ---------------------------------------------------------------------
module mux64_2to1 (
  output logic [63:0] out,
  input  logic [63:0] i0, i1,
  input  logic sel
);
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : bit_mux
      mux2_1 m (.out(out[i]), .i0(i0[i]), .i1(i1[i]), .sel(sel));
    end
  endgenerate
endmodule


// ---------------------------------------------------------------------
// New for lab3: a 5-bit-wide 2-to-1 mux, same style. Used to pick
// register-file addresses (Reg2Loc mux, WriteRegister mux for BL).
// ---------------------------------------------------------------------
module mux5_2to1 (
  output logic [4:0] out,
  input  logic [4:0] i0, i1,
  input  logic sel
);
  genvar i;
  generate
    for (i = 0; i < 5; i = i + 1) begin : bit_mux
      mux2_1 m (.out(out[i]), .i0(i0[i]), .i1(i1[i]), .sel(sel));
    end
  endgenerate
endmodule
