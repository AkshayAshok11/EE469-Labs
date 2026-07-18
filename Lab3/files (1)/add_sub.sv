`timescale 1ns/10ps

module add (in1, in2, sum, cin, cout);
  output wire sum, cout;
  input wire cin, in1, in2;

  wire o0, o1, o3;

  xor #(0.05) g1(o0, in1, in2);
  and #(0.05) g2(o1, in1, in2);
  xor #(0.05) g3(sum, o0, cin);
  and #(0.05) g4(o3, o0, cin);
  or #(0.05) g5(cout, o3, o1);

endmodule


module addchain (in1, in2, sum, cin, cout);
  input  wire [63:0] in1, in2;
  input  wire cin;
  output wire [63:0] sum;
  output wire cout;

  wire [62:0] carry;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : add
      if (i == 0)
        add a(.in1(in1[i]), .in2(in2[i]), .sum(sum[i]), .cin(cin), .cout(carry[i]));
      else if (i == 63)
        add a(.in1(in1[i]), .in2(in2[i]), .sum(sum[i]), .cin(carry[i-1]), .cout(cout));
      else
        add a(.in1(in1[i]), .in2(in2[i]), .sum(sum[i]), .cin(carry[i-1]), .cout(carry[i]));
    end
  endgenerate
endmodule



module add64 (in1, in2, sum, overflow, carry_out);
  input  wire [63:0] in1, in2;
  output wire [63:0] sum;
  output wire overflow, carry_out;

  addchain add (
    .in1(in1),
    .in2(in2),
    .sum(sum),
    .cin(1'b0),
    .cout(carry_out)
  );

  wire same_sign, diff_sum;
  xnor #(0.05) g_same (same_sign, in1[63], in2[63]);
  xor  #(0.05) g_diff (diff_sum,  in1[63], sum[63]);
  and  #(0.05) g_ovf  (overflow,  same_sign, diff_sum);
endmodule




module not64 (out, in);
  output wire [63:0] out;
  input wire [63:0] in;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : nots
      not #(0.05) g1(out[i], in[i]);
    end
  endgenerate
endmodule


module sub64 (in1, in2, diff, overflow, carry_out);
  input  wire [63:0] in1, in2;
  output wire [63:0] diff;
  output wire overflow, carry_out;

  wire [63:0] not_in2;
  not64 inv (
    .out(not_in2),
    .in(in2)
  );

  addchain add (
    .in1(in1),
    .in2(not_in2),
    .sum(diff),
    .cin(1'b1),
    .cout(carry_out)
  );

  wire same_sign, diff_sum;
  xnor #(0.05) g_same (same_sign, in1[63], not_in2[63]);
  xor  #(0.05) g_diff (diff_sum,  in1[63], diff[63]);
  and  #(0.05) g_ovf  (overflow,  same_sign, diff_sum);
endmodule