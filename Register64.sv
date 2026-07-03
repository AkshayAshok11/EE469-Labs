// Register64: a 64-bit register with a write-enable, built entirely
// from D_FF (the given primitive) plus basic gates.
//
// The D_FF itself has no enable pin, so "enable" is implemented with
// a 2:1 mux on the D_FF's d input:
//   we=1 -> d_muxed = d        (load new data)
//   we=0 -> d_muxed = q        (hold: FF re-latches its own output)
//
// Because the FF only samples d_muxed at the clock edge, this is
// naturally immune to we glitches that occur away from the clock edge --
// only the value of we (and d) at the instant of the edge matters.

module Register64 (
    output [63:0] q,
    input  [63:0] d,
    input         we,
    input         clk
);

  wire we_n;
  wire [63:0] d_muxed;
  wire [63:0] and_new, and_hold;

  not #(0.05) inv_we (we_n, we);

  genvar i;
  generate
    for (i = 0; i < 64; i = i + 1) begin : bitslice
      and #(0.05) a_new  (and_new[i],  d[i], we);
      and #(0.05) a_hold (and_hold[i], q[i], we_n);
      or  #(0.05) o_mux  (d_muxed[i], and_new[i], and_hold[i]);

      D_FF ff (.q(q[i]), .d(d_muxed[i]), .reset(1'b0), .clk(clk));
    end
  endgenerate

endmodule
