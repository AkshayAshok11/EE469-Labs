module mux2_1 (out, i0, i1, sel);
  output wire out;
  input wire i0, i1, sel;
  wire n_sel, a0, a1;

  not #0.05 g1 (n_sel, sel);
  and #0.05 g2 (a0, i0, n_sel);
  and #0.05 g3 (a1, i1, sel);
  or  #0.05 g4 (out, a0, a1);
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
    for (i = 0; i < 4; i = i + 1) begin : L2
      mux2_1 m (.out(lvl1[i]), .i0(in[2*i]), .i1(in[2*i+1]), .sel(sel[0]));
    end
    for (i = 0; i < 2; i = i + 1) begin : L3
      mux2_1 m (.out(lvl2[i]), .i0(lvl1[2*i]), .i1(lvl1[2*i+1]), .sel(sel[1]));
    end
  endgenerate

  mux2_1 mfinal (.out(out), .i0(lvl2[0]), .i1(lvl2[1]), .sel(sel[2]));
endmodule