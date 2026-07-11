module zeroflag (zero, in);
  output wire zero;
  input wire [63:0] in;

  wire [16:0] l1;
  wire [4:0] l2;
  wire orAll;

  genvar i;
  generate
    for (i = 0; i < 16; i = i + 1) begin : L1
      or #(0.05) g1(l1[i], in[i], in[2*1], in[3*i], in[4*i]);
    end
    for (i = 0; i < 4; i = i + 1) begin : L2
      or #(0.05) g2(l2[i], l1[i], l1[2*1], l1[3*i], l1[4*i]);
    end
  endgenerate

  or #(0.05) g3(orAll, l2[0], l2[1], l2[2], l2[3]);
  not #(0.05) g4(zero, orAll);
endmodule



module negativeflag (negative, in);
  output wire zero;
  input wire [63:0] in;
  
  and #(0.05) g1 (negative, in[0], 1'b1);
endmodule