module dec1_2 (out0, out1, in, en);
  output wire out0, out1;
  input  wire in, en;
  wire n_in;

  not #50 g1 (n_in, in);
  and #50 g2 (out0, en, n_in);
  and #50 g3 (out1, en, in);
endmodule



module dec5_32 (
  output logic [31:0] out,
  input logic [4:0] sel,
  input logic en
);
  logic [1:0] lvl3;
  logic [3:0] lvl2;
  logic [7:0] lvl1;
  logic [15:0] lvl0;

  dec1_2 dtop (.out0(lvl3[0]), .out1(lvl3[1]), .in(sel[4]), .en(en));

  genvar i;
  generate
    for (i = 0; i < 2; i = i + 1) begin : L3
      dec1_2 d (.out0(lvl2[2*i]), .out1(lvl2[2*i+1]), .in(sel[3]), .en(lvl3[i]));
    end
    for (i = 0; i < 4; i = i + 1) begin : L2
      dec1_2 d (.out0(lvl1[2*i]), .out1(lvl1[2*i+1]), .in(sel[2]), .en(lvl2[i]));
    end
    for (i = 0; i < 8; i = i + 1) begin : L1
      dec1_2 d (.out0(lvl0[2*i]), .out1(lvl0[2*i+1]), .in(sel[1]), .en(lvl1[i]));
    end
    for (i = 0; i < 16; i = i + 1) begin : L0
      dec1_2 d (.out0(out[2*i]), .out1(out[2*i+1]), .in(sel[0]), .en(lvl0[i]));
    end
  endgenerate
endmodule
