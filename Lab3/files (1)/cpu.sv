`timescale 1ns/10ps

// =====================================================================
// cpu.sv -- 64-bit single-cycle LEGv8 CPU
//
// Instantiates instructmem and datamem internally, so the testbench
// only needs to drive clk/reset. Debug outputs (pc_out, instr_out) are
// exposed for convenience, but ModelSim can also reach every internal
// signal (registers, flags, memory contents) hierarchically once you
// add them to the wave window (see cpu_wave.do).
// =====================================================================

module cpu (
  input  logic        clk,
  input  logic        reset,
  output logic [63:0] pc_out,
  output logic [31:0] instr_out
);

  // ---------------- Program Counter ----------------
  logic [63:0] PC, PCNext, PCPlus4, BranchTarget, PCBranchStage;
  reg64bit pcreg (.q(PC), .d(PCNext), .en(1'b1), .clk(clk), .reset(reset));

  assign pc_out    = PC;
  assign instr_out = instr;

  // ---------------- Instruction fetch ----------------
  logic [31:0] instr;
  instructmem imem (.address(PC), .instruction(instr), .clk(clk));

  // ---------------- Control unit ----------------
  logic       Reg2Loc, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite;
  logic       UncondBranch, ZeroBranch, CondBranch, RegBranch, FlagWrite, IsBL;
  logic [2:0] ALUCntrl;
  logic [1:0] ImmSrc;

  control_unit ctrl (
    .instr(instr),
    .Reg2Loc(Reg2Loc), .ALUSrc(ALUSrc), .MemToReg(MemToReg),
    .RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite),
    .UncondBranch(UncondBranch), .ZeroBranch(ZeroBranch),
    .CondBranch(CondBranch), .RegBranch(RegBranch),
    .FlagWrite(FlagWrite), .ALUCntrl(ALUCntrl), .ImmSrc(ImmSrc), .IsBL(IsBL)
  );

  // ---------------- Immediate extend ----------------
  logic [63:0] ImmExt;
  imm_extend ext (.instr(instr), .ImmSrc(ImmSrc), .ImmExt(ImmExt));

  // ---------------- Register file ----------------
  logic [4:0]  ReadRegister1, ReadRegister2, WriteRegister;
  logic [63:0] ReadData1, ReadData2, WriteData;

  assign ReadRegister1 = instr[9:5];   // Rn -- also BR's target register

  mux5_2to1 reg2loc_mux (
    .out(ReadRegister2),
    .i0(instr[20:16]),  // Rm (R-format: ADDS/SUBS)
    .i1(instr[4:0]),    // Rt (STUR's store data, CBZ's test register)
    .sel(Reg2Loc)
  );

  mux5_2to1 writereg_mux (
    .out(WriteRegister),
    .i0(instr[4:0]),    // Rd/Rt
    .i1(5'd30),          // X30 = LR, forced for BL
    .sel(IsBL)
  );

  regfile rf (
    .ReadData1(ReadData1), .ReadData2(ReadData2),
    .WriteData(WriteData),
    .ReadRegister1(ReadRegister1), .ReadRegister2(ReadRegister2),
    .WriteRegister(WriteRegister),
    .RegWrite(RegWrite),
    .clk(clk), .reset(reset)
  );

  // ---------------- ALU ----------------
  logic [63:0] ALUBIn, ALUResult;
  logic ALU_negative, ALU_zero, ALU_overflow, ALU_carry;

  mux64_2to1 alusrc_mux (
    .out(ALUBIn), .i0(ReadData2), .i1(ImmExt), .sel(ALUSrc)
  );

  alu main_alu (
    .A(ReadData1), .B(ALUBIn), .cntrl(ALUCntrl),
    .result(ALUResult),
    .negative(ALU_negative), .zero(ALU_zero),
    .overflow(ALU_overflow), .carry_out(ALU_carry)
  );

  // ---------------- Flags (N, V) ----------------
  logic N_flag, V_flag;
  flagreg flags (
    .N_out(N_flag), .V_out(V_flag),
    .N_in(ALU_negative), .V_in(ALU_overflow),
    .FlagWrite(FlagWrite),
    .clk(clk), .reset(reset)
  );

  // ---------------- Data memory ----------------
  logic [63:0] MemReadData;
  datamem dmem (
    .address(ALUResult),
    .write_enable(MemWrite),
    .read_enable(MemRead),
    .write_data(ReadData2),
    .clk(clk),
    .xfer_size(4'd8),          // every LDUR/STUR in this ISA subset is a double-word
    .read_data(MemReadData)
  );

  // ---------------- Write-back mux ----------------
  logic [63:0] WriteDataStage;
  mux64_2to1 memtoreg_mux (
    .out(WriteDataStage), .i0(ALUResult), .i1(MemReadData), .sel(MemToReg)
  );
  mux64_2to1 bl_mux (
    .out(WriteData), .i0(WriteDataStage), .i1(PCPlus4), .sel(IsBL)
  );

  // ---------------- PC update ----------------
  add64 pc_adder   (.in1(PC), .in2(64'd4), .sum(PCPlus4));       // unused overflow/carry
  add64 br_adder   (.in1(PC), .in2(ImmExt), .sum(BranchTarget)); // unused overflow/carry

  logic BranchTaken;
  assign BranchTaken = UncondBranch | (ZeroBranch & ALU_zero) | (CondBranch & (N_flag != V_flag));

  mux64_2to1 pcsrc_mux (
    .out(PCBranchStage), .i0(PCPlus4), .i1(BranchTarget), .sel(BranchTaken)
  );
  mux64_2to1 pcbr_mux (
    .out(PCNext), .i0(PCBranchStage), .i1(ReadData1), .sel(RegBranch)
  );

endmodule
