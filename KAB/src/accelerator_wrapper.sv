// Simple Memory-Mapped Accelerator Wrapper (No RISC-V)
// For demonstration and synthesis
`timescale 1ns/1ps

module accelerator_wrapper (
    input  logic clk,
    input  logic rst,
    
    // Simple memory-mapped interface
    input  logic        mem_valid,
    input  logic        mem_write,
    input  logic [31:0] mem_addr,
    input  logic [31:0] mem_wdata,
    input  logic [3:0]  mem_wstrb,
    output logic [31:0] mem_rdata,
    output logic        mem_ready
);

    // Memory map (FIXED - no overlaps):
    // 0x00: Control (bit 0 = start, bit 1 = done - read only)
    // 0x10-0x33: Matrix A (9 elements, 4 bytes each = 36 bytes)
    // 0x40-0x63: Matrix B (9 elements, 4 bytes each = 36 bytes)  
    // 0x70-0x93: Matrix C (9 elements, 4 bytes each = 36 bytes, read only)
    
    localparam ADDR_CTRL  = 8'h00;
    localparam ADDR_MAT_A = 8'h10;
    localparam ADDR_MAT_B = 8'h40;  // Changed from 0x30 to avoid overlap
    localparam ADDR_MAT_C = 8'h70;  // Changed from 0x50 for clarity
    
    // Accelerator signals
    logic        accel_start;
    logic        accel_done;
    logic signed [7:0] mat_a [0:8];
    logic signed [7:0] mat_b [0:8];
    logic signed [31:0] mat_c [0:8];
    
    // Instantiate the systolic array accelerator
    systolic_array_3x3 accel (
        .clk(clk),
        .rst(rst),
        .start(accel_start),
        .mat_a(mat_a),
        .mat_b(mat_b),
        .mat_c(mat_c),
        .done(accel_done)
    );
    
    // Memory interface logic
    logic [7:0] addr_offset;
    assign addr_offset = mem_addr[7:0];
    
    // Write logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            accel_start <= 0;
            for (int i = 0; i < 9; i++) begin
                mat_a[i] <= 8'sd0;
                mat_b[i] <= 8'sd0;
            end
        end else begin
            // Handle writes
            if (mem_valid && mem_write) begin
                case (addr_offset)
                    ADDR_CTRL: begin
                        if (mem_wstrb[0])
                            accel_start <= mem_wdata[0];
                    end
                    
                    // Matrix A writes (byte addressable, but we use lower byte of word)
                    ADDR_MAT_A + 8'h00: if (mem_wstrb[0]) mat_a[0] <= mem_wdata[7:0];
                    ADDR_MAT_A + 8'h04: if (mem_wstrb[0]) mat_a[1] <= mem_wdata[7:0];
                    ADDR_MAT_A + 8'h08: if (mem_wstrb[0]) mat_a[2] <= mem_wdata[7:0];
                    ADDR_MAT_A + 8'h0C: if (mem_wstrb[0]) mat_a[3] <= mem_wdata[7:0];
                    ADDR_MAT_A + 8'h10: if (mem_wstrb[0]) mat_a[4] <= mem_wdata[7:0];
                    ADDR_MAT_A + 8'h14: if (mem_wstrb[0]) mat_a[5] <= mem_wdata[7:0];
                    ADDR_MAT_A + 8'h18: if (mem_wstrb[0]) mat_a[6] <= mem_wdata[7:0];
                    ADDR_MAT_A + 8'h1C: if (mem_wstrb[0]) mat_a[7] <= mem_wdata[7:0];
                    ADDR_MAT_A + 8'h20: if (mem_wstrb[0]) mat_a[8] <= mem_wdata[7:0];
                    
                    // Matrix B writes
                    ADDR_MAT_B + 8'h00: if (mem_wstrb[0]) mat_b[0] <= mem_wdata[7:0];
                    ADDR_MAT_B + 8'h04: if (mem_wstrb[0]) mat_b[1] <= mem_wdata[7:0];
                    ADDR_MAT_B + 8'h08: if (mem_wstrb[0]) mat_b[2] <= mem_wdata[7:0];
                    ADDR_MAT_B + 8'h0C: if (mem_wstrb[0]) mat_b[3] <= mem_wdata[7:0];
                    ADDR_MAT_B + 8'h10: if (mem_wstrb[0]) mat_b[4] <= mem_wdata[7:0];
                    ADDR_MAT_B + 8'h14: if (mem_wstrb[0]) mat_b[5] <= mem_wdata[7:0];
                    ADDR_MAT_B + 8'h18: if (mem_wstrb[0]) mat_b[6] <= mem_wdata[7:0];
                    ADDR_MAT_B + 8'h1C: if (mem_wstrb[0]) mat_b[7] <= mem_wdata[7:0];
                    ADDR_MAT_B + 8'h20: if (mem_wstrb[0]) mat_b[8] <= mem_wdata[7:0];
                endcase
            end
        end
    end
    
    // Read logic (combinational)
    always_comb begin
        mem_rdata = 32'h0;
        mem_ready = 1'b1;  // Always ready (single cycle)
        
        if (mem_valid && !mem_write) begin
            case (addr_offset)
                ADDR_CTRL: begin
                    mem_rdata = {30'h0, accel_done, accel_start};
                end
                
                // Matrix C reads (result, 32-bit values)
                ADDR_MAT_C + 8'h00: mem_rdata = mat_c[0];
                ADDR_MAT_C + 8'h04: mem_rdata = mat_c[1];
                ADDR_MAT_C + 8'h08: mem_rdata = mat_c[2];
                ADDR_MAT_C + 8'h0C: mem_rdata = mat_c[3];
                ADDR_MAT_C + 8'h10: mem_rdata = mat_c[4];
                ADDR_MAT_C + 8'h14: mem_rdata = mat_c[5];
                ADDR_MAT_C + 8'h18: mem_rdata = mat_c[6];
                ADDR_MAT_C + 8'h1C: mem_rdata = mat_c[7];
                ADDR_MAT_C + 8'h20: mem_rdata = mat_c[8];
                
                default: mem_rdata = 32'hDEADBEEF;  // Invalid address
            endcase
        end
    end

endmodule
