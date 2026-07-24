`timescale 1ns/10ps

module alu (
  input  wire [63:0] A,
  input  wire [63:0] B,
  input  wire [2:0] cntrl,
  output wire [63:0] result,
  output wire negative,
  output wire zero,
  output wire overflow,
  output wire carry_out
);
  wire [63:0] out_add, out_sub, out_and, out_or, out_xor;
  wire ovf_add, ovf_sub;
  wire cout_add, cout_sub;

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
      wire [7:0] mux_in;

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

  wire [7:0] ovf_mux_in;
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

  wire [7:0] cout_mux_in;
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