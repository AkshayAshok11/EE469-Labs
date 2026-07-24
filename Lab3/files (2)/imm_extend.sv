`timescale 1ns/10ps

// =====================================================================
// imm_extend.sv -- PURE GATE-LEVEL VERSION
//
// Sign/zero-extension itself is pure wire replication (copying a bit to
// several destinations needs no gates -- it's routing, not logic), so
// that part is still plain concatenation. What used to be a `case`
// choosing among the four candidate values is now a 3-mux binary tree
// built from your gate-level mux64_2to1 (same primitive already used
// for ALUSrc/MemToReg/PCSrc in cpu.sv).
//
//   ImmSrc = 00 : I-format  ADDI       -> imm12 = instr[21:10], ZERO-extend
//   ImmSrc = 01 : D-format  LDUR/STUR  -> imm9  = instr[20:12], SIGN-extend
//   ImmSrc = 10 : CB-format CBZ/B.cond -> imm19 = instr[23:5],  SIGN-extend, <<2
//   ImmSrc = 11 : B-format  B/BL       -> imm26 = instr[25:0],  SIGN-extend, <<2
// =====================================================================

module imm_extend (
  input  logic [31:0] instr,
  input  logic [1:0]  ImmSrc,
  output logic [63:0] ImmExt
);

  wire [11:0] imm12;
  wire [8:0]  imm9;
  wire [18:0] imm19;
  wire [25:0] imm26;

  assign imm12 = instr[21:10];
  assign imm9  = instr[20:12];
  assign imm19 = instr[23:5];
  assign imm26 = instr[25:0];

  // Four candidate extended values -- pure wiring (replication), no gates needed.
  wire [63:0] addi_ext, ldst_ext, cb_ext, b_ext;
  assign addi_ext = {52'b0, imm12};                     // ADDI: zero-extend, no shift
  assign ldst_ext = {{55{imm9[8]}}, imm9};               // LDUR/STUR: sign-extend, no shift
  assign cb_ext   = {{43{imm19[18]}}, imm19, 2'b00};     // CBZ/B.cond: sign-extend, <<2
  assign b_ext    = {{36{imm26[25]}}, imm26, 2'b00};     // B/BL: sign-extend, <<2

  // Select among the four with a 2-level gate-built mux tree.
  wire [63:0] stage0, stage1;
  mux64_2to1 sel0 (.out(stage0), .i0(addi_ext), .i1(ldst_ext), .sel(ImmSrc[0]));
  mux64_2to1 sel1 (.out(stage1), .i0(cb_ext),   .i1(b_ext),    .sel(ImmSrc[0]));
  mux64_2to1 selF (.out(ImmExt), .i0(stage0),   .i1(stage1),   .sel(ImmSrc[1]));

endmodule
