// 5:32 decoder with enable.
// enable[k] is high iff sel == k AND write_en is high.
// Built as a binary AND-tree, mirroring the mux32_1 tree structure:
// combine 2 bits at a time (max 2-input gates, well within the 4-input
// limit) until all 5 bits of sel are folded in, then gate with write_en.
//
// Stage A: 4 combinations of sel[1:0]      -> g2[0..3]
// Stage B: 4 combinations of sel[3:2]      -> g4[0..3]
// Stage C: 16 combinations of sel[3:0]     -> g16[0..15]  (g4 x g2)
// Stage D: 32 combinations of sel[4:0]     -> g32[0..31]  (sel[4] x g16)
// Stage E: gate each of the 32 with write_en -> enable[0..31]

module decoder5to32 (
    output wire [31:0] enable,
    input  wire [4:0]  sel,
    input  wire        write_en
);

  wire [4:0] comp;   // complements of each select bit
  wire [3:0] g2;     // decode of sel[1:0]
  wire [3:0] g4;     // decode of sel[3:2]
  wire [15:0] g16;   // decode of sel[3:0]
  wire [31:0] g32;   // decode of sel[4:0], before RegWrite gating

  genvar b;
  generate
    for (b = 0; b < 5; b = b + 1) begin : invert_bits
      not #(0.05) g_inv (comp[b], sel[b]);
    end
  endgenerate

  // Stage A: decode sel[1:0] -> g2[0]=00, g2[1]=01, g2[2]=10, g2[3]=11
  and #(0.05) a20 (g2[0], comp[1], comp[0]);
  and #(0.05) a21 (g2[1], comp[1], sel[0]);
  and #(0.05) a22 (g2[2], sel[1],  comp[0]);
  and #(0.05) a23 (g2[3], sel[1],  sel[0]);

  // Stage B: decode sel[3:2] -> same pattern, one bit higher
  and #(0.05) a40 (g4[0], comp[3], comp[2]);
  and #(0.05) a41 (g4[1], comp[3], sel[2]);
  and #(0.05) a42 (g4[2], sel[3],  comp[2]);
  and #(0.05) a43 (g4[3], sel[3],  sel[2]);

  // Stage C: combine into 16-way decode of sel[3:0]
  genvar j;
  generate
    for (j = 0; j < 16; j = j + 1) begin : stage_c
      and #(0.05) g_c (g16[j], g4[j/4], g2[j%4]);
    end
  endgenerate

  // Stage D: fold in sel[4] to get the full 32-way decode
  genvar k;
  generate
    for (k = 0; k < 16; k = k + 1) begin : stage_d_lo
      and #(0.05) g_dlo (g32[k], comp[4], g16[k]);
    end
    for (k = 16; k < 32; k = k + 1) begin : stage_d_hi
      and #(0.05) g_dhi (g32[k], sel[4], g16[k-16]);
    end
  endgenerate

  // Stage E: gate every one-hot line with write_en
  generate
    for (k = 0; k < 32; k = k + 1) begin : stage_e
      and #(0.05) g_e (enable[k], g32[k], write_en);
    end
  endgenerate

endmodule
