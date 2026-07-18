`timescale 1ns/10ps

// Pulls the immediate field out of the instruction and extends it to
// 64 bits, per LEGv8 encoding:
//   ImmSrc = 00 : I-format  ADDI   -> imm12 = instr[21:10], ZERO-extend
//   ImmSrc = 01 : D-format  LDUR/STUR -> imm9 = instr[20:12], SIGN-extend
//   ImmSrc = 10 : CB-format CBZ/B.LT  -> imm19 = instr[23:5], SIGN-extend, <<2
//   ImmSrc = 11 : B-format  B/BL      -> imm26 = instr[25:0], SIGN-extend, <<2
//
// The <<2 for branch-type immediates is just rewiring (concatenating
// two zero bits on the bottom and dropping the top two bits), not an
// arithmetic operation, so it's done here rather than with a separate
// shifter/adder.
module imm_extend (
  input  logic [31:0] instr,
  input  logic [1:0]  ImmSrc,
  output logic [63:0] ImmExt
);

  logic [11:0] imm12;
  logic [8:0]  imm9;
  logic [18:0] imm19;
  logic [25:0] imm26;

  assign imm12 = instr[21:10];
  assign imm9  = instr[20:12];
  assign imm19 = instr[23:5];
  assign imm26 = instr[25:0];

  always_comb begin
    case (ImmSrc)
      2'b00: ImmExt = {52'b0, imm12};                                  // ADDI: zero-extend, no shift
      2'b01: ImmExt = {{55{imm9[8]}}, imm9};                            // LDUR/STUR: sign-extend, no shift
      2'b10: ImmExt = {{43{imm19[18]}}, imm19, 2'b00};                  // CBZ/B.LT: sign-extend, <<2
      2'b11: ImmExt = {{36{imm26[25]}}, imm26, 2'b00};                  // B/BL: sign-extend, <<2
      default: ImmExt = 64'bx;
    endcase
  end
endmodule
