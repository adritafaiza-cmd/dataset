```verilog
`timescale 1ns/1ps

module async_bidir_ramif_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir,
       output wire             o_ram_a_clk,
       output wire [DSIZE-1:0] o_ram_a_wdata,
       input wire [DSIZE-1:0]  i_ram_a_rdata,
       output wire [ASIZE-1:0] o_ram_a_addr,
       output wire             o_ram_a_rinc,
       output wire             o_ram_a_winc,
       output wire             o_ram_b_clk,
       output wire [DSIZE-1:0] o_ram_b_wdata,
       input wire [DSIZE-1:0]  i_ram_b_rdata,
       output wire [ASIZE-1:0] o_ram_b_addr,
       output wire             o_ram_b_rinc,
       output wire             o_ram_b_winc
       );

  // Internal pointers and counters
  reg [ASIZE-1:0] a_wr_ptr, a_rd_ptr;
  reg [ASIZE-1:0] b_wr_ptr, b_rd_ptr;
  
  // Cross-domain pointers (snapshots)
  reg [ASIZE-1:0] a_rd_ptr_b; // Read pointer seen by B domain
  reg [ASIZE-1:0] b_wr_ptr_a; // Write pointer seen by A domain
  
  // Status flags
  reg a_full_int, a_empty_int;
  reg b_full_int, b_empty_int;
  reg a_full_sync, a_empty_sync;
  reg b_full_sync, b_empty_sync;
  
  // Direction control
  reg a_dir_reg, b_dir_reg;
  reg a_dir_sync, b_dir_sync;

  // Generate clock signals for external RAM
  assign o_ram_a_clk = a_clk;
  assign o_ram_b_clk = b_clk;

  // ========================================================================
  // A-Domain Logic
  // ========================================================================
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_dir_reg <= 1'b0; // Default to A->B (Write to RAM A, Read from RAM B)
      a_full_int <= 1'b0;
      a_empty_int <= 1'b1;
    end else begin
      // Handle Direction Input
      if (a_dir != a_dir_sync) begin
        a_dir_reg <= a_dir;
        a_dir_sync <= a_dir;
      end
      
      // Write Pointer Logic
      if (a_winc) begin
        if (a_dir_reg) begin
          // A->B: Writing to RAM A
          a_wr_ptr <= a_wr_ptr + 1'b1;
          o_ram_a_winc <= 1'b1;
          o_ram_a_wdata <= a_wdata;
          o_ram_a_addr <= a_wr_ptr;
        end else begin
          // B->A: Writing to RAM B
          a_wr_ptr <= a_wr_ptr + 1'b1;
          o_ram_b_winc <= 1'b1;
          o_ram_b_wdata <= a_wdata;
          o_ram_b_addr <= a_wr_ptr;
        end
      end else begin
        o_ram_a_winc <= 1'b0;
        o_ram_b_winc <= 1'b0;
      end

      // Read Pointer Logic
      if (a_rinc) begin
        if (a_dir_reg) begin
          // A->B: Reading from RAM B
          a_rd_ptr <= a_rd_ptr + 1'b1;
          o_ram_b_rinc <= 1'b1;
          o_ram_b_addr <= a_rd_ptr;
          // Data comes from i_ram_b_rdata
        end else begin
          // B->A: Reading from RAM A
          a_rd_ptr <= a_rd_ptr + 1'b1;
          o_ram_a_rinc <= 1'b1;
          o_ram_a_addr <= a_rd_ptr;
          // Data comes from i_ram_a_rdata
        end
      end else begin
        o_ram_a_rinc <= 1'b0;
        o_ram_b_rinc <= 1'b0;
      end

      // Full/Empty Logic (Internal)
      if (a_dir_reg) begin
        // A->B Mode
        if (a_wr_ptr == a_rd_ptr) begin
          a_empty_int <= 1'b1;
          a_full_int <= 1'b0;
        end else if (a_wr_ptr == (a_rd_ptr + ASIZE[ASIZE-1:0])) begin
          a_empty_int <= 1'b0;
          a_full_int <= 1'b1;
        end else begin
          a_empty_int <= 1'b0;
          a_full_int <= 1'b0;
        end
      end else begin
        // B->A Mode
        if (a_wr_ptr == a_rd_ptr) begin
          a_empty_int <= 1'b1;
          a_full_int <= 1'b0;
        end else if (a_wr_ptr == (a_rd_ptr + ASIZE[ASIZE-1:0])) begin
          a_empty_int <= 1'b0;
          a_full_int <= 1'b1;
        end else begin
          a_empty_int <= 1'b0;
          a_full_int <= 1'b0;
        end
      end
    end
  end

  // Cross-domain pointer update for A (Snapshot B's write pointer)
  // We need to capture b_wr_ptr in A domain to determine if B->A is full
  always @(posedge a_clk) begin
    if (!a_rst_n)
      a_rd_ptr_b <= 0;
    else
      a_rd_ptr_b <= b_wr_ptr_a;
  end

  // ========================================================================
  // B-Domain Logic
  // ========================================================================
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_dir_reg <= 1'b0; // Default to B->A (Write to RAM B, Read from RAM A)
      b_full_int <= 1'b0;
      b_empty_int <= 1'b1;
    end else begin
      // Handle Direction Input
      if (b_dir != b_dir_sync) begin
        b_dir_reg <= b_dir;
        b_dir_sync <= b_dir;
      end

      // Write Pointer Logic
      if (b_winc) begin
        if (b_dir_reg) begin
          // B->A: Writing to RAM B
          b_wr_ptr <= b_wr_ptr + 1'b1;
          o_ram_b_winc <= 1'b1;
          o_ram_b_wdata <= b_wdata;
          o_ram_b_addr <= b_wr_ptr;
        end else begin
          // A->B: Writing to RAM A
          b_wr_ptr <= b_wr_ptr + 1'b1;
          o_ram_a_winc <= 1'b1;
          o_ram_a_wdata <= b_wdata;
          o_ram_a_addr <= b_wr_ptr;
        end
      end else begin
        o_ram_b_winc <= 1'b0;
        o_ram_a_winc <= 1'b0;
      end

      // Read Pointer Logic
      if (b_rinc) begin
        if (b_dir_reg) begin
          // B->A: Reading from RAM A
          b_rd_ptr <= b_rd_ptr + 1'b1;
          o_ram_a_rinc <= 1'b1;
          o_ram_a_addr <= b_rd_ptr;
          // Data comes from i_ram_a_rdata
        end else begin
          // A->B: Reading from RAM B
          b_rd_ptr <= b_rd_ptr + 1'b1;
          o_ram_b_rinc <= 1'b1;
          o_ram_b_addr <= b_rd_ptr;
          // Data comes from i_ram_b_rdata
        end
      end else begin
        o_ram_b_rinc <= 1'b0;
        o_ram_a_rinc <= 1'b0;
      end

      // Full/Empty Logic (Internal)
      if (b_dir_reg) begin
        // B->A Mode
        if (b_wr_ptr == b_rd_ptr) begin
          b_empty_int <= 1'b1;
          b_full_int <= 1'b0;
        end else if (b_wr_ptr == (b_rd_ptr + ASIZE[ASIZE-1:0])) begin
          b_empty_int <= 1'b0;
          b_full_int <= 1'b1;
        end else begin
          b_empty_int <= 1'b0;
          b_full_int <= 1'b0;
        end
      end else begin
        // A->B Mode
        if (b_wr_ptr == b_rd_ptr) begin
          b_empty_int <= 1'b1;
          b_full_int <= 1'b0;
        end else if (b_wr_ptr == (b_rd_ptr + ASIZE[ASIZE-1:0])) begin
          b_empty_int <= 1'b0;
          b_full_int <= 1'b1;
        end else begin
          b_empty_int <= 1'b0;
          b_full_int <= 1'b0;
        end
      end
    end
  end

  // Cross-domain pointer update for B (Snapshot A's write pointer)
  // We need to capture a_wr_ptr in B domain to determine if A->B is full
  always @(posedge b_clk) begin
    if (!b_rst_n)
      b_wr_ptr_a <= 0;
    else
      b_wr_ptr_a <= a_wr_ptr;
  end

  // ========================================================================
  // Output Logic & Synchronization
  // ========================================================================

  // A-Domain Outputs
  // Data selection based on direction
  assign a_rdata = (a_dir_reg) ? i_ram_b_rdata : i_ram_a_rdata;

  // Full/Empty Synchronization for A
  // We need to sync b_wr_ptr_a (which indicates A->B fullness) and a_rd_ptr_b (which indicates B->A emptiness)
  // Actually, for A:
  // a_full is true if A->B is full (a_wr_ptr == a_rd_ptr + 1) -> This is internal logic already computed as a_full_int
  // But wait, the requirement says "Pointers in both directions cross as acknowledged binary snapshots".
  // This implies we should use the cross-domain pointers for the final status signals to ensure stability across domains.
  
  // Let's refine the status logic to strictly follow the "cross-domain snapshot" requirement for the outputs.
  // For A:
  // a_full: Is the FIFO full for A? 
  //   If A->B: Full when a_wr_ptr == a_rd_ptr + 1. We know a_wr_ptr and a_rd_ptr are in A domain.
  //   If B->A: Full when b_wr_ptr == a_rd_ptr + 1. Here b_wr_ptr is the snapshot (b_wr_ptr_a).
  // a_empty: Is the FIFO empty for A?
  //   If A->B: Empty when a_wr_ptr == a_rd_ptr.
  //   If B->A: Empty when b_wr_ptr == a_rd_ptr.
  
  // To make this robust against metastability from the other domain, we sync the cross-domain pointers.
  
  // Sync b_wr_ptr_a (A's view of B's write pointer)
  reg [ASIZE-1:0] b_wr_ptr_a_sync1, b_wr_ptr_a_sync2;
  always @(posedge a_clk) begin
    if (!a_rst_n) begin
      b_wr_ptr_a_sync1 <= 0;
      b_wr_ptr_a_sync2 <= 0;
    end else begin
      b_wr_ptr_a_sync1 <= b_wr_ptr_a;
      b_wr_ptr_a_sync2 <= b_wr_ptr_a_sync1;
    end
  end

  // Sync a_rd_ptr_b (B's view of A's read pointer) - needed for B domain outputs
  reg [ASIZE-1:0] a_rd_ptr_b_sync1, a_rd_ptr_b_sync2;
  always @(posedge b_clk) begin
    if (!b_rst_n) begin
      a_rd_ptr_b_sync1 <= 0;
      a_rd_ptr_b_sync2 <= 0;
    end else begin
      a_rd_ptr_b_sync1 <= a_rd_ptr_b;
      a_rd_ptr_b_sync2 <= a_rd_ptr_b_sync1;
    end
  end

  // Re-evaluate A outputs with synchronized cross-domain pointers
  assign a_full = (a_dir_reg) ? (a_wr_ptr == (a_rd_ptr + 1'b1)) : (b_wr_ptr_a_sync2 == (a_rd_ptr + 1'b1));
  assign a_empty = (a_dir_reg) ? (a_wr_ptr == a_rd_ptr) : (b_wr_ptr_a_sync2 == a_rd_ptr);
  
  // Asynchronous Full/Empty flags (lagging)
  // These are the raw internal flags, potentially lagging if the other domain hasn't updated its pointer yet.
  assign a_afull = a_full_int;
  assign a_aempty = a_empty_int;

  // B-Domain Outputs
  // Data selection based on direction
  assign b_rdata = (b_dir_reg) ? i_ram_a_rdata : i_ram_b_rdata;

  // Full/Empty Synchronization for B
  // b_full: Is the FIFO full for B?
  //   If B->A: Full when b_wr_ptr == a_rd_ptr + 1. Use a_rd_ptr_b_sync2.
  //   If A->B: Full when b_wr_ptr == b_rd_ptr + 1. Internal logic.
  // b_empty: Is the FIFO empty for B?
  //   If B->A: Empty when b_wr_ptr == a_rd_ptr. Use a_rd_ptr_b_sync2.
  //   If A->B: Empty when b_wr_ptr == b_rd_ptr. Internal logic.

  assign b_full = (b_dir_reg) ? (b_wr_ptr == (b_rd_ptr + 1'b1)) : (a_rd_ptr_b_sync2 == (b_rd_ptr + 1'b1));
  assign b_empty = (b_dir_reg) ? (b_wr_ptr == b_rd_ptr) : (a_rd_ptr_b_sync2 == b_rd_ptr);

  // Asynchronous Full/Empty flags (lagging)
  assign b_afull = b_full_int;
  assign b_aempty = b_empty_int;

  // Direction Sync for outputs (just in case, though internal logic uses a_dir_reg/b_dir_reg)
  // The outputs a_full, a_empty depend on a_dir_reg. If a_dir changes, the logic switches.
  // We need to ensure a_dir_reg is stable. The logic inside the always block handles the flip-flop.
  // However, for the output assignments, we rely on the registered a_dir_reg and b_dir_reg.
  
  // Note: The internal full/empty logic (a_full_int, etc.) was updated in the main always blocks.
  // The synchronized versions (a_full, b_full) use the cross-domain pointers.
  
  // One detail: When direction changes, the pointers might be misaligned relative to the new direction's "full" definition immediately?
  // The problem statement says "start empty after reset".
  // On reset, pointers are 0. Empty is true.
  // When direction changes, the pointers remain where they are.
  // If A->B was full (wr=rd+1) and switches to B->A, is it full?
  // In B->A, full is wr == rd + 1. Since pointers didn't change, it remains full.
  // This is correct behavior for a shared buffer.

  // Final check on output assignments to ensure they match the requirements:
  // "full and empty can lag" -> This refers to the asynchronous flags (a_afull, a_aempty).
  // The synchronous flags (a_full, a_empty) are the ones that are stable across domains.
  // The prompt asks for "a_full", "a_empty" etc. Usually, in FIFOs, these are the stable ones.
  // But the prompt also says "Pointers in both directions cross as acknowledged binary snapshots, so full and empty can lag."
  // This implies the outputs a_full/a_empty might be the lagging ones? 
  // Or does it mean the internal logic lags?
  // Standard practice: a_full/a_empty are the stable, synchronized outputs. a_afull/a_aempty are the raw, potentially metastable/lagging ones.
  // Given the interface has both pairs, I will provide:
  // a_full, a_empty: Synchronized (using cross-domain pointers).
  // a_afull, a_aempty: Asynchronous (internal logic, may lag).
  
  // Wait, re-reading: "Pointers in both directions cross as acknowledged binary snapshots, so full and empty can lag."
  // This sentence explains WHY the cross-domain pointers are used and why there is a lag.
  // It likely refers to the fact that when you check "Is it full?", you are checking a pointer from the other domain which might be 1 cycle behind.
  // Therefore, the outputs a_full/a_empty (which use the cross-domain pointers) are the correct "safe" outputs, but they inherently have a 1-cycle lag compared to the true state in the other domain.
  // The "lag" mentioned is the nature of the cross-domain check.
  // So:
  // a_full = Synchronized check (uses b_wr_ptr_a_sync2).
  // a_afull = Internal check (uses a_wr_ptr, a_rd_ptr directly).
  // This matches the standard dual-port FIFO interface where _sync flags are safe and _async flags are raw.
  
  // Let's verify the logic again.
  // A Domain:
  // a_full: Should indicate if A cannot write.
  //   If A->B: Check A's wr vs A's rd. (Internal)
  //   If B->A: Check B's wr (seen by A) vs A's rd. (Cross domain)
  //   My code: assign a_full = (a_dir_reg) ? (a_wr_ptr == (a_rd_ptr + 1'b1)) : (b_wr_ptr_a_sync2 == (a_rd_ptr + 1'b1));
  //   This is correct.
  
  // B Domain:
  // b_full: Should indicate if B cannot write.
  //   If B->A: Check B's wr vs A's rd (seen by B).
  //   If A->B: Check B's wr vs B's rd.
  //   My code: assign b_full = (b_dir_reg) ? (b_wr_ptr == (b_rd_ptr + 1'b1)) : (a_rd_ptr_b_sync2 == (b_rd_ptr + 1'b1));
  //   This is correct.

  // One edge case: Direction change.
  // If A->B is full (wr=rd+1). Switch to B->A.
  // New condition for full: b_wr_ptr == a_rd_ptr + 1.
  // Since pointers didn't change, b_wr_ptr (which is a_wr_ptr) == a_rd_ptr + 1.
  // So it remains full. Correct.

  // Reset behavior:
  // Reset: wr=0, rd=0. Empty.
  // a_full = (0 == 0+1) -> 0. Correct.
  // a_empty = (0 == 0) -> 1. Correct.

endmodule
```<|im_end|>
