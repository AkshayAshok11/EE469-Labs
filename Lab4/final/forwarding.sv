`timescale 1ns/10ps

// Unified forwarding mux, used for both of the ID-stage register reads
// (ReadData1/ReadData2).  Because branches (CBZ's zero-test, BR's target,
// B.LT's flag check) resolve in ID -- one stage earlier than the shared
// ALU -- forwarding has to happen once, in ID, from three priority-ordered
// sources instead of the usual EX-only forwarding unit:
//
//   1. "ex"  : the instruction currently in EX (live, still-combinational
//              ALU output this same cycle) -- the immediately preceding
//              instruction.
//   2. "mem" : the instruction currently in MEM (live write-back value:
//              ALUResult/MemReadData/PC+4 already resolved) -- two
//              instructions back.  This is what covers a load whose data
//              isn't ready until MEM.
//   3. "wb"  : the instruction currently in WB (MEM/WB.WriteData) -- three
//              instructions back, which is also the "write and read the
//              register file the same cycle" case.
//
// Once resolved here, the forwarded value is latched into ID/EX and used
// as-is in EX -- no separate EX-stage forwarding unit is needed.
//
// Each *_valid input must already exclude non-register-writing instructions
// and X31 (X31 is architecturally hardwired to 0, so a forward of a write
// targeting it must never win a match).
module forward_select (
  output logic [63:0] out,

  input  logic [4:0]  src_reg,
  input  logic [63:0] raw_val,

  input  logic         ex_valid,
  input  logic [4:0]   ex_reg,
  input  logic [63:0]  ex_val,

  input  logic         mem_valid,
  input  logic [4:0]   mem_reg,
  input  logic [63:0]  mem_val,

  input  logic         wb_valid,
  input  logic [4:0]   wb_reg,
  input  logic [63:0]  wb_val
);
  always_comb begin
    if (ex_valid && (ex_reg == src_reg))
      out = ex_val;
    else if (mem_valid && (mem_reg == src_reg))
      out = mem_val;
    else if (wb_valid && (wb_reg == src_reg))
      out = wb_val;
    else
      out = raw_val;
  end
endmodule
