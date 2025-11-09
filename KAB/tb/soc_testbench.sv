// RISC-V SoC Testbench with Matrix Accelerator
// Tests CPU + Accelerator integration
`timescale 1ns/1ps

module riscv_soc_tb;
    logic clk;
    logic rst;
    logic trap;
    logic [7:0] debug_out;
    logic       debug_valid;
    
    // DUT instantiation
    riscv_soc #(
        .MEM_SIZE(4096)
    ) dut (
        .clk(clk),
        .rst(rst),
        .trap(trap),
        .debug_out(debug_out),
        .debug_valid(debug_valid)
    );
    
    // Clock generation (50 MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;  // 20ns period
    end
    
    // Test matrices
    logic signed [7:0] test_mat_a [0:8];
    logic signed [7:0] test_mat_b [0:8];
    logic signed [31:0] expected_c [0:8];
    
    // Address definitions (must match SoC memory map)
    localparam ACCEL_BASE  = 32'h02000000;
    localparam ACCEL_CTRL  = ACCEL_BASE + 32'h00;
    localparam ACCEL_MAT_A = ACCEL_BASE + 32'h10;
    localparam ACCEL_MAT_B = ACCEL_BASE + 32'h40;
    localparam ACCEL_MAT_C = ACCEL_BASE + 32'h70;
    
    // Test stimulus
    initial begin
        $dumpfile("sim/waves/riscv_soc.vcd");
        $dumpvars(0, riscv_soc_tb);
        
        // Initialize test matrices
        // Test 1: Simple 3x3 multiplication
        // A = [[1, 2, 3],     B = [[9, 8, 7],
        //      [4, 5, 6],          [6, 5, 4],
        //      [7, 8, 9]]          [3, 2, 1]]
        
        test_mat_a[0] = 8'sd1;  test_mat_a[1] = 8'sd2;  test_mat_a[2] = 8'sd3;
        test_mat_a[3] = 8'sd4;  test_mat_a[4] = 8'sd5;  test_mat_a[5] = 8'sd6;
        test_mat_a[6] = 8'sd7;  test_mat_a[7] = 8'sd8;  test_mat_a[8] = 8'sd9;
        
        test_mat_b[0] = 8'sd9;  test_mat_b[1] = 8'sd8;  test_mat_b[2] = 8'sd7;
        test_mat_b[3] = 8'sd6;  test_mat_b[4] = 8'sd5;  test_mat_b[5] = 8'sd4;
        test_mat_b[6] = 8'sd3;  test_mat_b[7] = 8'sd2;  test_mat_b[8] = 8'sd1;
        
        // Expected result C = A * B
        expected_c[0] = 32'sd30;  expected_c[1] = 32'sd24;  expected_c[2] = 32'sd18;
        expected_c[3] = 32'sd84;  expected_c[4] = 32'sd69;  expected_c[5] = 32'sd54;
        expected_c[6] = 32'sd138; expected_c[7] = 32'sd114; expected_c[8] = 32'sd90;
        
        $display("========================================");
        $display("RISC-V SoC + Matrix Accelerator Test");
        $display("========================================");
        
        // Reset sequence
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        $display("[%0t] Reset released", $time);
        
        // Load test program into RAM
        load_test_program();
        
        // Wait for program to execute
        // The program will:
        // 1. Write matrices to accelerator
        // 2. Start computation
        // 3. Wait for done
        // 4. Read results
        // 5. Output debug info
        
        $display("[%0t] Waiting for CPU execution...", $time);
        
        // Monitor debug output
        fork
            begin
                repeat(10) begin
                    @(posedge debug_valid);
                    $display("[%0t] Debug output: 0x%02h ('%c')", $time, debug_out, 
                             (debug_out >= 32 && debug_out < 127) ? debug_out : ".");
                end
            end
            begin
                // Timeout after 100us
                #100000;
                $display("[%0t] WARNING: Test timeout!", $time);
            end
            begin
                // Wait for trap (program completion)
                @(posedge trap);
                $display("[%0t] CPU trapped - program completed", $time);
            end
        join_any
        
        // Check accelerator results directly
        #100;
        check_accelerator_results();
        
        $display("========================================");
        $display("Test completed");
        $display("========================================");
        $finish;
    end
    
    // Task to load a simple test program
    task load_test_program();
        begin
            $display("[%0t] Loading test program into RAM...", $time);
            
            // For now, we'll manually write to the accelerator
            // In a real system, this would be RISC-V machine code
            
            // TODO: Replace with actual RISC-V firmware
            // For simulation, we'll write directly through testbench
            
            $display("[%0t] Direct accelerator test (bypassing CPU for now)...", $time);
            
            // Write Matrix A
            for (int i = 0; i < 9; i++) begin
                write_accel(ACCEL_MAT_A + i*4, {24'h0, test_mat_a[i]});
            end
            
            // Write Matrix B
            for (int i = 0; i < 9; i++) begin
                write_accel(ACCEL_MAT_B + i*4, {24'h0, test_mat_b[i]});
            end
            
            // Start computation
            write_accel(ACCEL_CTRL, 32'h1);
            
            // Wait for completion
            wait_for_done();
        end
    endtask
    
    // Task to write to accelerator (direct access for testing)
    task write_accel(input [31:0] addr, input [31:0] data);
        begin
            // Force write through memory interface
            @(posedge clk);
            force dut.accel_mem_valid = 1'b1;
            force dut.accel_mem_write = 1'b1;
            force dut.accel_mem_addr = addr;
            force dut.accel_mem_wdata = data;
            force dut.accel_mem_wstrb = 4'b1111;
            @(posedge clk);
            release dut.accel_mem_valid;
            release dut.accel_mem_write;
            release dut.accel_mem_addr;
            release dut.accel_mem_wdata;
            release dut.accel_mem_wstrb;
        end
    endtask
    
    // Task to read from accelerator
    task read_accel(input [31:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            force dut.accel_mem_valid = 1'b1;
            force dut.accel_mem_write = 1'b0;
            force dut.accel_mem_addr = addr;
            @(posedge clk);
            @(posedge clk);  // Wait for response
            data = dut.accel_mem_rdata;
            release dut.accel_mem_valid;
            release dut.accel_mem_write;
            release dut.accel_mem_addr;
        end
    endtask
    
    // Task to wait for accelerator done
    task wait_for_done();
        reg [31:0] status;
        integer timeout;
        reg done_flag;
        begin
            timeout = 0;
            $display("[%0t] Waiting for accelerator to finish...", $time);
            done_flag = 1'b0;
            for (timeout = 0; timeout <= 100; timeout = timeout + 1) begin
                read_accel(ACCEL_CTRL, status);
                if (status[1]) begin
                    $display("[%0t] Accelerator finished!", $time);
                    done_flag = 1'b1;
                    timeout = 101; // force exit
                end
                else #100;
            end
            if (!done_flag)
                $display("[%0t] ERROR: Accelerator timeout! (waited %0d cycles)", $time, timeout);
        end
    endtask
    
    // Task to check accelerator results
    task check_accelerator_results();
        logic [31:0] result;
        integer errors;
        begin
            errors = 0;
            $display("[%0t] Checking accelerator results...", $time);
            
            for (int i = 0; i < 9; i++) begin
                read_accel(ACCEL_MAT_C + i*4, result);
                $display("  C[%0d] = %0d (expected %0d) %s", 
                         i, $signed(result), $signed(expected_c[i]),
                         (result == expected_c[i]) ? "✓" : "✗");
                if (result != expected_c[i]) errors++;
            end
            
            if (errors == 0) begin
                $display("✅ ALL TESTS PASSED!");
            end else begin
                $display("❌ %0d ERRORS FOUND!", errors);
            end
        end
    endtask

endmodule
