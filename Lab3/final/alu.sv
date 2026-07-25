`timescale 1ns/10ps

module add (in1, in2, sum, cin, cout);
  output logic sum, cout;
  input logic cin, in1, in2;

  logic o0, o1, o3;

  xor #(0.05) g1(o0, in1, in2);
  and #(0.05) g2(o1, in1, in2);
  xor #(0.05) g3(sum, o0, cin);
  and #(0.05) g4(o3, o0, cin);
  or #(0.05) g5(cout, o3, o1);
endmodule


module addchain (in1, in2, sum, cin, cout);
  input  logic [63:0] in1, in2;
  input  logic cin;
  output logic [63:0] sum;
  output logic cout;

  logic [62:0] carry;
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
  input  logic [63:0] in1, in2;
  output logic [63:0] sum;
  output logic overflow, carry_out;

  addchain add (
    .in1(in1),
    .in2(in2),
    .sum(sum),
    .cin(1'b0),
    .cout(carry_out)
  );

  logic same_sign, diff_sum;
  xnor #(0.05) g_same (same_sign, in1[63], in2[63]);
  xor  #(0.05) g_diff (diff_sum,  in1[63], sum[63]);
  and  #(0.05) g_ovf  (overflow,  same_sign, diff_sum);
endmodule


module not64 (out, in);
  output logic [63:0] out;
  input logic [63:0] in;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : nots
      not #(0.05) g1(out[i], in[i]);
    end
  endgenerate
endmodule


module sub64 (in1, in2, diff, overflow, carry_out);
  input  logic [63:0] in1, in2;
  output logic [63:0] diff;
  output logic overflow, carry_out;

  logic [63:0] not_in2;
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

  logic same_sign, diff_sum;
  xnor #(0.05) g_same (same_sign, in1[63], not_in2[63]);
  xor  #(0.05) g_diff (diff_sum,  in1[63], diff[63]);
  and  #(0.05) g_ovf  (overflow,  same_sign, diff_sum);
endmodule


module xor64 (out, in1, in2);
  output logic [63:0] out;
  input logic [63:0] in1, in2;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : operation
      xor #(0.05) g1(out[i], in1[i], in2[i]);
    end
  endgenerate
endmodule


module and64 (out, in1, in2);
  output logic [63:0] out;
  input logic [63:0] in1, in2;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : operation
      and #(0.05) g1(out[i], in1[i], in2[i]);
    end
  endgenerate
endmodule


module or64 (out, in1, in2);
  output logic [63:0] out;
  input logic [63:0] in1, in2;
  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : operation
      or #(0.05) g1(out[i], in1[i], in2[i]);
    end
  endgenerate
endmodule


module zeroflag (zero, in);
  output logic zero;
  input logic [63:0] in;

  logic [15:0] l1;
  logic [3:0]  l2;
  logic orAll;

  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : L1
      or #(0.05) g1(l1[i], in[4*i], in[4*i+1], in[4*i+2], in[4*i+3]);
    end

    for (i = 0; i < 4; i = i + 1) begin : L2
      or #(0.05) g2(l2[i], l1[4*i], l1[4*i+1], l1[4*i+2], l1[4*i+3]);
    end
  endgenerate
  or #(0.05) g3(orAll, l2[0], l2[1], l2[2], l2[3]);
  not #(0.05) g4(zero, orAll);
endmodule


module negativeflag (negative, in);
  output logic negative;
  input logic [63:0] in;
  
  and #(0.05) g1 (negative, in[63], 1'b1);
endmodule


module alu (
  input  logic [63:0] A,
  input  logic [63:0] B,
  input  logic [2:0] cntrl,
  output logic [63:0] result,
  output logic negative,
  output logic zero,
  output logic overflow,
  output logic carry_out
);
  logic [63:0] out_add, out_sub, out_and, out_or, out_xor;
  logic ovf_add, ovf_sub;
  logic cout_add, cout_sub;

  add64 adder (
    .in1(A),
    .in2(B),
    .sum(out_add),
    .overflow(ovf_add),
    .carry_out(cout_add)
  );

  sub64 subber (
    .in1(A),
    .in2(B),
    .diff(out_sub),
    .overflow(ovf_sub),
    .carry_out(cout_sub)
  );

  and64 ander (
    .out(out_and),
    .in1(A),
    .in2(B)
  );

  or64 orer (
    .out(out_or),
    .in1(A),
    .in2(B)
  );

  xor64 xorer (
    .out(out_xor),
    .in1(A),
    .in2(B)
  );

  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : result_muxes
      logic [7:0] mux_in;

      assign mux_in[0] = B[i];
      assign mux_in[1] = 1'b0;
      assign mux_in[2] = out_add[i];
      assign mux_in[3] = out_sub[i];
      assign mux_in[4] = out_and[i];
      assign mux_in[5] = out_or[i];
      assign mux_in[6] = out_xor[i];
      assign mux_in[7] = 1'b0;

      mux8_1 m_res (
        .out(result[i]),
        .in(mux_in),
        .sel(cntrl)
      );
    end
  endgenerate

  logic [7:0] ovf_mux_in;
  assign ovf_mux_in[0] = 1'b0;
  assign ovf_mux_in[1] = 1'b0;
  assign ovf_mux_in[2] = ovf_add;
  assign ovf_mux_in[3] = ovf_sub;
  assign ovf_mux_in[4] = 1'b0;
  assign ovf_mux_in[5] = 1'b0;
  assign ovf_mux_in[6] = 1'b0;
  assign ovf_mux_in[7] = 1'b0;
    
  mux8_1 m_ovf (
    .out(overflow),
    .in(ovf_mux_in),
    .sel(cntrl)
  );

  logic [7:0] cout_mux_in;
  assign cout_mux_in[0] = 1'b0;
  assign cout_mux_in[1] = 1'b0;
  assign cout_mux_in[2] = cout_add;
  assign cout_mux_in[3] = cout_sub;
  assign cout_mux_in[4] = 1'b0;
  assign cout_mux_in[5] = 1'b0;
  assign cout_mux_in[6] = 1'b0;
  assign cout_mux_in[7] = 1'b0;
    
  mux8_1 m_cout (
    .out(carry_out),
    .in(cout_mux_in),
    .sel(cntrl)
  );

  zeroflag zflag (
    .zero(zero),
    .in(result)
  );

  negativeflag nflag (
    .negative(negative),
    .in(result)
  );
endmodule