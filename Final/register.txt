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



