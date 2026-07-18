# Single-Cycle ARM (LEGv8) CPU — Design Notes

I built and **simulated this end-to-end in Icarus Verilog** before handing it
over (ADDI, ADDS, SUBS, LDUR/STUR round-trip, CBZ, B.LT, B, BL/BR all verified
correct against hand-computed expected values — see "Self-test" below). Real
ModelSim/`vsim` behavior can differ in edge cases, so still run your own
benchmarks, but the datapath logic itself is confirmed sound.

## ⚠️ Read this first: instruction encoding assumption

Your lab handout lists the instructions and their semantics, but **not the
actual bit-level encoding** (which fields live at which bit positions, what
the opcode values are). That has to come from somewhere — normally a
reference/green card your course hands out. Since I don't have that, I used
the **standard LEGv8 encoding** from Patterson & Hennessy's *Computer
Organization and Design, ARM Edition* (the same textbook your handout's
"Chapter 4" reference points to), which is the conventional teaching ISA this
exact instruction subset is drawn from:

| Format | Layout | Used by |
|---|---|---|
| R | `opcode[31:21]` `Rm[20:16]` `shamt[15:10]` `Rn[9:5]` `Rd[4:0]` | ADDS, SUBS, BR |
| I | `opcode[31:22]` `imm12[21:10]` `Rn[9:5]` `Rd[4:0]` | ADDI |
| D | `opcode[31:21]` `imm9[20:12]` `op2[11:10]` `Rn[9:5]` `Rt[4:0]` | LDUR, STUR |
| B | `opcode[31:26]` `imm26[25:0]` | B, BL |
| CB | `opcode[31:24]` `imm19[23:5]` `Rt/cond[4:0]` | CBZ, B.LT |

Opcodes used (see `localparam`s at the top of `control_unit.sv`):
`ADDS=10101011000`, `SUBS=11101011000`, `ADDI=1001000100`, `LDUR=11111000010`,
`STUR=11111000000`, `CBZ=10110100`, `B.cond=01010100` (LT condition
`=01011`), `B=000101`, `BL=100101`, `BR=11010110000`.

**If your course's reference card uses different opcode values, everything
you need to change is contained in `control_unit.sv`** — the datapath,
register file, ALU, and testbench are all opcode-agnostic.

One spot worth double-checking: `BR Rd` in your handout's notation — I
decoded its target register from the **Rn field** (`instr[9:5]`), since that's
the field the register file's (unmuxed) ReadRegister1 port always reads,
matching the standard datapath. If your reference card puts BR's target
register somewhere else, update `ReadRegister1`'s assignment in `cpu.sv`.

## What I fixed in your existing files

**Duplicate `mux2_1`.** Your lab-1 mux file (regfile's `mux2_1`/`mux32_1`/
`mux64x32to1`) and your lab-2 mux file (ALU's `mux2_1`/`mux8_1`) both define
`module mux2_1` identically. Compiling both into one project throws a
duplicate-module error. I merged them into one **`mux_lib.sv`** containing
`mux2_1` once, plus `mux8_1`, `mux32_1`, `mux64x32to1`, and two new ones the
CPU needs (`mux64_2to1`, `mux5_2to1`, both built the same gate-level way —
one `mux2_1` per bit). **Use `mux_lib.sv` in place of both of your old mux
files.**

## New files for lab 3

- **`control_unit.sv`** — decodes the opcode and drives every control
  signal. This is the one place the PDF explicitly says can be plain RTL
  (`always_comb`/`casez`), so that's what it is.
- **`imm_extend.sv`** — pulls out and sign/zero-extends whichever immediate
  field the current instruction uses (imm12 zero-extended for ADDI; imm9
  sign-extended for LDUR/STUR; imm19/imm26 sign-extended **and pre-shifted
  left by 2** for CBZ/B.LT/B/BL, since branch immediates count instructions,
  not bytes). The shift is pure rewiring (concatenating two zero bits), not
  arithmetic, so it's done as a `case`, not with a shifter.
- **`flagreg.sv`** — stores the N (negative) and V (overflow) flags, built
  from the exact same `D_FF` + `mux2_1` pattern your `reg64bit` uses, just
  narrower (2 bits instead of 64), so it reuses your verified primitives
  instead of a plain behavioral register. Only latches on `FlagWrite`
  (asserted for ADDS/SUBS).
- **`cpu.sv`** — the top-level datapath. Instantiates `instructmem`,
  `datamem`, your `regfile`, your `alu`, plus the new pieces above, and
  wires them together with the `add64` adder (reused for PC+4 and the
  branch-target add — no `+` operator) and `mux64_2to1`/`mux5_2to1` for
  every actual datapath mux (ALU-B select, write-data select, PC-next
  select, register-address select). The PC register is just your
  `reg64bit` with `en` tied high.
- **`cpu_testbench.sv`** / **`cpu_wave.do`** / **`runlab.do`** — testbench
  and ModelSim scripts, described below.

### Where I drew the "structural gates vs. plain RTL" line

Your labs 1–2 built the register file and ALU entirely from primitive gates
(`and`/`or`/`not` with delays) rather than behavioral operators — presumably
per "lab #1 rules." The PDF for this lab explicitly carves out an exception:
*"The control logic for your CPU can be done in RTL (`always_comb` and
`always_ff` blocks)."* I took that to mean: the **opcode-decode logic**
(`control_unit.sv`) and **immediate extraction** (`imm_extend.sv`, pure
rewiring, no gates needed) can be plain SystemVerilog, but **actual
datapath computation and multiplexing** should keep reusing your existing
structural primitives — so PC+4 and branch-target math go through `add64`
(never `+`), and every real data mux (ALUSrc, MemToReg, PCSrc, Reg2Loc,
WriteRegister) is built from `mux2_1` arrays (`mux64_2to1`, `mux5_2to1`), not
ternary operators. If your "lab #1 rules" document says something different
about where that line falls, this is the one place you might want to adjust.

## Control signals (per instruction)

| Instr | Reg2Loc | ALUSrc | MemToReg | RegWrite | MemRead | MemWrite | FlagWrite | ALUCntrl | Branch type |
|---|---|---|---|---|---|---|---|---|---|
| ADDI | – | 1 | ALU | 1 | 0 | 0 | 0 | ADD | – |
| ADDS | 0 (Rm) | 0 | ALU | 1 | 0 | 0 | 1 | ADD | – |
| SUBS | 0 (Rm) | 0 | ALU | 1 | 0 | 0 | 1 | SUB | – |
| LDUR | – | 1 | Mem | 1 | 1 | 0 | 0 | ADD | – |
| STUR | 1 (Rt) | 1 | – | 0 | 0 | 1 | 0 | ADD | – |
| CBZ | 1 (Rt) | 0 | – | 0 | 0 | 0 | 0 | PASS_B | taken if ALU `zero` |
| B.LT | – | – | – | 0 | 0 | 0 | 0 | – | taken if `N != V` (stored flags) |
| B | – | – | – | 0 | 0 | 0 | 0 | – | always taken |
| BL | – | – | PC+4 | 1 (→X30) | 0 | 0 | 0 | – | always taken |
| BR | – | – | – | 0 | 0 | 0 | 0 | – | PC ← ReadData1 |

CBZ is the fun one: `Reg2Loc` routes `Rt` into the register file's second
read port, the ALU is told to `PASS_B` (opcode `000`, already in your
`alu.sv`), and the ALU's own `zero` output — computed for free as part of
that pass-through — tells you whether `Rt == 0`. No separate comparator
needed.

## Running it

```
vsim -c -do runlab.do
```

To switch benchmarks, edit the `` `define BENCHMARK `` line in
`instructmem.sv` exactly as it already tells you to. The clock period
(`ClockDelay` in `cpu_testbench.sv`) is set very long (10,000 ns) because
your register file's `mux2_1`/decoder gates use `#50` delays several levels
deep — the handout's "a VERY long clock is fine" warning is not a joke here.
If you add more logic and start seeing `X`s in your registers, lengthen it
further before assuming there's a bug.

`NumCycles` defaults to 40. Bump it up for longer benchmark programs. If a
program doesn't end in a self-loop (`label: B label`), keep `NumCycles`
close to the program's actual length — running the PC past the end of
instruction memory is harmless but will make `instructmem.sv`'s own
bounds-check assertion complain loudly and repeatedly.

`cpu_wave.do` sets up a wave window with clock, reset, PC, instruction,
every control signal, both flags, and all 31 general registers (X0–X30;
X31/XZR is a hardwired constant, not a real register) — satisfying the
"illustrate all register contents, PC, flags, clock and reset" submission
requirement. Data memory is a 1024-byte array, not a bus, so it's shown via
ModelSim's **Memory List** view instead (the script opens it automatically
and loads `dmem.mem`).

## Self-test (bonus, not required for submission)

`asm.py` is a ~100-line hand-rolled LEGv8 assembler I wrote purely to
generate a test program and confirm the whole datapath end-to-end before
giving this to you — not a deliverable, just useful if you want to
hand-assemble a quick test of your own beyond the provided benchmarks.
`selftest.arm` is its output: a short program exercising all ten
instructions (values chosen so every result is easy to hand-check), ending
in a self-loop. Point `instructmem.sv`'s `` `define BENCHMARK `` at it to
try it yourself; expected final state is documented in the `$display`
statements at the end of `cpu_testbench.sv`.
