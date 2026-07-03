// Top-level 32x64 ARM register file.
// Wires together the three sub-blocks:
//   - decoder5to32: WriteRegister/RegWrite -> 31 individual write enables
//   - Register64 x31: the actual storage (registers 0..30)
//   - register 31: hardwired to zero, no flip-flops needed
//   - mux64x32to1 x2: ReadRegister1 -> ReadData1, ReadRegister2 -> ReadData2

module regfile (
    output [63:0] ReadData1, ReadData2,
    input  [63:0] WriteData,
    input  [4:0]  ReadRegister1, ReadRegister2, WriteRegister,
    input         RegWrite,
    input         clk
);

  wire [31:0] enable;              // one-hot write-enable lines from the decoder
  wire [63:0] regs [0:31];         // all 32 register outputs (regs[31] = hardwired 0)

  decoder5to32 dec (
      .enable(enable),
      .sel(WriteRegister),
      .write_en(RegWrite)
  );

  genvar r;
  generate
    for (r = 0; r < 31; r = r + 1) begin : reg_bank
      Register64 reg_inst (
          .q  (regs[r]),
          .d  (WriteData),
          .we (enable[r]),
          .clk(clk)
      );
    end
  endgenerate

  // Register 31 is hardwired to zero -- no flip-flops, no write enable needed.
  // This is a wire tied to a constant, which the lab explicitly allows.
  assign regs[31] = 64'b0;

  mux64x32to1 read1 (
      .out (ReadData1),
      .regs(regs),
      .sel (ReadRegister1)
  );

  mux64x32to1 read2 (
      .out (ReadData2),
      .regs(regs),
      .sel (ReadRegister2)
  );

endmodule
