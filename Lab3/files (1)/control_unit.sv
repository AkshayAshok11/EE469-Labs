`timescale 1ns/10ps

// =====================================================================
// control_unit.sv
//
// Decodes Instruction[31:21] (11 bits) to identify the instruction and
// drive every control signal in the datapath. This uses the standard
// LEGv8/ARMv8 "teaching ISA" opcode encoding (Patterson & Hennessy,
// Computer Organization and Design, ARM Edition -- the same ISA your
// lab handout's instruction list is drawn from). Narrower opcodes
// (I/B/CB-format) are padded with '?' don't-cares out to 11 bits,
// since the remaining bits at that position are immediate data, not
// opcode, for those formats.
//
// *** IMPORTANT ***
// If your course handed out a reference/green card with different
// opcode bit patterns than the standard textbook ones, update the
// literals in the casez below to match -- everything downstream
// (datapath, testbench) is unaffected by this choice.
//
// ALU control codes match your alu.sv/alustim.sv exactly:
//   000 = pass B   010 = A+B   011 = A-B   100 = A&B   101 = A|B   110 = A^B
// =====================================================================

module control_unit (
  input  logic [31:0] instr,

  output logic       Reg2Loc,     // 0: ReadReg2 = Rm(20:16)   1: ReadReg2 = Rt/Rd(4:0)
  output logic       ALUSrc,      // 0: ALU B = ReadData2      1: ALU B = ImmExt
  output logic       MemToReg,    // 0: WriteData = ALUResult  1: WriteData = MemReadData
  output logic       RegWrite,
  output logic       MemRead,
  output logic       MemWrite,
  output logic       UncondBranch,// B, BL           -- always taken
  output logic       ZeroBranch,  // CBZ             -- taken if ALU zero flag
  output logic       CondBranch,  // B.LT            -- taken if N != V (stored flags)
  output logic       RegBranch,   // BR              -- PC <= ReadData1
  output logic       FlagWrite,   // ADDS, SUBS      -- latch N,V
  output logic [2:0]  ALUCntrl,
  output logic [1:0]  ImmSrc,
  output logic       IsBL         // BL: WriteReg=X30, WriteData=PC+4
);

  // ALU control codes (must match alu.sv)
  localparam [2:0] ALU_PASSB = 3'b000;
  localparam [2:0] ALU_ADD   = 3'b010;
  localparam [2:0] ALU_SUB   = 3'b011;

  // Standard LEGv8 opcodes, 11-bit view (instr[31:21])
  localparam [10:0] OP_ADDS = 11'b10101011000;
  localparam [10:0] OP_SUBS = 11'b11101011000;
  localparam [10:0] OP_LDUR = 11'b11111000010;
  localparam [10:0] OP_STUR = 11'b11111000000;
  localparam [10:0] OP_BR   = 11'b11010110000;

  logic [4:0] cond;
  assign cond = instr[4:0];
  localparam [4:0] COND_LT = 5'b01011;

  always_comb begin
    // Safe defaults: no register/memory side effects, no branch.
    Reg2Loc      = 1'b0;
    ALUSrc       = 1'b0;
    MemToReg     = 1'b0;
    RegWrite     = 1'b0;
    MemRead      = 1'b0;
    MemWrite     = 1'b0;
    UncondBranch = 1'b0;
    ZeroBranch   = 1'b0;
    CondBranch   = 1'b0;
    RegBranch    = 1'b0;
    FlagWrite    = 1'b0;
    ALUCntrl     = ALU_ADD;
    ImmSrc       = 2'b00;
    IsBL         = 1'b0;

    casez (instr[31:21])
      OP_ADDS: begin
        RegWrite  = 1'b1;
        FlagWrite = 1'b1;
        ALUCntrl  = ALU_ADD;
      end

      OP_SUBS: begin
        RegWrite  = 1'b1;
        FlagWrite = 1'b1;
        ALUCntrl  = ALU_SUB;
      end

      11'b1001000100?: begin // ADDI
        ALUSrc   = 1'b1;
        RegWrite = 1'b1;
        ALUCntrl = ALU_ADD;
        ImmSrc   = 2'b00;
      end

      OP_LDUR: begin
        ALUSrc   = 1'b1;
        RegWrite = 1'b1;
        MemRead  = 1'b1;
        MemToReg = 1'b1;
        ALUCntrl = ALU_ADD;
        ImmSrc   = 2'b01;
      end

      OP_STUR: begin
        Reg2Loc   = 1'b1;
        ALUSrc    = 1'b1;
        MemWrite  = 1'b1;
        ALUCntrl  = ALU_ADD;
        ImmSrc    = 2'b01;
      end

      11'b10110100???: begin // CBZ
        Reg2Loc    = 1'b1;
        ALUCntrl   = ALU_PASSB;
        ImmSrc     = 2'b10;
        ZeroBranch = 1'b1;
      end

      11'b01010100???: begin // B.cond -- only LT is defined by the spec
        ImmSrc    = 2'b10;
        if (cond == COND_LT)
          CondBranch = 1'b1;
      end

      11'b000101?????: begin // B
        UncondBranch = 1'b1;
        ImmSrc       = 2'b11;
      end

      11'b100101?????: begin // BL
        UncondBranch = 1'b1;
        RegWrite     = 1'b1;
        ImmSrc       = 2'b11;
        IsBL         = 1'b1;
      end

      OP_BR: begin
        RegBranch = 1'b1;
      end

      default: begin
        // Unrecognized opcode -- leave everything at safe defaults.
      end
    endcase
  end
endmodule
