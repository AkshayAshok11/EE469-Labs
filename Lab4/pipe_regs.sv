`timescale 1ns/10ps

// Pipeline registers for the 5-stage (IF/ID/EX/MEM/WB) pipelined CPU.
// Each is just a bank of reg64bit/regNbit flip-flops (always enabled --
// this design has no stall/hazard-detection unit, so every stage always
// advances every cycle).  The IF/ID register additionally take a "flush"
// select so a taken branch can force a bubble (all-zero = NOP instruction)
// into the slot instead of the instruction that was speculatively fetched.


module if_id_reg (
  output logic [31:0] instr,
  output logic [63:0] PC,
  output logic [63:0] PCPlus4,

  input  logic [31:0] instr_in,
  input  logic [63:0] PC_in,
  input  logic [63:0] PCPlus4_in,
  input  logic         flush,

  input  logic clk, reset
);
  logic [31:0] instr_d;
  mux32_2to1 flush_mux (.out(instr_d), .i0(instr_in), .i1(32'b0), .sel(flush));

  regNbit #(32) r_instr    (.q(instr),    .d(instr_d),    .en(1'b1), .reset(reset), .clk(clk));
  reg64bit      r_pc       (.q(PC),       .d(PC_in),      .en(1'b1), .reset(reset), .clk(clk));
  reg64bit      r_pcplus4  (.q(PCPlus4),  .d(PCPlus4_in), .en(1'b1), .reset(reset), .clk(clk));
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
  regNbit #(1) r_alusrc   (.q(ALUSrc),   .d(ALUSrc_in),   .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(3) r_alucntrl (.q(ALUCntrl), .d(ALUCntrl_in), .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(1) r_memread  (.q(MemRead),  .d(MemRead_in),  .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(1) r_memwrite (.q(MemWrite), .d(MemWrite_in), .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(1) r_m2r      (.q(MemToReg), .d(MemToReg_in), .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(1) r_regwrite (.q(RegWrite), .d(RegWrite_in), .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(1) r_isbl     (.q(IsBL),     .d(IsBL_in),     .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(1) r_flagw    (.q(FlagWrite),.d(FlagWrite_in),.en(1'b1), .reset(reset), .clk(clk));
  reg64bit     r_rd1      (.q(ReadData1),.d(ReadData1_in),.en(1'b1), .reset(reset), .clk(clk));
  reg64bit     r_rd2      (.q(ReadData2),.d(ReadData2_in),.en(1'b1), .reset(reset), .clk(clk));
  reg64bit     r_imm      (.q(ImmExt),   .d(ImmExt_in),   .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(5) r_wreg     (.q(WriteRegister), .d(WriteRegister_in), .en(1'b1), .reset(reset), .clk(clk));
  reg64bit     r_pcplus4  (.q(PCPlus4),  .d(PCPlus4_in),  .en(1'b1), .reset(reset), .clk(clk));
endmodule


module ex_mem_reg (
  output logic        MemRead,
  output logic        MemWrite,
  output logic        MemToReg,
  output logic        RegWrite,
  output logic        IsBL,
  output logic [63:0] ALUResult,
  output logic [63:0] StoreData,
  output logic [4:0]  WriteRegister,
  output logic [63:0] PCPlus4,

  input  logic        MemRead_in,
  input  logic        MemWrite_in,
  input  logic        MemToReg_in,
  input  logic        RegWrite_in,
  input  logic        IsBL_in,
  input  logic [63:0] ALUResult_in,
  input  logic [63:0] StoreData_in,
  input  logic [4:0]  WriteRegister_in,
  input  logic [63:0] PCPlus4_in,

  input  logic clk, reset
);
  regNbit #(1) r_memread  (.q(MemRead),  .d(MemRead_in),  .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(1) r_memwrite (.q(MemWrite), .d(MemWrite_in), .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(1) r_m2r      (.q(MemToReg), .d(MemToReg_in), .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(1) r_regwrite (.q(RegWrite), .d(RegWrite_in), .en(1'b1), .reset(reset), .clk(clk));
  regNbit #(1) r_isbl     (.q(IsBL),     .d(IsBL_in),     .en(1'b1), .reset(reset), .clk(clk));
  reg64bit     r_alures   (.q(ALUResult),.d(ALUResult_in),.en(1'b1), .reset(reset), .clk(clk));
  reg64bit     r_store    (.q(StoreData),.d(StoreData_in),.en(1'b1), .reset(reset), .clk(clk));
  regNbit #(5) r_wreg     (.q(WriteRegister), .d(WriteRegister_in), .en(1'b1), .reset(reset), .clk(clk));
  reg64bit     r_pcplus4  (.q(PCPlus4),  .d(PCPlus4_in),  .en(1'b1), .reset(reset), .clk(clk));
endmodule


module mem_wb_reg (
  output logic        RegWrite,
  output logic [63:0] WriteData,
  output logic [4:0]  WriteRegister,

  input  logic        RegWrite_in,
  input  logic [63:0] WriteData_in,
  input  logic [4:0]  WriteRegister_in,

  input  logic clk, reset
);
  regNbit #(1) r_regwrite (.q(RegWrite), .d(RegWrite_in), .en(1'b1), .reset(reset), .clk(clk));
  reg64bit     r_wdata    (.q(WriteData),.d(WriteData_in),.en(1'b1), .reset(reset), .clk(clk));
  regNbit #(5) r_wreg     (.q(WriteRegister), .d(WriteRegister_in), .en(1'b1), .reset(reset), .clk(clk));
endmodule
