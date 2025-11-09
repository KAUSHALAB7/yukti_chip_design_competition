// MAC Unit Testbench - Quick verification - Pure Verilog
`timescale 1ns/1ps

module mac_unit_tb;
    reg        clk;
    reg        rst;
    reg        enable;
    reg        clear_acc;
    reg signed [7:0] a;
    reg signed [7:0] b;
    wire signed [31:0] acc;
    
    // DUT
    mac_unit dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .clear_acc(clear_acc),
        .a(a),
        .b(b),
        .acc(acc)
    );
    
    // Clock generation - 10ns period (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Test sequence
    initial begin
        $display("[MAC TB] Starting test...");
        
        // Initialize
        rst = 1;
        enable = 0;
        clear_acc = 0;
        a = 8'sd0;
        b = 8'sd0;
        
        // Reset
        #20 rst = 0;
        #10;
        
        // Test 1: Simple MAC - 2*3 + 4*5 + 1*1 = 6 + 20 + 1 = 27
        $display("[TEST 1] MAC operations: 2*3 + 4*5 + 1*1");
        enable = 1;
        
        a = 8'sd2; b = 8'sd3;
        #10;
        $display("  After 2*3: acc = %0d (expected 6)", acc);
        
        a = 8'sd4; b = 8'sd5;
        #10;
        $display("  After 4*5: acc = %0d (expected 26)", acc);
        
        a = 8'sd1; b = 8'sd1;
        #10;
        $display("  After 1*1: acc = %0d (expected 27)", acc);
        
        // Test 2: Clear and new accumulation
        $display("[TEST 2] Clear accumulator");
        clear_acc = 1;
        #10;
        clear_acc = 0;
        $display("  After clear: acc = %0d (expected 0)", acc);
        
        // Test 3: Negative numbers
        $display("[TEST 3] Negative: (-5)*3 + 2*(-4) = -15 + -8 = -23");
        a = -8'sd5; b = 8'sd3;
        #10;
        $display("  After (-5)*3: acc = %0d (expected -15)", acc);
        
        a = 8'sd2; b = -8'sd4;
        #10;
        $display("  After 2*(-4): acc = %0d (expected -23)", acc);
        
        // Done
        #20;
        $display("[MAC TB] All tests complete!");
        $finish;
    end
    
    // Waveform dump
    initial begin
        $dumpfile("KAB/sim/waves/mac_unit.vcd");
        $dumpvars(0, mac_unit_tb);
    end

endmodule
