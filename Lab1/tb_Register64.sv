`timescale 1ns/10ps

module tb_Register64;

  reg  [63:0] d;
  reg         we, clk;
  wire [63:0] q;

  Register64 dut (.q(q), .d(d), .we(we), .clk(clk));

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    $display("---- Test 1: load a value ----");
    d = 64'hDEAD_BEEF_0000_0001;
    we = 1;
    @(posedge clk); #1;
    $display("t=%0t q=%h (expect deadbeef00000001)", $time, q);

    $display("---- Test 2: hold when we=0, even with different d ----");
    d = 64'hFFFF_FFFF_FFFF_FFFF;
    we = 0;
    @(posedge clk); #1;
    $display("t=%0t q=%h (expect deadbeef00000001, unchanged)", $time, q);

    $display("---- Test 3: load a new value ----");
    d = 64'h1234_5678_9ABC_DEF0;
    we = 1;
    @(posedge clk); #1;
    $display("t=%0t q=%h (expect 123456789abcdef0)", $time, q);

    $display("---- Test 4: we glitches away from clock edge, should NOT corrupt ----");
    we = 0;
    d  = 64'hBAD_BAD_BAD_BAD;
    #1 we = 1; #1 we = 0; #1 we = 1; #1 we = 0; // glitching mid-cycle
    @(posedge clk); #1;
    $display("t=%0t q=%h (we settled to 0 before edge -> expect 123456789abcdef0, unchanged)", $time, q);

    $display("---- Test 5: we is 1 exactly at the clock edge -> should load ----");
    d = 64'hCAFE_CAFE_CAFE_CAFE;
    we = 1;
    @(posedge clk); #1;
    $display("t=%0t q=%h (expect cafecafecafecafe)", $time, q);

    $display("All tests done.");
    $finish;
  end

endmodule
