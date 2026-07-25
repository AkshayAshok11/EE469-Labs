`timescale 1ns/10ps

module dec1_2 (out0, out1, in, en);
  output logic out0, out1;
  input  logic in, en;
  logic n_in;

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


module D_FF (q, d, reset, clk);
  output reg q;
  input d, reset, clk;
  always_ff @(posedge clk)
    if (reset)
      q <= 0;      // On reset, set to 0
    else
      q <= d;      // Otherwise out = d
endmodule


module reg64bit (q, d, en, reset, clk);
  output logic [63:0] q;
  input logic [63:0] d;
  input logic en, reset, clk;
  logic [63:0] d_next;

  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : reg_bit
        mux2_1 m (.out(d_next[i]), .i0(q[i]), .i1(d[i]), .sel(en));
        D_FF dff (.q(q[i]), .d(d_next[i]), .reset(reset), .clk(clk));
    end
  endgenerate
endmodule


module regfile (
    output [63:0] ReadData1, ReadData2,
    input [63:0] WriteData,
    input [4:0] ReadRegister1, ReadRegister2, WriteRegister,
    input RegWrite,
    input clk, reset
);

  logic [31:0] write_en;
  logic [63:0] regs [0:31];

  dec5_32 decoder (
    .out(write_en), 
    .sel(WriteRegister), 
    .en(RegWrite)
  );

  genvar r;
  generate
    for (r = 0; r < 31; r = r + 1) begin : reg_bank
      reg64bit reg_inst (
          .q(regs[r]),
          .d(WriteData),
          .en(write_en[r]),
          .clk(clk),
	  .reset(reset)
      );
    end
  endgenerate

  assign regs[31] = 64'b0;

  mux64x32to1 read1 (
      .out (ReadData1),
      .regs(regs),
      .sel (ReadRegister1)
  );

  mux64x32to1 read2 (
      .out (ReadData2),
      .regs(regs),
      .sel (ReadRegister2)
  );
endmodule