// RISC-V Assembly Firmware for Matrix Accelerator/*

// Team KAB - Standard Memory-Mapped I/O Demo * Startup code for RISC-V SoC

// Assembles for RV32I * Minimal initialization and jump to main

 */

.section .text

.globl _start    .section .text.start

    .global _start

_start:

    // Initialize stack pointer_start:

    li sp, 0x4000    /* Set stack pointer */

        la sp, __stack_top

    // Call main function    

    call main    /* Clear BSS */

        la a0, __bss_start

    // Trap on completion    la a1, __bss_end

    ebreakbss_clear:

    beq a0, a1, bss_done

main:    sw zero, 0(a0)

    // Load base address of accelerator (0x02000000)    addi a0, a0, 4

    lui  x10, 0x2000      // x10 = 0x02000000    j bss_clear

    bss_done:

    //========================================    

    // STEP 1: Write Matrix A to accelerator    /* Call main */

    //========================================    call main

    // Matrix A = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]    

        /* If main returns, trap */

    li   x11, 0x10        // Offset for Matrix A start    ebreak

    add  x12, x10, x11    // x12 = base + 0x10    j .

    
    li   x13, 1
    sw   x13, 0(x12)      // A[0] = 1
    li   x13, 2
    sw   x13, 4(x12)      // A[1] = 2
    li   x13, 3
    sw   x13, 8(x12)      // A[2] = 3
    li   x13, 4
    sw   x13, 12(x12)     // A[3] = 4
    li   x13, 5
    sw   x13, 16(x12)     // A[4] = 5
    li   x13, 6
    sw   x13, 20(x12)     // A[5] = 6
    li   x13, 7
    sw   x13, 24(x12)     // A[6] = 7
    li   x13, 8
    sw   x13, 28(x12)     // A[7] = 8
    li   x13, 9
    sw   x13, 32(x12)     // A[8] = 9
    
    //========================================
    // STEP 2: Write Matrix B to accelerator
    //========================================
    // Matrix B = [[9, 8, 7], [6, 5, 4], [3, 2, 1]]
    
    li   x11, 0x40        // Offset for Matrix B start
    add  x12, x10, x11    // x12 = base + 0x40
    
    li   x13, 9
    sw   x13, 0(x12)      // B[0] = 9
    li   x13, 8
    sw   x13, 4(x12)      // B[1] = 8
    li   x13, 7
    sw   x13, 8(x12)      // B[2] = 7
    li   x13, 6
    sw   x13, 12(x12)     // B[3] = 6
    li   x13, 5
    sw   x13, 16(x12)     // B[4] = 5
    li   x13, 4
    sw   x13, 20(x12)     // B[5] = 4
    li   x13, 3
    sw   x13, 24(x12)     // B[6] = 3
    li   x13, 2
    sw   x13, 28(x12)     // B[7] = 2
    li   x13, 1
    sw   x13, 32(x12)     // B[8] = 1
    
    //========================================
    // STEP 3: Start accelerator
    //========================================
    li   x13, 1
    sw   x13, 0(x10)      // Write 1 to control register (start bit)
    
    //========================================
    // STEP 4: Wait for done
    //========================================
wait_loop:
    lw   x14, 0(x10)      // Read control register
    andi x14, x14, 2      // Check bit 1 (done bit)
    beqz x14, wait_loop   // Loop if not done
    
    //========================================
    // STEP 5: Read results and output via debug port
    //========================================
    li   x11, 0x70        // Offset for Matrix C start
    add  x12, x10, x11    // x12 = base + 0x70
    
    lui  x15, 0x1000      // x15 = 0x10000000 (debug port)
    
    // Read and output C[0]
    lw   x13, 0(x12)
    sw   x13, 0(x15)
    
    // Read and output C[1]
    lw   x13, 4(x12)
    sw   x13, 0(x15)
    
    // Read and output C[2]
    lw   x13, 8(x12)
    sw   x13, 0(x15)
    
    // Read and output C[3]
    lw   x13, 12(x12)
    sw   x13, 0(x15)
    
    // Read and output C[4]
    lw   x13, 16(x12)
    sw   x13, 0(x15)
    
    // Read and output C[5]
    lw   x13, 20(x12)
    sw   x13, 0(x15)
    
    // Read and output C[6]
    lw   x13, 24(x12)
    sw   x13, 0(x15)
    
    // Read and output C[7]
    lw   x13, 28(x12)
    sw   x13, 0(x15)
    
    // Read and output C[8]
    lw   x13, 32(x12)
    sw   x13, 0(x15)
    
    // Return
    ret
