// 64-bit-wide 32:1 multiplexor.
// regs holds the 32 register outputs (64 bits each) -- e.g. registers
// 0..31 of the register file, with regs[31] tied to zero for ARM's
// hardwired zero register.
// One mux32_1 per output bit, selecting bit b from all 32 registers.

module mux64x32to1 (
    output logic [63:0] out,
    input  logic [63:0] regs [0:31],
    input  logic [4:0]  sel
);

  genvar b, r;
  generate
    for (b = 0; b < 64; b = b + 1) begin : bitslice
      logic [31:0] col;
      for (r = 0; r < 32; r = r + 1) begin : gather
        assign col[r] = regs[r][b];   // pure wire connection, not logic
      end
      mux32_1 m (.out(out[b]), .in(col), .sel(sel));
    end
  endgenerate

endmodule
