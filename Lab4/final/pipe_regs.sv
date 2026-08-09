`timescale 1ns/10ps

// Pipeline registers for the 5-stage (IF/ID/EX/MEM/WB) pipelined CPU.
// Each is just a bank of reg64bit/reg32bit/reg5bit/reg3bit/reg1bit
// flip-flops (always enabled -- this design has no stall/hazard-detection
// unit, so every stage always advances every cycle).  The IF/ID register
// additionally takes a "flush" select so a taken branch can force a bubble
// (all-zero = NOP instruction) into the slot instead of the instruction
// that was speculatively fetched.
//
// Field names follow the standard textbook pipeline-register diagram
// (IF/ID holds IR, PC+4; ID/EX holds PC+4, Read Data 1&2, SignExt(imm);
// EX/MEM holds ALUout; MEM/WB holds the value about to be written back)
// wherever this ISA's own datapath actually matches that diagram.  Two
// places it doesn't, on purpose:
//   - IF/ID also carries the branch instruction's own PC (not just PC+4),
//     because this ISA's branches are PC-relative to the branch itself,
//     not to PC+4 like the diagram's MIPS-style datapath.
//   - EX/MEM carries no "zero"/"adder output" fields, because branch/CBZ/BR
//     resolution happens a stage earlier, in ID (see cpu.sv) -- by the time
//     EX/MEM would be written, that decision has already been consumed.


module if_id_reg (
  output logic [31:0] IR,
  output logic [63:0] PC,
  output logic [63:0] PCPlus4,

  input  logic [31:0] IR_in,
  input  logic [63:0] PC_in,
  input  logic [63:0] PCPlus4_in,
  input  logic         flush,

  input  logic clk, reset
);
  logic [31:0] IR_d;
  mux32_2to1 flush_mux (.out(IR_d), .i0(IR_in), .i1(32'b0), .sel(flush));

  reg32bit r_ir       (.q(IR),       .d(IR_d),       .en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_pc       (.q(PC),       .d(PC_in),      .en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_pcplus4  (.q(PCPlus4),  .d(PCPlus4_in), .en(1'b1), .reset(reset), .clk(clk));
endmodule


module id_ex_reg (
  output logic        ALUSrc,
  output logic [2:0]  ALUCntrl,
  output logic        MemRead,
  output logic        MemWrite,
  output logic        MemToReg,
  output logic        RegWrite,
  output logic        IsBL,
  output logic        FlagWrite,
  output logic [63:0] ReadData1,
  output logic [63:0] ReadData2,
  output logic [63:0] ImmExt,
  output logic [4:0]  WriteRegister,
  output logic [63:0] PCPlus4,

  input  logic        ALUSrc_in,
  input  logic [2:0]  ALUCntrl_in,
  input  logic        MemRead_in,
  input  logic        MemWrite_in,
  input  logic        MemToReg_in,
  input  logic        RegWrite_in,
  input  logic        IsBL_in,
  input  logic        FlagWrite_in,
  input  logic [63:0] ReadData1_in,
  input  logic [63:0] ReadData2_in,
  input  logic [63:0] ImmExt_in,
  input  logic [4:0]  WriteRegister_in,
  input  logic [63:0] PCPlus4_in,

  input  logic clk, reset
);
  reg1bit  r_alusrc   (.q(ALUSrc),   .d(ALUSrc_in),   .en(1'b1), .reset(reset), .clk(clk));
  reg3bit  r_alucntrl (.q(ALUCntrl), .d(ALUCntrl_in), .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_memread  (.q(MemRead),  .d(MemRead_in),  .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_memwrite (.q(MemWrite), .d(MemWrite_in), .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_m2r      (.q(MemToReg), .d(MemToReg_in), .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_regwrite (.q(RegWrite), .d(RegWrite_in), .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_isbl     (.q(IsBL),     .d(IsBL_in),     .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_flagw    (.q(FlagWrite),.d(FlagWrite_in),.en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_rd1      (.q(ReadData1),.d(ReadData1_in),.en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_rd2      (.q(ReadData2),.d(ReadData2_in),.en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_imm      (.q(ImmExt),   .d(ImmExt_in),   .en(1'b1), .reset(reset), .clk(clk));
  reg5bit  r_wreg     (.q(WriteRegister), .d(WriteRegister_in), .en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_pcplus4  (.q(PCPlus4),  .d(PCPlus4_in),  .en(1'b1), .reset(reset), .clk(clk));
endmodule


module ex_mem_reg (
  output logic        MemRead,
  output logic        MemWrite,
  output logic        MemToReg,
  output logic        RegWrite,
  output logic        IsBL,
  output logic [63:0] ALUout,
  output logic [63:0] StoreData,
  output logic [4:0]  WriteRegister,
  output logic [63:0] PCPlus4,

  input  logic        MemRead_in,
  input  logic        MemWrite_in,
  input  logic        MemToReg_in,
  input  logic        RegWrite_in,
  input  logic        IsBL_in,
  input  logic [63:0] ALUout_in,
  input  logic [63:0] StoreData_in,
  input  logic [4:0]  WriteRegister_in,
  input  logic [63:0] PCPlus4_in,

  input  logic clk, reset
);
  reg1bit  r_memread  (.q(MemRead),  .d(MemRead_in),  .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_memwrite (.q(MemWrite), .d(MemWrite_in), .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_m2r      (.q(MemToReg), .d(MemToReg_in), .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_regwrite (.q(RegWrite), .d(RegWrite_in), .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_isbl     (.q(IsBL),     .d(IsBL_in),     .en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_aluout   (.q(ALUout),   .d(ALUout_in),   .en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_store    (.q(StoreData),.d(StoreData_in),.en(1'b1), .reset(reset), .clk(clk));
  reg5bit  r_wreg     (.q(WriteRegister), .d(WriteRegister_in), .en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_pcplus4  (.q(PCPlus4),  .d(PCPlus4_in),  .en(1'b1), .reset(reset), .clk(clk));
endmodule


// Holds "data read from memory and the ALU output" (kept as two separate
// fields, per the textbook diagram) plus what's needed to pick between
// them -- and, for BL, override both -- once WB actually runs.
module mem_wb_reg (
  output logic        RegWrite,
  output logic        MemToReg,
  output logic        IsBL,
  output logic [63:0] ALUout,
  output logic [63:0] ReadData,
  output logic [63:0] PCPlus4,
  output logic [4:0]  WriteRegister,

  input  logic        RegWrite_in,
  input  logic        MemToReg_in,
  input  logic        IsBL_in,
  input  logic [63:0] ALUout_in,
  input  logic [63:0] ReadData_in,
  input  logic [63:0] PCPlus4_in,
  input  logic [4:0]  WriteRegister_in,

  input  logic clk, reset
);
  reg1bit  r_regwrite (.q(RegWrite), .d(RegWrite_in), .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_m2r      (.q(MemToReg), .d(MemToReg_in), .en(1'b1), .reset(reset), .clk(clk));
  reg1bit  r_isbl     (.q(IsBL),     .d(IsBL_in),     .en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_aluout   (.q(ALUout),   .d(ALUout_in),   .en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_rdata    (.q(ReadData), .d(ReadData_in), .en(1'b1), .reset(reset), .clk(clk));
  reg64bit r_pcplus4  (.q(PCPlus4),  .d(PCPlus4_in),  .en(1'b1), .reset(reset), .clk(clk));
  reg5bit  r_wreg     (.q(WriteRegister), .d(WriteRegister_in), .en(1'b1), .reset(reset), .clk(clk));
endmodule
