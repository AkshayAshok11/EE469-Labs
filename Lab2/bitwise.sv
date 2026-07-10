/*module 64bitor (out, zero, negative, in1, in2);
  output wire [63:0] out;
  output wire zero, negative;
  input wire [63:0] in1, in2;

  assign zero = 1'b0;
  assign negative = 1'b0;

  genvar i;
  generate
  for (i = 0; i < 64; i = i + 1) begin : multi
    or #(0.05) g1(out[i], in1[i], in2[i]);
    or #(0.05) g2(zero, zero, out[i]);
  endgenerate
  
  or g3(negative, negative, out[63]);
endmodule



module 64bitand (out, zero, negative, in1, in2);
  output wire [63:0] out;
  output wire zero, negative;
  input wire [63:0] in1, in2;

  assign zero = 1'b0;
  assign negative = 1'b0;

  genvar i;
  generate
  for (i = 0; i < 64; i = i + 1) begin : multi
    and #(0.05) g1(out[i], in1[i], in2[i]);
    or #(0.05) g2(zero, zero, out[i]);
  endgenerate

  or g3(negative, negative, out[63]);
endmodule



module 64bitxor (out, zero, negative, in1, in2);
  output wire [63:0] out;
  output wire zero, negative;
  input wire [63:0] in1, in2;

  assign zero = 1'b0;
  assign negative = 1'b0;

  genvar i;
  generate
  for (i = 0; i < 64; i = i + 1) begin : multi
    xor #(0.05) g1(out[i], in1[i], in2[i]);
    or #(0.05) g2(zero, zero, out[i]);
  endgenerate
  
  or g3(negative, negative, out[63]);
endmodule
*/
module xor64 (out, in1, in2);
  output wire [63:0] out;
  input wire [63:0] in1, in2;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : bit
      xor #(0.05) g1(out[i], in1[i], in2[i]);
    end
  endgenerate
endmodule

module and64 (out, in1, in2);
  output wire [63:0] out;
  input wire [63:0] in1, in2;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : bit
      and #(0.05) g1(out[i], in1[i], in2[i]);
    end
  endgenerate
endmodule

module or64 (out, in1, in2);
  output wire [63:0] out;
  input wire [63:0] in1, in2;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : bit
      or #(0.05) g1(out[i], in1[i], in2[i]);
    end
  endgenerate
endmodule

module not64 (out, in);
  output wire [63:0] out;
  input wire [63:0] in;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : bit
      not #(0.05) g1(out[i], in[i]);
    end
  endgenerate
endmodule

module zero64 (zero, in);
  output wire zero;
  input wire [63:0] in;

  wire [31:0] l1;
  wire [15:0] l2;
  wire [7:0]  l3;
  wire [3:0]  l4;
  wire [1:0]  l5;
  wire        orAll;

  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : s1
      or #(0.05) g(l1[i], in[2*i], in[2*i+1]);
    end
    for (i = 0; i < 16; i = i + 1) begin : s2
      or #(0.05) g(l2[i], l1[2*i], l1[2*i+1]);
    end
    for (i = 0; i < 8; i = i + 1) begin : s3
      or #(0.05) g(l3[i], l2[2*i], l2[2*i+1]);
    end
    for (i = 0; i < 4; i = i + 1) begin : s4
      or #(0.05) g(l4[i], l3[2*i], l3[2*i+1]);
    end
    for (i = 0; i < 2; i = i + 1) begin : s5
      or #(0.05) g(l5[i], l4[2*i], l4[2*i+1]);
    end
  endgenerate

  or  #(0.05) g6(orAll, l5[0], l5[1]);
  not #(0.05) g7(zero, orAll);
endmodule