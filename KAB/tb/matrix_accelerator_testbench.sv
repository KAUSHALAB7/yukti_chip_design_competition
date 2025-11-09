// Systolic Array 3x3 Testbench - Pure Verilog
`timescale 1ns/1ps

module matrix_accelerator_testbench;
    logic        clk;
    logic        rst;
    logic        start;
    
    // Matrix A, B, C as arrays (SystemVerilog)
    logic signed [7:0] mat_a [0:8];
    logic signed [7:0] mat_b [0:8];
    logic signed [31:0] mat_c [0:8];
    
    logic done;
    
    // DUT
    matrix_accelerator_3x3 dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mat_a(mat_a),
        .mat_b(mat_b),
        .mat_c(mat_c),
        .done(done)
    );
    
    // Clock generation - 10ns period (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Test sequence
    initial begin
        $display("[SYSTOLIC TB] Starting 3x3 Matrix Multiplication Test");
        
        // Initialize
        rst = 1;
        start = 0;
        for (int i = 0; i < 9; i++) begin
            mat_a[i] = 0;
            mat_b[i] = 0;
        end
        
        // Reset
        #20 rst = 0;
        #10;
        
        // Test 1: Matrix multiplication
        // A = [[1, 2, 3],      B = [[9,  8,  7],
        //      [4, 5, 6],           [13, 6,  5],
        //      [7, 8, 9]]           [3,  2,  1]]
        $display("\n[TEST 1] Matrix Multiplication A * B");
        $display("Matrix A:");
        $display("  [1  2  3]");
        $display("  [4  5  6]");
        $display("  [7  8  9]");
        $display("Matrix B:");
        $display("  [9  8  7]");
        $display("  [13 6  5]");
        $display("  [3  2  1]");
        
        // Load matrix A (row-major: [row*3 + col])
        mat_a[0] = 8'sd1; mat_a[1] = 8'sd2; mat_a[2] = 8'sd3;
        mat_a[3] = 8'sd4; mat_a[4] = 8'sd5; mat_a[5] = 8'sd6;
        mat_a[6] = 8'sd7; mat_a[7] = 8'sd8; mat_a[8] = 8'sd9;
        
        // Load matrix B (row-major)
        mat_b[0] = 8'sd9;  mat_b[1] = 8'sd8;  mat_b[2] = 8'sd7;
        mat_b[3] = 8'sd13; mat_b[4] = 8'sd6;  mat_b[5] = 8'sd5;
        mat_b[6] = 8'sd3;  mat_b[7] = 8'sd2;  mat_b[8] = 8'sd1;
        
        start = 1;
        #10 start = 0;
        
        // Wait for done
        // Wait for done
        @(posedge done);
        #10;
        
        $display("\nMAC Accumulators (internal):");
        for (int i = 0; i < 9; i++) begin
            $write(" [%0d]=%0d", i, dut.mac_acc[i]);
        end
        $display("");
        
        $display("\nResult C = A * B:");
        $display("  [%0d  %0d  %0d]", dut.mac_acc[0], dut.mac_acc[1], dut.mac_acc[2]);
        $display("  [%0d  %0d  %0d]", dut.mac_acc[3], dut.mac_acc[4], dut.mac_acc[5]);
        $display("  [%0d  %0d  %0d]", dut.mac_acc[6], dut.mac_acc[7], dut.mac_acc[8]);
        
        // Verify (manual calculation):
        // C[0][0] = 1*9 + 2*13 + 3*3 = 9 + 26 + 9 = 44
        // C[0][1] = 1*8 + 2*6 + 3*2 = 8 + 12 + 6 = 26
        // C[0][2] = 1*7 + 2*5 + 3*1 = 7 + 10 + 3 = 20
        // C[1][0] = 4*9 + 5*13 + 6*3 = 36 + 65 + 18 = 119
        // C[1][1] = 4*8 + 5*6 + 6*2 = 32 + 30 + 12 = 74
        // C[1][2] = 4*7 + 5*5 + 6*1 = 28 + 25 + 6 = 59
        // C[2][0] = 7*9 + 8*13 + 9*3 = 63 + 104 + 27 = 194
        // C[2][1] = 7*8 + 8*6 + 9*2 = 56 + 48 + 18 = 122
        // C[2][2] = 7*7 + 8*5 + 9*1 = 49 + 40 + 9 = 98
        if (dut.mac_acc[0] == 44 && dut.mac_acc[1] == 26 && dut.mac_acc[2] == 20 &&
            dut.mac_acc[3] == 119 && dut.mac_acc[4] == 74 && dut.mac_acc[5] == 59 &&
            dut.mac_acc[6] == 194 && dut.mac_acc[7] == 122 && dut.mac_acc[8] == 98)
            $display("✓ TEST 1 PASSED");
        else
            $display("✗ TEST 1 FAILED");

        
        // Test 2: Another matrix multiplication
        // A = [[1, 2, 0],      B = [[2, 1, 0],
        //      [3, 4, 0],           [1, 2, 0],
        //      [0, 0, 0]]           [0, 0, 0]]
        $display("\n[TEST 2] Matrix Multiplication");
        $display("Matrix A:");
        $display("  [1  2  0]");
        $display("  [3  4  0]");
        $display("  [0  0  0]");
        $display("Matrix B:");
        $display("  [2  1  0]");
        $display("  [1  2  0]");
        $display("  [0  0  0]");
        
        #30;
        
        mat_a[0] = 8'sd1; mat_a[1] = 8'sd2; mat_a[2] = 8'sd0;
        mat_a[3] = 8'sd3; mat_a[4] = 8'sd4; mat_a[5] = 8'sd0;
        mat_a[6] = 8'sd0; mat_a[7] = 8'sd0; mat_a[8] = 8'sd0;
        
        mat_b[0] = 8'sd2; mat_b[1] = 8'sd1; mat_b[2] = 8'sd0;
        mat_b[3] = 8'sd1; mat_b[4] = 8'sd2; mat_b[5] = 8'sd0;
        mat_b[6] = 8'sd0; mat_b[7] = 8'sd0; mat_b[8] = 8'sd0;
        
        start = 1;
        #10 start = 0;
        
        // Wait for done
        @(posedge done);
        #10;
        
        $display("\nResult C = A * B:");
        $display("  [%0d  %0d  %0d]", dut.mac_acc[0], dut.mac_acc[1], dut.mac_acc[2]);
        $display("  [%0d  %0d  %0d]", dut.mac_acc[3], dut.mac_acc[4], dut.mac_acc[5]);
        $display("  [%0d  %0d  %0d]", dut.mac_acc[6], dut.mac_acc[7], dut.mac_acc[8]);
        
        // Verify:
        // C[0][0] = 1*2 + 2*1 + 0*0 = 4
        // C[0][1] = 1*1 + 2*2 + 0*0 = 5
        // C[1][0] = 3*2 + 4*1 + 0*0 = 10
        // C[1][1] = 3*1 + 4*2 + 0*0 = 11
        if (dut.mac_acc[0] == 4 && dut.mac_acc[1] == 5 && dut.mac_acc[2] == 0 &&
            dut.mac_acc[3] == 10 && dut.mac_acc[4] == 11 && dut.mac_acc[5] == 0 &&
            dut.mac_acc[6] == 0 && dut.mac_acc[7] == 0 && dut.mac_acc[8] == 0)
            $display("✓ TEST 2 PASSED");
        else
            $display("✗ TEST 2 FAILED");

        
        #50;
        $display("\n[SYSTOLIC TB] All tests complete!");
        $finish;
    end
    
    // Waveform dump
    initial begin
        $dumpfile("sim/waves/matrix_accelerator.vcd");
        $dumpvars(0, matrix_accelerator_testbench);
    end

endmodule
