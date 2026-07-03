`timescale 1ns/10ps

module tb_mux32_1;

  logic [31:0] in;
  logic [4:0]  sel;
  logic        out;
  integer i;
  integer errors;

  mux32_1 dut (.out(out), .in(in), .sel(sel));

  initial begin
    errors = 0;
    // give every input line a distinct, known value
    for (i = 0; i < 32; i = i + 1)
      in[i] = i[0];        // alternating 0/1/0/1... pattern
    in = 32'b10110100_11001010_01011001_00101101; // distinct known pattern

    for (i = 0; i < 32; i = i + 1) begin
      sel = i[4:0];
      #10;
      if (out !== in[i]) begin
        $display("FAIL: sel=%0d out=%b expected=%b", i, out, in[i]);
        errors = errors + 1;
      end else begin
        $display("PASS: sel=%0d out=%b", i, out);
      end
    end

    if (errors == 0)
      $display("ALL 32 SELECT VALUES PASSED");
    else
      $display("%0d FAILURES", errors);

    $finish;
  end

endmodule
