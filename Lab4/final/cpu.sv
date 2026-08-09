`timescale 1ns/10ps


// 5-stage pipelined LEGv8 CPU (IF/ID/EX/MEM/WB).
//
// Branch/CBZ/BR resolution happens in ID (one stage ahead of the shared
// ALU in EX) so that exactly one already-fetched instruction -- the
// architectural delay slot -- executes after every taken load or branch,
// with no stall/hazard-detection unit and (by default) no flush.
//
// FLUSH_ON_BRANCH (extra credit, off by default): uncomment the `define
// below to squash the instruction fetched into the delay slot of a taken
// branch (forced to an all-zero NOP) instead of executing it, giving
// dynamic (0-delay-slot) branch resolution.  Leave it commented out to
// reproduce the required 1-delay-slot behavior expected by the standard
// testbenches -- same one-line-toggle convention as the `define BENCHMARK
// selection in instructmem.sv.
//`define FLUSH_ON_BRANCH

module cpu (
  input  logic        clk,
  input  logic        reset,
  output logic        n_flag_out,
  output logic        v_flag_out
);

  //======================================================================
  // IF stage
  //======================================================================
  logic [63:0] PC, PCNext;
  reg64bit pcreg (.q(PC), .d(PCNext), .en(1'b1), .clk(clk), .reset(reset));

  logic [31:0] IR_fetched;
  instructmem imem (.address(PC), .instruction(IR_fetched), .clk(clk));

  logic [63:0] PCPlus4_IF;
  add64 pc_adder (.in1(PC), .in2(64'd4), .sum(PCPlus4_IF)); // unused overflow/carry

  logic flush_if_id;

  logic [31:0] IF_ID_IR;
  logic [63:0] IF_ID_PC, IF_ID_PCPlus4;
  if_id_reg ifid (
    .IR(IF_ID_IR), .PC(IF_ID_PC), .PCPlus4(IF_ID_PCPlus4),
    .IR_in(IR_fetched), .PC_in(PC), .PCPlus4_in(PCPlus4_IF),
    .flush(flush_if_id),
    .clk(clk), .reset(reset)
  );

  //======================================================================
  // ID stage
  //======================================================================

  // ---- Decode ----
  logic       Reg2Loc, ALUSrc, MemToReg, RegWrite, MemRead, MemWrite;
  logic       UncondBranch, ZeroBranch, CondBranch, RegBranch, FlagWrite, IsBL;
  logic [2:0] ALUCntrl;
  logic [1:0] ImmSrc;

  control_unit ctrl (
    .instr(IF_ID_IR),
    .Reg2Loc(Reg2Loc), .ALUSrc(ALUSrc), .MemToReg(MemToReg),
    .RegWrite(RegWrite), .MemRead(MemRead), .MemWrite(MemWrite),
    .UncondBranch(UncondBranch), .ZeroBranch(ZeroBranch),
    .CondBranch(CondBranch), .RegBranch(RegBranch),
    .FlagWrite(FlagWrite), .ALUCntrl(ALUCntrl), .ImmSrc(ImmSrc), .IsBL(IsBL)
  );

  logic [63:0] ImmExt;
  imm_extend ext (.instr(IF_ID_IR), .ImmSrc(ImmSrc), .ImmExt(ImmExt));

  logic [4:0]  ReadRegister1, ReadRegister2, WriteRegisterID;
  logic [63:0] ReadData1_raw, ReadData2_raw;

  assign ReadRegister1 = IF_ID_IR[9:5];   // Rn

  mux5_2to1 reg2loc_mux (
    .out(ReadRegister2),
    .i0(IF_ID_IR[20:16]),  // Rm
    .i1(IF_ID_IR[4:0]),    // Rt/Rd
    .sel(Reg2Loc)
  );

  mux5_2to1 writereg_mux (
    .out(WriteRegisterID),
    .i0(IF_ID_IR[4:0]),    // Rd/Rt
    .i1(5'd30),             // X30 = LR
    .sel(IsBL)
  );

  // ---- Register file (read here in ID, written by WB below) ----
  logic [63:0] WriteData;
  logic [4:0]  MEM_WB_WriteRegister;
  logic        MEM_WB_RegWrite;

  regfile rf (
    .ReadData1(ReadData1_raw), .ReadData2(ReadData2_raw),
    .WriteData(WriteData),
    .ReadRegister1(ReadRegister1), .ReadRegister2(ReadRegister2),
    .WriteRegister(MEM_WB_WriteRegister),
    .RegWrite(MEM_WB_RegWrite),
    .clk(clk), .reset(reset)
  );

  // ---- Forwarding (resolved once, here in ID -- see forwarding.sv) ----
  logic        ex_fwd_valid;
  logic [4:0]  ex_fwd_reg;
  logic [63:0] ex_fwd_val;

  logic        mem_fwd_valid;
  logic [4:0]  mem_fwd_reg;
  logic [63:0] mem_fwd_val;

  logic        wb_fwd_valid;
  logic [4:0]  wb_fwd_reg;
  logic [63:0] wb_fwd_val;

  logic [63:0] ForwardedReadData1, ForwardedReadData2;

  forward_select fwd1 (
    .out(ForwardedReadData1),
    .src_reg(ReadRegister1), .raw_val(ReadData1_raw),
    .ex_valid(ex_fwd_valid), .ex_reg(ex_fwd_reg), .ex_val(ex_fwd_val),
    .mem_valid(mem_fwd_valid), .mem_reg(mem_fwd_reg), .mem_val(mem_fwd_val),
    .wb_valid(wb_fwd_valid), .wb_reg(wb_fwd_reg), .wb_val(wb_fwd_val)
  );

  forward_select fwd2 (
    .out(ForwardedReadData2),
    .src_reg(ReadRegister2), .raw_val(ReadData2_raw),
    .ex_valid(ex_fwd_valid), .ex_reg(ex_fwd_reg), .ex_val(ex_fwd_val),
    .mem_valid(mem_fwd_valid), .mem_reg(mem_fwd_reg), .mem_val(mem_fwd_val),
    .wb_valid(wb_fwd_valid), .wb_reg(wb_fwd_reg), .wb_val(wb_fwd_val)
  );

  // ---- Branch/CBZ/BR resolution (ID stage, using forwarded operands) ----
  // NOTE: this ISA's branches are PC-relative to the branch instruction's
  // OWN address (see the encoding comments in the .arm test files: "B: PC =
  // PC + SignExtend(...)"), not to PC+4 as in the generic MIPS-style
  // pipeline diagram -- so the adder below deliberately uses IF_ID_PC, not
  // IF_ID_PCPlus4, to stay correct for this ISA.
  logic [63:0] BranchTarget;
  add64 br_adder (.in1(IF_ID_PC), .in2(ImmExt), .sum(BranchTarget)); // unused overflow/carry

  logic ID_Zero;
  zeroflag id_zero_check (.zero(ID_Zero), .in(ForwardedReadData2));

  // Flags: flagreg is one cycle "stale" relative to an instruction that
  // immediately precedes a B.LT (that instruction is still combinationally
  // computing N/V in EX this very cycle), so forward the live EX flags
  // when the EX-stage instruction writes flags, else use flagreg.
  logic N_flag, V_flag;
  logic EX_ALU_negative, EX_ALU_overflow;
  logic ID_EX_FlagWrite;

  logic EffN, EffV;
  mux2_1 flagN_fwd (.out(EffN), .i0(N_flag), .i1(EX_ALU_negative), .sel(ID_EX_FlagWrite));
  mux2_1 flagV_fwd (.out(EffV), .i0(V_flag), .i1(EX_ALU_overflow), .sel(ID_EX_FlagWrite));

  wire flags_neq, zero_taken, cond_taken, BranchTaken, AnyTaken;
  xor g_flags_neq   (flags_neq, EffN, EffV);
  and g_zero_taken  (zero_taken, ZeroBranch, ID_Zero);
  and g_cond_taken  (cond_taken, CondBranch, flags_neq);
  or  g_branch_taken(BranchTaken, UncondBranch, zero_taken, cond_taken);
  or  g_any_taken   (AnyTaken, BranchTaken, RegBranch);

`ifdef FLUSH_ON_BRANCH
  assign flush_if_id = AnyTaken;
`else
  assign flush_if_id = 1'b0;
`endif

  logic [63:0] PCBranchStage;
  mux64_2to1 pcsrc_mux (.out(PCBranchStage), .i0(PCPlus4_IF), .i1(BranchTarget), .sel(BranchTaken));
  mux64_2to1 pcbr_mux  (.out(PCNext), .i0(PCBranchStage), .i1(ForwardedReadData2), .sel(RegBranch));

  // ---- ID/EX pipeline register ----
  logic        ID_EX_ALUSrc, ID_EX_MemRead, ID_EX_MemWrite, ID_EX_MemToReg, ID_EX_RegWrite, ID_EX_IsBL;
  logic [2:0]  ID_EX_ALUCntrl;
  logic [63:0] ID_EX_ReadData1, ID_EX_ReadData2, ID_EX_ImmExt, ID_EX_PCPlus4;
  logic [4:0]  ID_EX_WriteRegister;

  id_ex_reg idex (
    .ALUSrc(ID_EX_ALUSrc), .ALUCntrl(ID_EX_ALUCntrl),
    .MemRead(ID_EX_MemRead), .MemWrite(ID_EX_MemWrite), .MemToReg(ID_EX_MemToReg),
    .RegWrite(ID_EX_RegWrite), .IsBL(ID_EX_IsBL), .FlagWrite(ID_EX_FlagWrite),
    .ReadData1(ID_EX_ReadData1), .ReadData2(ID_EX_ReadData2),
    .ImmExt(ID_EX_ImmExt), .WriteRegister(ID_EX_WriteRegister), .PCPlus4(ID_EX_PCPlus4),

    .ALUSrc_in(ALUSrc), .ALUCntrl_in(ALUCntrl),
    .MemRead_in(MemRead), .MemWrite_in(MemWrite), .MemToReg_in(MemToReg),
    .RegWrite_in(RegWrite), .IsBL_in(IsBL), .FlagWrite_in(FlagWrite),
    .ReadData1_in(ForwardedReadData1), .ReadData2_in(ForwardedReadData2),
    .ImmExt_in(ImmExt), .WriteRegister_in(WriteRegisterID), .PCPlus4_in(IF_ID_PCPlus4),

    .clk(clk), .reset(reset)
  );

  //======================================================================
  // EX stage
  //======================================================================
  logic [63:0] EX_ALUBIn, EX_ALUResult;
  logic        EX_ALU_zero, EX_ALU_carry; // unused downstream

  mux64_2to1 alusrc_mux (
    .out(EX_ALUBIn), .i0(ID_EX_ReadData2), .i1(ID_EX_ImmExt), .sel(ID_EX_ALUSrc)
  );

  alu main_alu (
    .A(ID_EX_ReadData1), .B(EX_ALUBIn), .cntrl(ID_EX_ALUCntrl),
    .result(EX_ALUResult),
    .negative(EX_ALU_negative), .zero(EX_ALU_zero),
    .overflow(EX_ALU_overflow), .carry_out(EX_ALU_carry)
  );

  // Distance-1 forwarding source: the instruction currently in EX.
  assign ex_fwd_valid = ID_EX_RegWrite && !ID_EX_MemRead && (ID_EX_WriteRegister != 5'd31);
  assign ex_fwd_reg   = ID_EX_WriteRegister;
  assign ex_fwd_val   = EX_ALUResult;

  flagreg flags (
    .N_out(N_flag), .V_out(V_flag),
    .N_in(EX_ALU_negative), .V_in(EX_ALU_overflow),
    .FlagWrite(ID_EX_FlagWrite),
    .clk(clk), .reset(reset)
  );

  assign n_flag_out = N_flag;
  assign v_flag_out = V_flag;

  // ---- EX/MEM pipeline register ----
  logic        EX_MEM_MemRead, EX_MEM_MemWrite, EX_MEM_MemToReg, EX_MEM_RegWrite, EX_MEM_IsBL;
  logic [63:0] EX_MEM_ALUout, EX_MEM_StoreData, EX_MEM_PCPlus4;
  logic [4:0]  EX_MEM_WriteRegister;

  ex_mem_reg exmem (
    .MemRead(EX_MEM_MemRead), .MemWrite(EX_MEM_MemWrite), .MemToReg(EX_MEM_MemToReg),
    .RegWrite(EX_MEM_RegWrite), .IsBL(EX_MEM_IsBL),
    .ALUout(EX_MEM_ALUout), .StoreData(EX_MEM_StoreData),
    .WriteRegister(EX_MEM_WriteRegister), .PCPlus4(EX_MEM_PCPlus4),

    .MemRead_in(ID_EX_MemRead), .MemWrite_in(ID_EX_MemWrite), .MemToReg_in(ID_EX_MemToReg),
    .RegWrite_in(ID_EX_RegWrite), .IsBL_in(ID_EX_IsBL),
    .ALUout_in(EX_ALUResult), .StoreData_in(ID_EX_ReadData2),
    .WriteRegister_in(ID_EX_WriteRegister), .PCPlus4_in(ID_EX_PCPlus4),

    .clk(clk), .reset(reset)
  );

  //======================================================================
  // MEM stage
  //======================================================================
  logic [63:0] MemReadData;
  datamem dmem (
    .address(EX_MEM_ALUout),
    .write_enable(EX_MEM_MemWrite),
    .read_enable(EX_MEM_MemRead),
    .write_data(EX_MEM_StoreData),
    .clk(clk),
    .xfer_size(4'd8),          // every LDUR/STUR is a double-word
    .read_data(MemReadData)
  );

  // Distance-2 forwarding tap: the instruction currently in MEM.  This has
  // to be computed live, here, rather than waiting for MEM/WB to be
  // written next cycle -- it's what correctly covers a load, whose data
  // isn't ready until now.  (The *official* ALUout/MemToReg-vs-ReadData
  // merge for the actual register-file write happens down in WB, off the
  // latched MEM/WB fields -- this is only an early copy for forwarding.)
  logic [63:0] MemFwdStage, MemFwdValue;
  mux64_2to1 fwd_memtoreg_mux (
    .out(MemFwdStage), .i0(EX_MEM_ALUout), .i1(MemReadData), .sel(EX_MEM_MemToReg)
  );
  mux64_2to1 fwd_bl_mux (
    .out(MemFwdValue), .i0(MemFwdStage), .i1(EX_MEM_PCPlus4), .sel(EX_MEM_IsBL)
  );

  assign mem_fwd_valid = EX_MEM_RegWrite && (EX_MEM_WriteRegister != 5'd31);
  assign mem_fwd_reg   = EX_MEM_WriteRegister;
  assign mem_fwd_val   = MemFwdValue;

  // ---- MEM/WB pipeline register ----
  // Holds "data read from memory" (ReadData) and "the ALU output" (ALUout)
  // as two separate fields, per the diagram -- MemToReg/IsBL ride along so
  // WB can pick between (and, for BL, override) them once it actually runs.
  logic        MEM_WB_MemToReg, MEM_WB_IsBL;
  logic [63:0] MEM_WB_ALUout, MEM_WB_ReadData, MEM_WB_PCPlus4;

  mem_wb_reg memwb (
    .RegWrite(MEM_WB_RegWrite), .MemToReg(MEM_WB_MemToReg), .IsBL(MEM_WB_IsBL),
    .ALUout(MEM_WB_ALUout), .ReadData(MEM_WB_ReadData), .PCPlus4(MEM_WB_PCPlus4),
    .WriteRegister(MEM_WB_WriteRegister),

    .RegWrite_in(EX_MEM_RegWrite), .MemToReg_in(EX_MEM_MemToReg), .IsBL_in(EX_MEM_IsBL),
    .ALUout_in(EX_MEM_ALUout), .ReadData_in(MemReadData), .PCPlus4_in(EX_MEM_PCPlus4),
    .WriteRegister_in(EX_MEM_WriteRegister),

    .clk(clk), .reset(reset)
  );

  //======================================================================
  // WB stage: pick between the latched ALUout and ReadData (and, for BL,
  // override both with PCPlus4), then write the result into the register
  // file (write port wired into rf up in the ID section).
  //======================================================================
  logic [63:0] WriteDataStage;
  mux64_2to1 memtoreg_mux (
    .out(WriteDataStage), .i0(MEM_WB_ALUout), .i1(MEM_WB_ReadData), .sel(MEM_WB_MemToReg)
  );
  mux64_2to1 bl_mux (
    .out(WriteData), .i0(WriteDataStage), .i1(MEM_WB_PCPlus4), .sel(MEM_WB_IsBL)
  );

  // Distance-3 forwarding source: the instruction currently in WB.
  assign wb_fwd_valid = MEM_WB_RegWrite && (MEM_WB_WriteRegister != 5'd31);
  assign wb_fwd_reg   = MEM_WB_WriteRegister;
  assign wb_fwd_val   = WriteData;

endmodule
