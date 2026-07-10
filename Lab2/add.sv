


module add (in1, in2, out, carry);
  output wire out;
  input wire in1, in2;

  wire n_sel, a0, a1;

  xor a1(out, in1, in2);
  
endmodule