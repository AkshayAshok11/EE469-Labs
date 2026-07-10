


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


module add8bit (in1, in2, sum, cout);
  output wire [7:0] sum;
  output wire cout;
  input wire [7:0] in1, in2;
  wire [7:0] carry;
  genvar i;
  generate
    for(i = 0; i < 8; i = i + 1) begin: adder
      if (i == 0) begin
        add a(in1[i], in2[i], sum[i], 1'b0, carry[i]);
      end
      else begin
        wire c;
        add a(in1[i], in2[i], sum[i], carry[i-1], carry[i]);
      end
    end
  endgenerate
  assign cout = carry[7];
endmodule