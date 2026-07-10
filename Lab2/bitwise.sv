module 64bitor (out, zero, negative, in1, in2);
  output wire [63:0] out;
  output wire zero, negative;
  input wire [63:0] in1, in2;

  assign zero = 1'b0;
  assign negative = 1'b0;

  genvar i;
  for (i = 0; i < 64; i = i + 1) begin : multi
    or #(0.05) g1(out[i], in1[i], in2[i]);
    or #(0.05) g2(zero, zero, out[i]);
  endgenerate
  
  or g3(negative, negative, out[0]);
endmodule



module 64bitand (out, zero, negative, in);
  output wire [63:0] out;
  output wire zero, negative;
  input wire [63:0] in1, in2;

  assign zero = 1'b0;
  assign negative = 1'b0;

  genvar i;
  for (i = 0; i < 64; i = i + 1) begin : multi
    and #(0.05) g1(out[i], in1[i], in2[i]);
    or #(0.05) g2(zero, zero, out[i]);
  endgenerate
  
  or g3(negative, negative, out[0]);
endmodule



module 64bitxor (out, zero, negative, in);
  output wire [63:0] out;
  output wire zero, negative;
  input wire [63:0] in1, in2;

  assign zero = 1'b0;
  assign negative = 1'b0;

  genvar i;
  for (i = 0; i < 64; i = i + 1) begin : multi
    xor #(0.05) g1(out[i], in1[i], in2[i]);
    or #(0.05) g2(zero, zero, out[i]);
  endgenerate
  
  or g3(negative, negative, out[0]);
endmodule