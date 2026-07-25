`timescale 1ns/10ps

module control_unit (
  input  logic [31:0] instr,

  output logic       Reg2Loc,     // 0: ReadReg2 = Rm(20:16)   1: ReadReg2 = Rt/Rd(4:0)
  output logic       ALUSrc,      // 0: ALU B = ReadData2      1: ALU B = ImmExt
  output logic       MemToReg,    // 0: WriteData = ALUResult  1: WriteData = MemReadData
  output logic       RegWrite,
  output logic       MemRead,
  output logic       MemWrite,
  output logic       UncondBranch,// B, BL: always taken
  output logic       ZeroBranch,  // CBZ: taken if ALU zero flag
  output logic       CondBranch,  // B.LT: taken if N != V
  output logic       RegBranch,   // BR: PC <= ReadData2 (Reg2Loc routes Rd here)
  output logic       FlagWrite,   // ADDS, SUBS: latch N,V
  output logic [2:0]  ALUCntrl,
  output logic [1:0]  ImmSrc,
  output logic       IsBL         // BL: WriteReg=X30, WriteData=PC+4
);

  // Every opcode/cond bit we needed
  logic n21, n22, n23, n24, n25, n26, n27, n28, n29, n30, n31;
  not g_n21 (n21, instr[21]);
  not g_n22 (n22, instr[22]);
  not g_n23 (n23, instr[23]);
  not g_n24 (n24, instr[24]);
  not g_n25 (n25, instr[25]);
  not g_n26 (n26, instr[26]);
  not g_n27 (n27, instr[27]);
  not g_n28 (n28, instr[28]);
  not g_n29 (n29, instr[29]);
  not g_n30 (n30, instr[30]);
  not g_n31 (n31, instr[31]);

  logic n2, n4;
  not g_n2 (n2, instr[2]);
  not g_n4 (n4, instr[4]);



  // Instruction decode (one AND gate each)
  logic isADDI, isADDS, isSUBS, isLDUR, isSTUR, isCBZ, isBCOND, isLTcond, isBLT, isB, isBL, isBR;

  // ADDI  1001000100  (instr[31:22])
  and g_addi (isADDI, instr[31], n30, n29, instr[28], n27, n26, n25, instr[24], n23, n22);

  // ADDS  10101011000  (instr[31:21])
  and g_adds (isADDS, instr[31], n30, instr[29], n28, instr[27], n26, instr[25], instr[24], n23, n22, n21);

  // SUBS  11101011000  (instr[31:21])
  and g_subs (isSUBS, instr[31], instr[30], instr[29], n28, instr[27], n26, instr[25], instr[24], n23, n22, n21);

  // LDUR  11111000010  (instr[31:21])
  and g_ldur (isLDUR, instr[31], instr[30], instr[29], instr[28], instr[27], n26, n25, n24, n23, instr[22], n21);

  // STUR  11111000000  (instr[31:21])
  and g_stur (isSTUR, instr[31], instr[30], instr[29], instr[28], instr[27], n26, n25, n24, n23, n22, n21);

  // BR    11010110000  (instr[31:21])
  and g_br   (isBR, instr[31], instr[30], n29, instr[28], n27, instr[26], instr[25], n24, n23, n22, n21);

  // CBZ   10110100  (instr[31:24])
  and g_cbz  (isCBZ, instr[31], n30, instr[29], instr[28], n27, instr[26], n25, n24);

  // B.cond 01010100  (instr[31:24])
  and g_bcond (isBCOND, n31, instr[30], n29, instr[28], n27, instr[26], n25, n24);

  // cond field == LT (01011), instr[4:0]
  and g_lt   (isLTcond, n4, instr[3], n2, instr[1], instr[0]);

  // B.LT = B.cond opcode AND cond==LT
  and g_blt  (isBLT, isBCOND, isLTcond);

  // B     000101  (instr[31:26])
  and g_b    (isB, n31, n30, n29, instr[28], n27, instr[26]);

  // BL    100101  (instr[31:26])
  and g_bl   (isBL, instr[31], n30, n29, instr[28], n27, instr[26]);



  // Combine decoded instructions into control signals

  // Reg2Loc: STUR/CBZ/BR all read their second register field from instr[4:0]
  or  g_reg2loc (Reg2Loc, isSTUR, isCBZ, isBR);

  // ALUSrc: ADDI/LDUR/STUR use the immediate as the ALU's B input
  or  g_alusrc (ALUSrc, isADDI, isLDUR, isSTUR);

  // MemToReg: only LDUR writes back memory data
  assign MemToReg = isLDUR;

  // RegWrite: ADDI, ADDS, SUBS, LDUR, BL all write a register
  or  g_regwrite (RegWrite, isADDI, isADDS, isSUBS, isLDUR, isBL);

  assign MemRead = isLDUR;
  assign MemWrite = isSTUR;

  or  g_uncond (UncondBranch, isB, isBL);
  assign ZeroBranch = isCBZ;
  assign CondBranch = isBLT;
  assign RegBranch = isBR;

  or  g_flagwrite (FlagWrite, isADDS, isSUBS);

  assign IsBL = isBL;

  // ALUCntrl: bit2 is always 0 for this instruction set (000=passB, 010=add, 011=sub)
  assign ALUCntrl[2] = 1'b0;
  or  g_alu1 (ALUCntrl[1], isADDI, isADDS, isSUBS, isLDUR, isSTUR);
  assign ALUCntrl[0] = isSUBS;

  // ImmSrc: 00=I-type(ADDI) 01=D-type(LDUR/STUR) 10=CB-type(CBZ/B.cond) 11=B-type(B/BL)
  or  g_immsrc1 (ImmSrc[1], isCBZ, isBCOND, isB, isBL);
  or  g_immsrc0 (ImmSrc[0], isLDUR, isSTUR, isB, isBL);
endmodule



module flagreg (
  output logic N_out, O_out,
  input  logic N_in, O_in,
  input  logic FlagWrite,
  input  logic clk, reset
);
  logic N_next, O_next;

  mux2_1 mN (.out(N_next), .i0(N_out), .i1(N_in), .sel(FlagWrite));
  mux2_1 mO (.out(O_next), .i0(O_out), .i1(O_in), .sel(FlagWrite));

  D_FF dffN (.q(N_out), .d(N_next), .reset(reset), .clk(clk));
  D_FF dffO (.q(O_out), .d(O_next), .reset(reset), .clk(clk));
endmodule