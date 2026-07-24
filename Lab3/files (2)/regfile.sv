module regfile (
    output [63:0] ReadData1, ReadData2,
    input [63:0] WriteData,
    input [4:0] ReadRegister1, ReadRegister2, WriteRegister,
    input RegWrite,
    input clk, reset
);

  wire [31:0] write_en;
  wire [63:0] regs [0:31];

  dec5_32 decoder (
    .out(write_en), 
    .sel(WriteRegister), 
    .en(RegWrite)
  );

  genvar r;
  generate
    for (r = 0; r < 31; r = r + 1) begin : reg_bank
      reg64bit reg_inst (
          .q(regs[r]),
          .d(WriteData),
          .en(write_en[r]),
          .clk(clk),
	  .reset(reset)
      );
    end
  endgenerate

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
