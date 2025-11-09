// MAC Unit - 8-bit signed multiply-accumulate
// Team KAB - 4-hour hackathon - Pure Verilog
`timescale 1ns/1ps

module mac_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        enable,      // Start MAC operation
    input  wire        clear_acc,   // Clear accumulator
    input  wire signed [7:0] a,     // 8-bit signed input A
    input  wire signed [7:0] b,     // 8-bit signed input B
    output wire signed [31:0] acc   // 32-bit accumulator output
);

    // Internal accumulator
    reg signed [31:0] accumulator;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            accumulator <= 32'sd0;
        end else if (clear_acc) begin
            accumulator <= 32'sd0;
        end else if (enable) begin
            // MAC operation: acc = acc + (a * b)
            accumulator <= accumulator + (a * b);
        end
    end
    
    assign acc = accumulator;

endmodule
