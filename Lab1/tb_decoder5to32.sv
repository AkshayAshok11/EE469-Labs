`timescale 1ns/10ps

module tb_decoder5to32;

  logic [4:0]  sel;
  logic        write_en;
  wire  [31:0] enable;

  integer i, k;
  integer errors;

  decoder5to32 dut (.enable(enable), .sel(sel), .write_en(write_en));

  initial begin
    errors = 0;

    $display("---- write_en = 1: expect exactly one hot line per sel ----");
    write_en = 1;
    for (i = 0; i < 32; i = i + 1) begin
      sel = i[4:0];
      #10;
      if (enable !== (32'b1 << i)) begin
        $display("FAIL: sel=%0d enable=%b expected=%b", i, enable, (32'b1 << i));
        errors = errors + 1;
      end else begin
        $display("PASS: sel=%0d enable=%b", i, enable);
      end
    end

    $display("---- write_en = 0: expect all zero regardless of sel ----");
    write_en = 0;
    for (i = 0; i < 32; i = i + 4) begin  // spot-check every 4th value
      sel = i[4:0];
      #10;
      if (enable !== 32'b0) begin
        $display("FAIL: sel=%0d write_en=0 enable=%b expected=0", i, enable);
        errors = errors + 1;
      end else begin
        $display("PASS: sel=%0d write_en=0 enable=%b", i, enable);
      end
    end

    if (errors == 0)
      $display("ALL DECODER TESTS PASSED");
    else
      $display("%0d FAILURES", errors);

    $finish;
  end

endmodule
