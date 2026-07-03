// 1-bit-wide 32:1 multiplexor.
// Built as a binary tree of mux2_1: 5 levels (2^5 = 32 inputs),
// one level per bit of the 5-bit select signal.
// Total instances: 16 + 8 + 4 + 2 + 1 = 31 mux2_1's.

module mux32_1 (
    output logic        out,
    input  logic [31:0] in,
    input  logic [4:0]  sel
);

  logic [15:0] lvl0;
  logic [7:0]  lvl1;
  logic [3:0]  lvl2;
  logic [1:0]  lvl3;

  genvar i;
  generate
    // Level 0: 16 muxes, pick between pairs of the 32 inputs using sel[0]
    for (i = 0; i < 16; i = i + 1) begin : L0
      mux2_1 m (.out(lvl0[i]), .i0(in[2*i]), .i1(in[2*i+1]), .sel(sel[0]));
    end
    // Level 1: 8 muxes, using sel[1]
    for (i = 0; i < 8; i = i + 1) begin : L1
      mux2_1 m (.out(lvl1[i]), .i0(lvl0[2*i]), .i1(lvl0[2*i+1]), .sel(sel[1]));
    end
    // Level 2: 4 muxes, using sel[2]
    for (i = 0; i < 4; i = i + 1) begin : L2
      mux2_1 m (.out(lvl2[i]), .i0(lvl1[2*i]), .i1(lvl1[2*i+1]), .sel(sel[2]));
    end
    // Level 3: 2 muxes, using sel[3]
    for (i = 0; i < 2; i = i + 1) begin : L3
      mux2_1 m (.out(lvl3[i]), .i0(lvl2[2*i]), .i1(lvl2[2*i+1]), .sel(sel[3]));
    end
  endgenerate

  // Level 4: final mux, using sel[4] -> the 32:1 output
  mux2_1 mfinal (.out(out), .i0(lvl3[0]), .i1(lvl3[1]), .sel(sel[4]));

endmodule
