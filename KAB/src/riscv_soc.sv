// RISC-V SoC with Matrix Accelerator
// Team KAB - VLSI Competition
// Integration of PicoRV32 + Systolic Array Accelerator
`timescale 1ns/1ps

module riscv_soc #(
    parameter MEM_SIZE = 4096  // 16KB memory (4096 x 32-bit words)
) (
    input  logic clk,
    input  logic rst,
    output logic trap,
    
    // Optional debug outputs
    output logic [7:0] debug_out,
    output logic       debug_valid
);

    // PicoRV32 native memory interface
    logic        cpu_mem_valid;
    logic        cpu_mem_instr;
    logic        cpu_mem_ready;
    logic [31:0] cpu_mem_addr;
    logic [31:0] cpu_mem_wdata;
    logic [3:0]  cpu_mem_wstrb;
    logic [31:0] cpu_mem_rdata;
    // PCPI (custom instruction) interface
    logic        pcpi_valid;
    logic [31:0] pcpi_insn;
    logic [31:0] pcpi_rs1;
    logic [31:0] pcpi_rs2;
    logic        pcpi_wr;
    logic [31:0] pcpi_rd;
    logic        pcpi_wait;
    logic        pcpi_ready;
    
    // Memory map:
    // 0x00000000 - 0x00003FFF: RAM (16KB)
    // 0x02000000 - 0x02000093: Matrix Accelerator
    // 0x10000000 - 0x10000003: Debug output
    
    localparam ADDR_RAM_BASE   = 32'h00000000;
    localparam ADDR_RAM_MASK   = 32'h00003FFF;
    localparam ADDR_ACCEL_BASE = 32'h02000000;
    localparam ADDR_ACCEL_MASK = 32'h000000FF;
    localparam ADDR_DEBUG_BASE = 32'h10000000;
    
    // Accelerator interface
    logic        accel_mem_valid;
    logic        accel_mem_write;
    logic [31:0] accel_mem_addr;
    logic [31:0] accel_mem_wdata;
    logic [3:0]  accel_mem_wstrb;
    logic [31:0] accel_mem_rdata;
    logic        accel_mem_ready;

    // Custom-PCPI -> accelerator command interface
    logic        cpci_accel_cmd_valid; // from custom pcpi unit (pulse)
    logic [1:0]  cpci_accel_cmd_type;  // 0=write,1=read
    logic [31:0] cpci_accel_addr;
    logic [31:0] cpci_accel_wdata;
    // internal latched command
    logic        cpci_cmd_active;
    logic [1:0]  cpci_cmd_type_r;
    logic [31:0] cpci_cmd_addr_r;
    logic [31:0] cpci_cmd_wdata_r;

    // Simple on-chip DMA controller state (synthesizable)
    localparam [1:0] DMA_IDLE  = 2'b00;
    localparam [1:0] DMA_READ  = 2'b01;
    localparam [1:0] DMA_WRITE = 2'b10;
    localparam [1:0] DMA_DONE  = 2'b11;
    reg [1:0]      dma_state;
    logic        dma_active;
    logic [31:0] dma_src_base; // byte address in RAM
    logic [15:0] dma_len;      // number of words to transfer
    logic [15:0] dma_pos;      // current word index
    logic [31:0] dma_dst_base; // destination accel offset (byte)
    
    // RAM
    logic [31:0] ram [0:MEM_SIZE-1];
    logic [31:0] ram_rdata;
    logic        ram_ready;
    
    // Chip select signals
    logic        sel_ram;
    logic        sel_accel;
    logic        sel_debug;
    
    // Address decoding
    assign sel_ram   = (cpu_mem_addr & ~ADDR_RAM_MASK) == ADDR_RAM_BASE;
    assign sel_accel = (cpu_mem_addr & ~ADDR_ACCEL_MASK) == ADDR_ACCEL_BASE;
    assign sel_debug = cpu_mem_addr == ADDR_DEBUG_BASE;
    
    // Convert resetn (active low) from rst (active high)
    logic resetn;
    assign resetn = ~rst;
    
    // ============================================================
    // PicoRV32 CPU Instance
    // ============================================================
    picorv32 #(
        .ENABLE_COUNTERS(1),
        .ENABLE_REGS_16_31(1),
        .ENABLE_REGS_DUALPORT(1),
        .BARREL_SHIFTER(1),
        .COMPRESSED_ISA(1),
        .ENABLE_MUL(1),
        .ENABLE_DIV(1),
        .ENABLE_IRQ(0)
    ) cpu (
        .clk(clk),
        .resetn(resetn),
        .trap(trap),
        
    // Memory interface
    .mem_valid(cpu_mem_valid),
    .mem_instr(cpu_mem_instr),
    .mem_ready(cpu_mem_ready),
    .mem_addr(cpu_mem_addr),
    .mem_wdata(cpu_mem_wdata),
    .mem_wstrb(cpu_mem_wstrb),
    .mem_rdata(cpu_mem_rdata),

    // PCPI custom instruction interface
    .pcpi_valid(pcpi_valid),
    .pcpi_insn(pcpi_insn),
    .pcpi_rs1(pcpi_rs1),
    .pcpi_rs2(pcpi_rs2),
    .pcpi_wr(pcpi_wr),
    .pcpi_rd(pcpi_rd),
    .pcpi_wait(pcpi_wait),
    .pcpi_ready(pcpi_ready),
        
    // Unused interfaces
    .mem_la_read(),
    .mem_la_write(),
    .mem_la_addr(),
    .mem_la_wdata(),
    .mem_la_wstrb(),
        .irq(32'h0),
        .eoi(),
        .trace_valid(),
        .trace_data()
    );
    
    // ============================================================
    // Matrix Accelerator Instance
    // ============================================================
    accelerator_wrapper accel (
        .clk(clk),
        .rst(rst),
        .mem_valid(accel_mem_valid),
        .mem_write(accel_mem_write),
        .mem_addr(accel_mem_addr),
        .mem_wdata(accel_mem_wdata),
        .mem_wstrb(accel_mem_wstrb),
        .mem_rdata(accel_mem_rdata),
        .mem_ready(accel_mem_ready)
    );
    
    // Instantiate custom PCPI unit (recognizes a chosen custom opcode and
    // emits accelerator command requests). See src/custom_pcpi.sv for encoding.
    custom_pcpi custom_pcpi_u (
        .clk(clk),
        .rst(rst),
        .pcpi_valid(pcpi_valid),
        .pcpi_insn(pcpi_insn),
        .pcpi_rs1(pcpi_rs1),
        .pcpi_rs2(pcpi_rs2),
        .pcpi_wr(pcpi_wr),
        .pcpi_rd(pcpi_rd),
        .pcpi_wait(pcpi_wait),
        .pcpi_ready(pcpi_ready),

        .accel_cmd_valid(cpci_accel_cmd_valid),
        .accel_cmd_type(cpci_accel_cmd_type),
        .accel_cmd_addr(cpci_accel_addr),
        .accel_cmd_wdata(cpci_accel_wdata)
    );

    // Capture a command from the PCPI unit and hold it until accelerator
    // acknowledges via accel_mem_ready. This allows the custom instruction to
    // request MMIO accesses without CPU software involvement. Also handle DMA
    // start command (type == 2'b10).
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cpci_cmd_active   <= 1'b0;
            cpci_cmd_type_r   <= 2'b0;
            cpci_cmd_addr_r   <= 32'b0;
            cpci_cmd_wdata_r  <= 32'b0;

            // DMA reset
            dma_state     <= DMA_IDLE;
            dma_active    <= 1'b0;
            dma_src_base  <= 32'b0;
            dma_dst_base  <= 32'b0;
            dma_len       <= 16'b0;
            dma_pos       <= 16'b0;
        end else begin
            // Latch new command when presented
            if (cpci_accel_cmd_valid && !cpci_cmd_active) begin
                // If this is a DMA start command, program DMA registers
                if (cpci_accel_cmd_type == 2'b10) begin
                    // Use addr as source base, wdata[15:0] as length, wdata[31:16] as dst offset hi
                    dma_src_base <= cpci_accel_addr;
                    dma_len      <= cpci_accel_wdata[15:0];
                    dma_dst_base <= {16'b0, cpci_accel_wdata[31:16]};
                    dma_pos      <= 16'b0;
                    dma_active   <= 1'b1;
                    dma_state    <= DMA_READ;
                end else begin
                    cpci_cmd_active  <= 1'b1;
                    cpci_cmd_type_r  <= cpci_accel_cmd_type;
                    cpci_cmd_addr_r  <= cpci_accel_addr;
                    cpci_cmd_wdata_r <= cpci_accel_wdata;
                end
            end else if (cpci_cmd_active) begin
                // Clear when accelerator reports ready for the transaction
                if (accel_mem_ready && accel_mem_valid) begin
                    cpci_cmd_active <= 1'b0;
                end
            end

            // DMA state machine: simple synchronous transfer from RAM to accel
            if (dma_active) begin
                // Simple two-cycle transfer per word: READ -> WRITE
                if (dma_state == 2'b01) begin // DMA_READ
                    // advance to write phase; data will be picked from RAM in comb logic
                    dma_state <= 2'b10; // DMA_WRITE
                end else if (dma_state == 2'b10) begin // DMA_WRITE
                    // when the accelerator accepts the write, advance
                    if (accel_mem_ready || !accel_mem_valid) begin
                        if (dma_pos + 1 >= dma_len) begin
                            dma_state  <= 2'b11; // DMA_DONE
                        end else begin
                            dma_pos <= dma_pos + 1;
                            dma_state <= 2'b01; // DMA_READ
                        end
                    end
                end else if (dma_state == 2'b11) begin // DMA_DONE
                    dma_active <= 1'b0;
                    dma_state  <= 2'b00; // DMA_IDLE
                end else begin
                    dma_state <= 2'b00;
                end
            end
        end
    end

    // Accelerator bus multiplexing: prefer custom PCPI-driven commands when
    // active, otherwise forward CPU transactions to the accelerator.
    always @(*) begin
        // Default values
        accel_mem_valid  = 1'b0;
        accel_mem_write  = 1'b0;
        accel_mem_addr   = 32'h0;
        accel_mem_wdata  = 32'h0;
        accel_mem_wstrb  = 4'b0;

        if (dma_active && (dma_state == DMA_WRITE)) begin
            // DMA is performing a write to accelerator: drive accel MMIO
            accel_mem_valid = 1'b1;
            accel_mem_write = 1'b1;
            accel_mem_addr  = ADDR_ACCEL_BASE | (dma_dst_base + (dma_pos * 4));
            // Read data directly from RAM array (word addressed). Bound index to RAM size.
            accel_mem_wdata = ram[(dma_src_base[13:2]) + dma_pos];
            accel_mem_wstrb = 4'b1111;
        end else if (cpci_cmd_active) begin
            // Drive MMIO from latched PCPI command
            accel_mem_valid = 1'b1;
            accel_mem_write = (cpci_cmd_type_r == 2'b00);
            accel_mem_addr  = ADDR_ACCEL_BASE | cpci_cmd_addr_r;
            accel_mem_wdata = cpci_cmd_wdata_r;
            accel_mem_wstrb = 4'b1111;
        end else if (cpu_mem_valid && sel_accel) begin
            // Pass-through CPU MMIO
            accel_mem_valid = cpu_mem_valid;
            accel_mem_write = |cpu_mem_wstrb;
            accel_mem_addr  = cpu_mem_addr;
            accel_mem_wdata = cpu_mem_wdata;
            accel_mem_wstrb = cpu_mem_wstrb;
        end
    end
    
    // ============================================================
    // RAM Logic (Single-cycle read/write)
    // ============================================================
    always_ff @(posedge clk) begin
        if (cpu_mem_valid && sel_ram && |cpu_mem_wstrb) begin
            // Write to RAM
            if (cpu_mem_wstrb[0]) ram[cpu_mem_addr[13:2]][7:0]   <= cpu_mem_wdata[7:0];
            if (cpu_mem_wstrb[1]) ram[cpu_mem_addr[13:2]][15:8]  <= cpu_mem_wdata[15:8];
            if (cpu_mem_wstrb[2]) ram[cpu_mem_addr[13:2]][23:16] <= cpu_mem_wdata[23:16];
            if (cpu_mem_wstrb[3]) ram[cpu_mem_addr[13:2]][31:24] <= cpu_mem_wdata[31:24];
        end
    end
    
    // RAM read (combinational)
    assign ram_rdata = (sel_ram && cpu_mem_valid) ? ram[cpu_mem_addr[13:2]] : 32'h0;
    assign ram_ready = sel_ram;
    
    // ============================================================
    // Debug Output Logic
    // ============================================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            debug_out   <= 8'h0;
            debug_valid <= 1'b0;
        end else begin
            debug_valid <= 1'b0;
            if (cpu_mem_valid && sel_debug && |cpu_mem_wstrb) begin
                debug_out   <= cpu_mem_wdata[7:0];
                debug_valid <= 1'b1;
            end
        end
    end
    
    // ============================================================
    // CPU Memory Response Multiplexing
    // ============================================================
    always @(*) begin
        if (sel_accel) begin
            cpu_mem_rdata = accel_mem_rdata;
            cpu_mem_ready = accel_mem_ready;
        end else if (sel_ram) begin
            cpu_mem_rdata = ram_rdata;
            cpu_mem_ready = ram_ready;
        end else if (sel_debug) begin
            cpu_mem_rdata = 32'h0;
            cpu_mem_ready = 1'b1;
        end else begin
            // Invalid address
            cpu_mem_rdata = 32'hDEADBEEF;
            cpu_mem_ready = 1'b1;
        end
    end
    
    // ============================================================
    // Initialize RAM with test program
    // ============================================================
    initial begin
        // Initialize all RAM to zero
        for (int i = 0; i < MEM_SIZE; i++) begin
            ram[i] = 32'h0;
        end
        
        // Load RISC-V firmware (uncomment to enable CPU-driven test)
        $readmemh("firmware/firmware.hex", ram);
        
        // For now, keep RAM empty - testbench writes directly to accelerator
    end

endmodule
