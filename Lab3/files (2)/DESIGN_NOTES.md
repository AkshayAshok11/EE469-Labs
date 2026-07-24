# Single-Cycle ARM (LEGv8) CPU — Design Notes

**Verified against all 9 of your actual benchmark files** (test01–test06,
test10–test12) in Icarus Verilog — every register, flag, and memory value
matches each file's own "Expected results" comment exactly. Not a
self-written test program guessing at correctness: your real benchmarks,
run end to end.

## Pure gate-level, no RTL

Every module in the datapath — including the two new control pieces this
lab needed — is built entirely from primitive gates (`and`, `or`, `not`,
`xor`, `buf`) and structural instantiation, per your constraint. No
`always_comb`/`always_ff` with logic in them, no `case`/`if`, no `+ - * ==
!=`. The only `always`-adjacent thing anywhere is plain wiring (e.g.
`assign pc_out = PC;`), which the tutorial itself treats as a distinct,
non-logic construct from Boolean equations.

- **`control_unit.sv`** is a decoder-plus-OR-plane, the same structure as
  your own `dec5_32`: a bank of `not` gates produces the complement of
  every opcode/condition bit needed, then one multi-input `and` gate per
  instruction produces a one-hot `isADDI`/`isADDS`/.../`isBR` signal
  (multi-input gates are directly supported — the tutorial shows a
  5-input `and` explicitly). Every control output is then just an `or` of
  whichever `isXXX` signals need it asserted. There's no case statement
  anywhere; an opcode that matches nothing simply leaves every `isXXX` at
  0, which naturally leaves every control output at 0 too — the "default"
  case a `case` statement would otherwise need falls out for free.
- **`imm_extend.sv`**: sign/zero-extension itself is pure wire replication
  (copying a bit to multiple destinations needs no gates — it's routing,
  not logic, and the tutorial teaches concatenation/replication as its own
  feature separate from "Boolean Equations and Assign"). What used to be a
  `case` picking among the four possible extended values is now a 3-mux
  binary tree built from `mux64_2to1` (gate-built, one `mux2_1` per bit —
  same primitive `cpu.sv` already uses for ALUSrc/MemToReg/PCSrc).
- **`cpu.sv`**'s branch-taken logic (`UncondBranch OR (CBZ AND zero) OR
  (B.LT AND N≠V)`) is now explicit gate instances: an `xor` computes N≠V,
  two `and`s gate the zero/flag conditions, one `or` combines everything.
- **`flagreg.sv`** was already pure gates (your own `D_FF` + `mux2_1`
  pattern, just 2 bits instead of 64) — no changes needed there.
- **`mux_lib.sv`**'s new `mux64_2to1`/`mux5_2to1` are `generate` loops of
  `mux2_1`, exactly like your existing `mux32_1`/`mux64x32to1` — the
  tutorial's own `generate` examples (`DFF_VAR`, `tugOfWar99`) are the
  model here.

## Two real bugs the benchmark files caught

Checking against your actual `.arm` files (rather than trusting a textbook
reference) turned up two things worth knowing about:

**1. BR's target register is the Rd field, not Rn.** I'd originally guessed
`instr[9:5]` (Rn) by analogy with generic references. Your files prove
otherwise — e.g. `test06_BlBr.arm` encodes `BR X4` as
`11010110000_00000_000000_00000_00100`, with `00100` (=4) sitting in the
**last 5 bits** (Rd position), not the middle 5 bits (Rn position). Fixed
by routing BR's target through the same `Reg2Loc`-selected path STUR/CBZ
already use (`instr[4:0]` → `ReadRegister2` → `ReadData2`), rather than a
separate wire. Confirmed by `test06`'s result: X2 (an error flag that
should stay 0 unless BR jumps to the wrong place) comes out exactly 0.

**2. A transcription slip in ADDI's gate-level decode.** Hand-expanding the
opcode string `1001000100` into individual `and`-gate arguments, I
transposed bits 23 and 24 (used `instr[23]` where it should've been
`instr[24]`, and vice versa). This is exactly the kind of error gate-level
hand-transcription invites, and it slipped past my own first self-test
because the little assembler I'd written to generate that test used the
*same* bit-ordering convention consistently — so encode and decode agreed
with each other while both quietly disagreeing with your actual files.
Caught it by testing `control_unit.sv` in isolation against one of your
real encoded ADDI instructions and comparing every output signal by hand.
The lesson generalizes: bugs that are self-consistent between a
hand-written test and the code under test don't show up until you check
against an independent ground truth — which is exactly what your benchmark
files gave me here.

Every opcode value, field width, and field position in the current
`control_unit.sv` (ADDI, ADDS, SUBS, LDUR, STUR, CBZ, B.cond/B.LT, B, BL,
BR) is now cross-checked line-by-line against your actual encoded
instructions, not inferred from memory.

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
| BR | 1 (Rd) | – | – | 0 | 0 | 0 | 0 | – | PC ← ReadData2 |

CBZ is still the fun one: `Reg2Loc` routes `Rt` into the register file's
second read port, the ALU is told to `PASS_B` (opcode `000`, already in
your `alu.sv`), and the ALU's own `zero` output — computed for free as
part of that pass-through — tells you whether `Rt == 0`. No separate
comparator needed. Only `B.LT` is decoded among the conditional branches,
since it's the only condition your instruction set spec (and every
benchmark) actually uses — checked directly against every `B.cond` line in
all 9 files, all of them encode `cond = 01011` (LT).

## Per-benchmark results (all verified)

| Benchmark | Cycles to halt loop | Result |
|---|---|---|
| test01_AddiB | ~5 | X0=0, X1=1, X2=2, X3=3, X4=4 ✓ |
| test02_AddsSubs | ~9 | X0=1, X1=-1, X2=2, X3=-3, X4=-2, X5=-5, X6=0, X7=-6, N=1, V=0 ✓ |
| test03_CbzB | ~15 | X0=1, X1=0, X2=0, X3=1, X4=31, X5=0 ✓ |
| test04_LdurStur | ~10 | X0=1, X1=2, X2=3, X3=8, X4=11, X5=1, X6=2, X7=3, Mem[0]=1, Mem[8]=2, Mem[16]=3 ✓ |
| test05_Blt | ~7 | X0=1, X1=1 ✓ |
| test06_BlBr | ~17 | X0=1, X1=0, X2=0, X3=1, X4=52, X5=64, X29=20, X30=68 ✓ |
| test10_forwarding | ~60 | X0=0, X1=8, X2=0 (single-cycle), X3=5, X4=7, X5=2, X6=-2, X7=-2, X8=0, X9=1, X10=-4, X14=5, X15=8, X16=9, X17=1, X18=99, Mem[0]=8, Mem[8]=5 ✓ |
| test11_Sort | ~601 | X11..X20 = 1,2,3,4,5,6,7,8,9,10 ✓ |
| test12_Fibonacci | ~236 | X0=6, X1=8, X28=8, X30=196 ✓ |

`cpu_testbench.sv`'s default `NumCycles` (800) comfortably covers all of
these with margin; since every one ends in a self-loop (`B` to itself),
running longer than needed just idles harmlessly.

## Running it

```
vsim -c -do runlab.do
```

To switch benchmarks, edit the `` `define BENCHMARK `` line in
`instructmem.sv` as it already tells you to — point it at whichever file
in the `benchmarks/` folder you want (the ones included here have had
their line endings cleaned up but are otherwise your original files).

The clock period (`ClockDelay` in `cpu_testbench.sv`) is 10,000 ns because
your register file's `mux2_1`/decoder gates use `#50` delays several
levels deep — the handout's "a VERY long clock is fine" warning is not a
joke here. If you add more logic and start seeing `X`s in your registers,
lengthen it further.

`cpu_wave.do` sets up a wave window with clock, reset, PC, instruction,
every control signal, both flags, and all 31 general registers (X0–X30;
X31/XZR is a hardwired constant, not a real register) — satisfying the
"illustrate all register contents, PC, flags, clock and reset" submission
requirement. Data memory is a 1024-byte array, not a bus, so it's shown via
ModelSim's **Memory List** view instead (the script opens it automatically
and loads `dmem.mem`).

## Other things fixed along the way (from the previous round)

**Duplicate `mux2_1`.** Your lab-1 mux file (regfile's `mux2_1`/`mux32_1`/
`mux64x32to1`) and your lab-2 mux file (ALU's `mux2_1`/`mux8_1`) both
define `module mux2_1` identically — compiling both into one project
throws a duplicate-module error. Merged into one **`mux_lib.sv`**
containing `mux2_1` once, plus `mux8_1`, `mux32_1`, `mux64x32to1`, and the
two new ones this lab needs (`mux64_2to1`, `mux5_2to1`). **Use
`mux_lib.sv` in place of both of your old mux files.**

## File list

- `register.sv`, `decoder.sv`, `regfile.sv` — your lab 1 (unchanged)
- `add_sub.sv`, `bitwise.sv`, `flags.sv`, `alu.sv` — your lab 2 (unchanged)
- `mux_lib.sv` — merged mux file (replaces your two originals)
- `flagreg.sv` — N/V flag storage (new, gate-level)
- `imm_extend.sv` — immediate sign/zero-extend (new, gate-level)
- `control_unit.sv` — main control unit (new, gate-level)
- `cpu.sv` — top-level datapath (new)
- `datamem.sv`, `instructmem.sv`, `math.sv` — provided (unchanged)
- `cpu_testbench.sv`, `cpu_wave.do`, `runlab.do` — testbench/ModelSim scripts
- `benchmarks/` — your test programs, cleaned up (CRLF→LF) for convenience
