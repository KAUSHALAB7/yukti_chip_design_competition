// 3x3 Matrix Multiplication Accelerator - SystemVerilog
// High-performance parallel implementation using 9 MAC units
`timescale 1ns/1ps

module matrix_accelerator_3x3 (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic signed [7:0] mat_a [0:8],  // Matrix A (flattened 3x3)
    input  logic signed [7:0] mat_b [0:8],  // Matrix B (flattened 3x3)
    output logic signed [31:0] mat_c [0:8], // Result C (flattened 3x3)
    output logic        done
);

    // FSM states
    typedef enum logic [1:0] {
        IDLE,
        COMPUTE,
        DONE_STATE
    } state_t;
    
    state_t state, next_state;
    logic [1:0] k_count;  // Counter for k=0,1,2
    logic computing;
    
    // 9 MAC units
    logic signed [7:0] mac_a_in [0:8];
    logic signed [7:0] mac_b_in [0:8];
    logic signed [31:0] mac_acc [0:8];
    logic mac_enable [0:8];
    logic mac_clear [0:8];
    
    // Instantiate 9 MAC units
    genvar i;
    generate
        for (i = 0; i < 9; i++) begin : mac_units
            mac_unit mac_inst (
                .clk(clk),
                .rst(rst),
                .enable(mac_enable[i]),
                .clear_acc(mac_clear[i]),
                .a(mac_a_in[i]),
                .b(mac_b_in[i]),
                .acc(mac_acc[i])
            );
        end
    endgenerate
    
    // FSM state register
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = COMPUTE;
            COMPUTE: if (k_count == 2'd2 && computing) next_state = DONE_STATE;
            DONE_STATE: if (!start) next_state = IDLE;
        endcase
    end
    
    // Counter for k (0, 1, 2)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            k_count <= 2'd0;
            computing <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    k_count <= 2'd0;
                    computing <= 1'b0;
                end
                COMPUTE: begin
                    computing <= 1'b1;
                    if (k_count < 2'd2)
                        k_count <= k_count + 1;
                end
                default: begin
                    computing <= 1'b0;
                end
            endcase
        end
    end
    
    // Control signals
    always_comb begin
        for (int i = 0; i < 9; i++) begin
            mac_enable[i] = (state == COMPUTE);
            mac_clear[i] = (state == IDLE && start);
        end
    end
    
    // Compute logic: Route inputs to MACs
    // mat_c[i][j] = sum_k(mat_a[i][k] * mat_b[k][j])
    // Flattened: idx = i*3 + j
    always_comb begin
        // Explicitly unroll to avoid iverilog issues
        // Row 0
        mac_a_in[0] = mat_a[0*3 + k_count]; mac_b_in[0] = mat_b[k_count*3 + 0];
        mac_a_in[1] = mat_a[0*3 + k_count]; mac_b_in[1] = mat_b[k_count*3 + 1];
        mac_a_in[2] = mat_a[0*3 + k_count]; mac_b_in[2] = mat_b[k_count*3 + 2];
        // Row 1
        mac_a_in[3] = mat_a[1*3 + k_count]; mac_b_in[3] = mat_b[k_count*3 + 0];
        mac_a_in[4] = mat_a[1*3 + k_count]; mac_b_in[4] = mat_b[k_count*3 + 1];
        mac_a_in[5] = mat_a[1*3 + k_count]; mac_b_in[5] = mat_b[k_count*3 + 2];
        // Row 2
        mac_a_in[6] = mat_a[2*3 + k_count]; mac_b_in[6] = mat_b[k_count*3 + 0];
        mac_a_in[7] = mat_a[2*3 + k_count]; mac_b_in[7] = mat_b[k_count*3 + 1];
        mac_a_in[8] = mat_a[2*3 + k_count]; mac_b_in[8] = mat_b[k_count*3 + 2];
    end
    
    // Output assignment - continuous from MAC accumulators
    assign mat_c = mac_acc;
    assign done = (state == DONE_STATE);

endmodule
