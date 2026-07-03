`timescale 1ns/10ps

module tb_mux64x32to1;

  logic [63:0] regs [0:31];
  logic [4:0]  sel;
  logic [63:0] out;
  integer i;
  integer errors;

  mux64x32to1 dut (.out(out), .regs(regs), .sel(sel));

  initial begin
    errors = 0;
    // give each of the 32 "registers" a distinct, recognizable value
    for (i = 0; i < 32; i = i + 1)
      regs[i] = i * 64'h0000_0102_0408_0001;

    for (i = 0; i < 32; i = i + 1) begin
      sel = i[4:0];
      #10;
      if (out !== regs[i]) begin
        $display("FAIL: sel=%0d out=%h expected=%h", i, out, regs[i]);
        errors = errors + 1;
      end else begin
        $display("PASS: sel=%0d out=%h", i, out);
      end
    end

    if (errors == 0)
      $display("ALL 32 SELECT VALUES PASSED");
    else
      $display("%0d FAILURES", errors);

    $finish;
  end

endmodule
