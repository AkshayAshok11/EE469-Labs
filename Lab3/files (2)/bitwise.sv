`timescale 1ns/10ps

module xor64 (out, in1, in2);
  output wire [63:0] out;
  input wire [63:0] in1, in2;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : operation
      xor #(0.05) g1(out[i], in1[i], in2[i]);
    end
  endgenerate
endmodule

module and64 (out, in1, in2);
  output wire [63:0] out;
  input wire [63:0] in1, in2;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : operation
      and #(0.05) g1(out[i], in1[i], in2[i]);
    end
  endgenerate
endmodule

module or64 (out, in1, in2);
  output wire [63:0] out;
  input wire [63:0] in1, in2;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : operation
      or #(0.05) g1(out[i], in1[i], in2[i]);
    end
  endgenerate
endmodule