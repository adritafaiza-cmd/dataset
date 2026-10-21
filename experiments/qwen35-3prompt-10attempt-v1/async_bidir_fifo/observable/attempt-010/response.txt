```verilog
`timescale 1ns/1ps

module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
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
       input wire              b_dir
       );

  // Internal pointers: Write pointers (A side writes, B side reads)
  // Read pointers (B side writes, A side reads)
  // We use separate pointer sets for each direction to handle the bidirectional nature cleanly.
  // Direction A: A writes to A-side pointers, B reads from A-side pointers.
  // Direction B: B writes to B-side pointers, A reads from B-side pointers.
  
  // A-side pointers (Managed by A clock for write, B clock for read)
  reg [ASIZE-1:0] a_write_ptr;
  reg [ASIZE-1:0] a_read_ptr;
  
  // B-side pointers (Managed by B clock for write, A clock for read)
  reg [ASIZE-1:0] b_write_ptr;
  reg [ASIZE-1:0] b_read_ptr;

  // Write data registers (Double buffering for write side)
  // a_wdata_reg: Data written by A, available for B to read
  reg [DSIZE-1:0] a_wdata_reg;
  reg [DSIZE-1:0] a_wdata_reg2;
  
  // b_wdata_reg: Data written by B, available for A to read
  reg [DSIZE-1:0] b_wdata_reg;
  reg [DSIZE-1:0] b_wdata_reg2;

  // Write enable signals for the double buffers
  reg a_we;
  reg b_we;

  // Read enable signals for the double buffers
  reg a_re;
  reg b_re;

  // Status flags
  reg a_full, a_empty;
  reg b_full, b_empty;
  
  // Asynchronous status flags (one cycle lag)
  reg a_afull, a_aempty;
  reg b_afull, b_aempty;

  // Cross-domain pointers for status calculation
  // A side needs to know B's read pointer to determine full/empty
  wire [ASIZE-1:0] b_read_ptr_sync;
  wire [ASIZE-1:0] a_read_ptr_sync;
  
  // B side needs to know A's read pointer to determine full/empty
  wire [ASIZE-1:0] a_read_ptr_sync_b;
  wire [ASIZE-1:0] b_read_ptr_sync_a;

  // 1. Clock Domain Crossing: B's read pointer to A domain
  // Used by A to determine if FIFO is full/empty when A is reading (Direction B)
  wire [ASIZE-1:0] b_read_ptr_synced;
  wire [ASIZE-1:0] b_write_ptr_synced;
  
  // 2. Clock Domain Crossing: A's read pointer to B domain
  // Used by B to determine if FIFO is full/empty when B is writing (Direction A)
  wire [ASIZE-1:0] a_read_ptr_synced_b;
  wire [ASIZE-1:0] a_write_ptr_synced_b;

  // 3. Clock Domain Crossing: B's write pointer to A domain
  // Used by A to determine if FIFO is full/empty when A is writing (Direction A)
  wire [ASIZE-1:0] b_write_ptr_synced_a;
  wire [ASIZE-1:0] b_read_ptr_synced_a;

  // 4. Clock Domain Crossing: A's write pointer to B domain
  // Used by B to determine if FIFO is full/empty when B is reading (Direction B)
  wire [ASIZE-1:0] a_write_ptr_synced_a;
  wire [ASIZE-1:0] a_read_ptr_synced_a;

  // Generate Gray encoded pointers for CDC
  wire [ASIZE-1:0] a_write_ptr_gray;
  wire [ASIZE-1:0] a_read_ptr_gray;
  wire [ASIZE-1:0] b_write_ptr_gray;
  wire [ASIZE-1:0] b_read_ptr_gray;

  // Decode Gray back to binary in the destination domain
  wire [ASIZE-1:0] a_write_ptr_bin_sync;
  wire [ASIZE-1:0] a_read_ptr_bin_sync;
  wire [ASIZE-1:0] b_write_ptr_bin_sync;
  wire [ASIZE-1:0] b_read_ptr_bin_sync;

  // --- CDC Logic for A's pointers to B domain ---
  // A_write_ptr -> B domain (for B to check full/empty on A->B direction)
  assign a_write_ptr_gray = a_write_ptr ^ (a_write_ptr >> 1);
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_write_ptr_bin_sync <= {ASIZE{1'b0}};
    end else begin
      a_write_ptr_bin_sync <= a_write_ptr_gray;
    end
  end
  assign a_write_ptr_synced_a = a_write_ptr_bin_sync;

  // A_read_ptr -> B domain (for B to check full/empty on A->B direction)
  assign a_read_ptr_gray = a_read_ptr ^ (a_read_ptr >> 1);
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_read_ptr_bin_sync <= {ASIZE{1'b0}};
    end else begin
      a_read_ptr_bin_sync <= a_read_ptr_gray;
    end
  end
  assign a_read_ptr_synced_a = a_read_ptr_bin_sync;

  // --- CDC Logic for B's pointers to A domain ---
  // B_write_ptr -> A domain (for A to check full/empty on B->A direction)
  assign b_write_ptr_gray = b_write_ptr ^ (b_write_ptr >> 1);
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_write_ptr_bin_sync <= {ASIZE{1'b0}};
    end else begin
      b_write_ptr_bin_sync <= b_write_ptr_gray;
    end
  end
  assign b_write_ptr_synced_a = b_write_ptr_bin_sync;

  // B_read_ptr -> A domain (for A to check full/empty on B->A direction)
  assign b_read_ptr_gray = b_read_ptr ^ (b_read_ptr >> 1);
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_read_ptr_bin_sync <= {ASIZE{1'b0}};
    end else begin
      b_read_ptr_bin_sync <= b_read_ptr_gray;
    end
  end
  assign b_read_ptr_synced_a = b_read_ptr_bin_sync;

  // --- CDC Logic for A's pointers to B domain (Reversed for B's perspective) ---
  // Actually, we need B to see A's pointers to manage B->A direction correctly.
  // Wait, the logic above covers:
  // 1. A writes to A-side. B reads from A-side. B needs A's write ptr (to know full) and A's read ptr (to know empty).
  //    So A's pointers must cross to B. (Done above: a_write_ptr_synced_a, a_read_ptr_synced_a)
  
  // 2. B writes to B-side. A reads from B-side. A needs B's write ptr (to know full) and B's read ptr (to know empty).
  //    So B's pointers must cross to A. (Done above: b_write_ptr_synced_a, b_read_ptr_synced_a)

  // Let's re-verify the variable names and usage.
  // A Side Logic (Clock a_clk):
  // - Write: Uses a_winc. Updates a_write_ptr. Writes to a_wdata_reg.
  // - Read: Uses a_rinc. Reads from a_wdata_reg (if dir=A) or b_wdata_reg (if dir=B).
  // - Status: Checks a_write_ptr vs a_read_ptr (local). Checks crossed pointers for opposite direction.
  
  // B Side Logic (Clock b_clk):
  // - Write: Uses b_winc. Updates b_write_ptr. Writes to b_wdata_reg.
  // - Read: Uses b_rinc. Reads from b_wdata_reg (if dir=B) or a_wdata_reg (if dir=A).
  // - Status: Checks b_write_ptr vs b_read_ptr (local). Checks crossed pointers for opposite direction.

  // --- A Side Logic (Clock a_clk) ---
  
  // Write Enable for A
  assign a_we = a_winc;

  // Write Pointer Update (A domain)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_write_ptr <= {ASIZE{1'b0}};
    end else if (a_we) begin
      a_write_ptr <= a_write_ptr + 1;
    end
  end

  // Read Enable for A (Direction B)
  // A reads from B-side buffer when a_dir == 1 (assuming 0 is A->B, 1 is B->A? 
  // The prompt says "Move words in either direction, as selected on each side".
  // Usually a_dir=0 means A is sending to B, a_dir=1 means A is receiving from B.
  // Let's assume: a_dir=0 -> A writes, B reads. a_dir=1 -> B writes, A reads.
  // However, the prompt has separate a_dir and b_dir inputs.
  // "Move words in either direction, as selected on each side."
  // This implies independent direction control? Or coupled?
  // Standard bidir FIFO often has one direction signal or two.
  // Given "a_dir" and "b_dir", let's assume:
  // If a_dir == 0, A is the writer, B is the reader.
  // If a_dir == 1, A is the reader, B is the writer.
  // Similarly for b_dir. They should ideally be consistent.
  // If a_dir != b_dir, behavior is undefined or we prioritize one.
  // Let's assume standard: a_dir=0 (A->B), a_dir=1 (B->A).
  // A reads from B-side buffer when a_dir == 1.
  
  assign a_re = (a_dir == 1'b1) && a_rinc;

  // Read Pointer Update (A domain)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_read_ptr <= {ASIZE{1'b0}};
    end else if (a_re) begin
      a_read_ptr <= a_read_ptr + 1;
    end
  end

  // Write Data Register (A domain)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wdata_reg <= {DSIZE{1'b0}};
      a_wdata_reg2 <= {DSIZE{1'b0}};
    end else if (a_we) begin
      a_wdata_reg <= a_wdata;
      a_wdata_reg2 <= a_wdata_reg;
    end
  end

  // Read Data Register (A domain) - Reads from B-side buffer when a_dir=1
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata <= {DSIZE{1'b0}};
    end else if (a_re) begin
      // If a_dir is 1, read from b_wdata_reg. If 0, read from a_wdata_reg.
      // But wait, if a_dir is 0, A is writing. Does A read its own data? No.
      // If a_dir is 1, A is reading from B.
      if (a_dir == 1'b1)
        a_rdata <= b_wdata_reg;
      else
        a_rdata <= a_wdata_reg; // Fallback, though logically shouldn't happen if dir is respected
    end
  end

  // Status Logic (A domain)
  // Full: Write Ptr == Read Ptr (Empty) OR (Write Ptr + 1) == Read Ptr (Full)
  // We need to compare local pointers and crossed pointers.
  
  // Local Full/Empty for A->B direction
  // Full: a_write_ptr == a_read_ptr (if we consider the buffer full when pointers match? 
  // Standard: Full if (write_ptr + 1) == read_ptr. Empty if write_ptr == read_ptr.
  // But with pointers crossing, we use the crossed values for the opposite direction status.
  
  // A Full (A->B): A is full if A's write pointer is about to catch up to A's read pointer.
  // Actually, A_full indicates the FIFO is full for A's perspective (A->B).
  // A is full if a_write_ptr == a_read_ptr (assuming 1 entry buffer) or (a_write_ptr + 1) == a_read_ptr?
  // Let's use standard: Full if (write_ptr + 1) == read_ptr. Empty if write_ptr == read_ptr.
  // However, the prompt says "Pointers in both directions cross as acknowledged binary snapshots, so full and empty can lag."
  // This implies we calculate status based on the pointers available in the current domain.
  
  // A Full (A->B): A is full if A's write pointer is one ahead of A's read pointer.
  // But we must consider the B side's read pointer? No, A_full is about A's ability to write.
  // A cannot write if the FIFO is full. The FIFO is full if the number of items is max.
  // Max items = 2^ASIZE - 1.
  // Full condition: (a_write_ptr + 1) == a_read_ptr.
  // Empty condition: a_write_ptr == a_read_ptr.
  
  // However, the prompt mentions "Pointers in both directions cross...".
  // This usually means:
  // A_full is determined by comparing A's write pointer with A's read pointer.
  // A_empty is determined by comparing A's write pointer with A's read pointer.
  // BUT, the "lag" part suggests that when A reads (direction B), it uses B's pointers?
  // No, A reads from B's buffer. The status of that buffer (B->A direction) is determined by B's pointers.
  // So:
  // A_full (A->B): Compare a_write_ptr and a_read_ptr.
  // A_empty (A->B): Compare a_write_ptr and a_read_ptr.
  // A_full (B->A): Compare b_write_ptr and b_read_ptr (crossed to A).
  // A_empty (B->A): Compare b_write_ptr and b_read_ptr (crossed to A).
  
  // The prompt asks for "a_full", "a_empty". These are likely the status of the FIFO from A's perspective.
  // If A is writing (A->B), a_full/a_empty refer to A->B status.
  // If A is reading (B->A), a_full/a_empty refer to B->A status.
  // But typically, a_full means "FIFO is full", regardless of direction.
  // Let's assume:
  // a_full = (FIFO is full). FIFO is full if (a_write_ptr + 1) == a_read_ptr.
  // a_empty = (FIFO is empty). FIFO is empty if a_write_ptr == a_read_ptr.
  // This is consistent for both directions if we use the correct pointers.
  // When A is writing, it uses a_write_ptr and a_read_ptr.
  // When A is reading, it uses b_write_ptr and b_read_ptr (crossed).
  
  // Let's refine:
  // a_full: True if FIFO is full.
  // If A is writing (a_dir=0), check a_write_ptr vs a_read_ptr.
  // If A is reading (a_dir=1), check b_write_ptr vs b_read_ptr.
  // Similarly for a_empty.
  
  // Asynchronous Full/Empty (lagging by 1 cycle)
  // a_afull: True if FIFO was full one cycle ago (or will be full next cycle?).
  // Usually, afull is the status sampled one cycle ago.
  // a_aempty: True if FIFO was empty one cycle ago.
  
  // Implementation of Full/Empty logic in A domain:
  // We need to know which pointers to use based on a_dir.
  // However, a_dir changes. We can't switch logic dynamically easily without metastability.
  // Better approach: Always maintain both sets of status flags internally, but output the relevant one?
  // Or, since a_dir is an input, we can use it to select.
  // But a_dir is asynchronous to a_clk? No, it's an input.
  // Let's assume a_dir is stable enough or we sample it.
  // Actually, the standard way is:
  // a_full = (a_write_ptr + 1) == a_read_ptr. (Status of A->B buffer)
  // b_full = (b_write_ptr + 1) == b_read_ptr. (Status of B->A buffer)
  // But the FIFO is shared.
  // If A->B is full, the FIFO is full.
  // If B->A is full, the FIFO is full.
  // So a_full = (a_write_ptr + 1 == a_read_ptr) OR (b_write_ptr + 1 == b_read_ptr)?
  // No, that's not right. The pointers are independent for each direction.
  // Wait, a bidirectional FIFO usually has two independent FIFOs or one shared memory with two pointers?
  // "Move words in either direction". This implies a single FIFO structure.
  // If A writes, it adds to the tail. If B reads, it removes from the head.
  // If B writes, it adds to the tail. If A reads, it removes from the head.
  // This is a "ping-pong" or "dual-port" FIFO?
  // "Bidirectional asynchronous FIFO" typically means:
  // Direction A->B: A writes, B reads.
  // Direction B->A: B writes, A reads.
  // These are two separate logical FIFOs sharing the same physical memory?
  // Or is it a single FIFO where direction is determined by who is writing/reading?
  // If it's a single FIFO, then A writing and B writing simultaneously is impossible (collision).
  // The prompt says "Move words in either direction, as selected on each side."
  // This implies independent control.
  // Let's assume two independent FIFOs sharing the same depth, but logically separate.
  // A->B FIFO: A writes, B reads.
  // B->A FIFO: B writes, A reads.
  // They share the same physical storage? No, that would cause collisions.
  // Usually, a bidirectional FIFO has two separate FIFOs (one for each direction) or a dual-port RAM.
  // Given the interface has separate a_wdata, a_rdata, b_wdata, b_rdata, and separate pointers logic,
  // it's safer to implement two independent FIFOs (A->B and B->A) with the same depth.
  // But the prompt says "Preserve their order... start empty after reset".
  // If they are independent, they both start empty.
  // Let's assume two independent FIFOs.
  // A->B FIFO:
  //   Write: A (a_winc, a_wdata)
  //   Read: B (b_rinc, b_rdata)
  // B->A FIFO:
  //   Write: B (b_winc, b_wdata)
  //   Read: A (a_rinc, a_rdata)
  
  // Status:
  // a_full: Status of A->B FIFO (Full for A).
  // a_empty: Status of A->B FIFO (Empty for A).
  // b_full: Status of B->A FIFO (Full for B).
  // b_empty: Status of B->A FIFO (Empty for B).
  
  // Wait, the prompt asks for "a_full", "a_empty", "b_full", "b_empty".
  // And "a_afull", "a_aempty", "b_afull", "b_aempty".
  // This confirms two independent FIFOs.
  // A->B FIFO:
  //   Full: a_write_ptr == a_read_ptr (assuming 1-entry buffer) or (a_write_ptr + 1) == a_read_ptr?
  //   Standard: Full if (write_ptr + 1) == read_ptr. Empty if write_ptr == read_ptr.
  //   But with pointers crossing, we use the crossed pointers for the opposite side's status.
  //   A->B Full: (a_write_ptr + 1) == a_read_ptr.
  //   A->B Empty: a_write_ptr == a_read_ptr.
  //   B sees A->B status via crossed pointers.
  
  // B->A FIFO:
  //   Full: (b_write_ptr + 1) == b_read_ptr.
  //   Empty: b_write_ptr == b_read_ptr.
  //   A sees B->A status via crossed pointers.
  
  // Let's re-read carefully: "Pointers in both directions cross as acknowledged binary snapshots, so full and empty can lag."
  // This implies:
  // A_full is calculated using A's pointers (local).
  // B_full is calculated using B's pointers (local).
  // But B needs to know if A->B is full to stop writing? No, B reads. B stops reading if empty.
  // B needs to know if A->B is empty to stop reading.
  // B needs to know if A->B is full? No, B is the reader. B doesn't care if it's full.
  // A needs to know if A->B is full to stop writing.
  // A needs to know if A->B is empty? No, A is the writer.
  // So:
  // A needs: A->B Full (to stop writing).
  // B needs: A->B Empty (to stop reading).
  // B needs: B->A Full (to stop writing).
  // A needs: B->A Empty (to stop reading).
  
  // The outputs a_full, a_empty are for A's use.
  // a_full: A->B Full.
  // a_empty: A->B Empty.
  // b_full: B->A Full.
  // b_empty: B->A Empty.
  
  // But wait, the prompt says "a_full", "a_empty".
  // If A is reading (B->A), does a_full mean "B->A is full"?
  // Usually, a_full means "The FIFO is full from A's perspective".
  // If A is reading, A cares about B->A being empty.
  // If A is writing, A cares about A->B being full.
  // But the output signals are static.
  // Let's assume:
  // a_full = (A->B is full).
  // a_empty = (A->B is empty).
  // b_full = (B->A is full).
  // b_empty = (B->A is empty).
  
  // This makes sense. A uses a_full to stop writing to A->B.
  // B uses a_empty to stop reading from A->B.
  // B uses b_full to stop writing to B->A.
  // A uses b_empty to stop reading from B->A.
  
  // Now, the "lag" part.
  // "Pointers in both directions cross as acknowledged binary snapshots".
  // This means when A calculates a_full/a_empty, it uses its own pointers (local).
  // When B calculates b_full/b_empty, it uses its own pointers (local).
  // BUT, B needs to know if A->B is empty. B uses a_read_ptr (crossed to B) and a_write_ptr (crossed to B).
  // A needs to know if B->A is full. A uses b_read_ptr (crossed to A) and b_write_ptr (crossed to A).
  
  // So:
  // a_full = (a_write_ptr + 1) == a_read_ptr.
  // a_empty = a_write_ptr == a_read_ptr.
  // b_full = (b_write_ptr + 1) == b_read_ptr.
  // b_empty = b_write_ptr == b_read_ptr.
  
  // Asynchronous versions (lagging):
  // a_afull: Sample a_full one cycle ago (or next cycle?).
  // Usually, afull is the status of the FIFO as seen by the reader, but with a lag.
  // If A is writing, A needs to know if it's full NOW.
  // If B is reading, B needs to know if it's empty NOW.
  // The "lag" usually refers to the fact that the reader sees the status one cycle late.
  // So a_afull is the value of a_full from the previous cycle?
  // Or is it the value that the reader sees?
  // "Empty may be high for one local clock after an accepted read even when another word is stored."
  // This describes the lag.
  // So a_aempty is the status of a_empty from the previous cycle?
  // Let's implement:
  // a_afull = a_full (from previous cycle).
  // a_aempty = a_empty (from previous cycle).
  // Same for B.
  
  // Wait, the prompt says "Pointers in both directions cross as acknowledged binary snapshots".
  // This implies the crossed pointers are used for the status calculation of the opposite direction.
  // But the outputs a_full, a_empty are for A.
  // If A is writing, it uses local pointers.
  // If A is reading, it uses crossed pointers?
  // No, a_full/a_empty are specific to the A->B direction.
  // a_full: A->B Full.
  // a_empty: A->B Empty.
  // These are calculated using A's pointers (local) because A controls the write pointer and B controls the read pointer.
  // A knows its write pointer. A knows its read pointer (crossed from B).
  // So a_full = (a_write_ptr + 1) == a_read_ptr (crossed).
  // a_empty = a_write_ptr == a_read_ptr (crossed).
  
  // Similarly for B:
  // b_full = (b_write_ptr + 1) == b_read_ptr (crossed).
  // b_empty = b_write_ptr == b_read_ptr (crossed).
  
  // This makes sense. A needs to know if A->B is full. A knows a_write_ptr (local). A needs a_read_ptr (from B).
  // B needs to know if B->A is full. B knows b_write_ptr (local). B needs b_read_ptr (from A).
  
  // So we need:
  // 1. A's pointers crossed to B (for B to calculate a_full/a_empty).
  // 2. B's pointers crossed to A (for A to calculate b_full/b_empty).
  
  // Let's re-evaluate the "lag".
  // "Empty may be high for one local clock after an accepted read even when another word is stored."
  // This happens because the read pointer update is asynchronous.
  // When B reads, b_read_ptr increments. A sees this via crossed pointer.
  // A's a_empty calculation uses b_read_ptr.
  // If B reads, b_read_ptr increments. A sees the new value one cycle later.
  // So A thinks it's still empty for one cycle.
  // This matches the description.
  
  // So the logic is:
  // a_full = (a_write_ptr + 1) == a_read_ptr (crossed from B).
  // a_empty = a_write_ptr == a_read_ptr (crossed from B).
  // b_full = (b_write_ptr + 1) == b_read_ptr (crossed from A).
  // b_empty = b_write_ptr == b_read_ptr (crossed from A).
  
  // Asynchronous versions:
  // a_afull = a_full (from previous cycle).
  // a_aempty = a_empty (from previous cycle).
  // b_afull = b_full (from previous cycle).
  // b_aempty = b_empty (from previous cycle).
  
  // Wait, the prompt says "Pointers in both directions cross as acknowledged binary snapshots".
  // This confirms we use crossed pointers for status.
  
  // Let's implement the CDC for pointers again.
  // A->B direction:
  //   A writes (a_write_ptr). B reads (a_read_ptr).
  //   A needs a_read_ptr (crossed from B).
  //   B needs a_write_ptr (crossed from A).
  
  // B->A direction:
  //   B writes (b_write_ptr). A reads (b_read_ptr).
  //   B needs b_read_ptr (crossed from A).
  //   A needs b_write_ptr (crossed from B).
  
  // So we need 4 CDC paths:
  // 1. a_write_ptr -> B (for B to calculate a_full/a_empty)
  // 2. a_read_ptr -> B (for B to calculate a_full/a_empty)
  // 3. b_write_ptr -> A (for A to calculate b_full/b_empty)
  // 4. b_read_ptr -> A (for A to calculate b_full/b_empty)
  
  // Wait, earlier I said:
  // a_full = (a_write_ptr + 1) == a_read_ptr (crossed from B).
  // This requires a_read_ptr crossed to A.
  // b_full = (b_write_ptr + 1) == b_read_ptr (crossed from A).
  // This requires b_read_ptr crossed to B.
  
  // Let's clarify:
  // A->B FIFO:
  //   Write: A (a_write_ptr). Read: B (a_read_ptr).
  //   A needs to know if full: (a_write_ptr + 1) == a_read_ptr.
  //     A has a_write_ptr. Needs a_read_ptr (crossed from B).
  //   B needs to know if empty: a_write_ptr == a_read_ptr.
  //     B has a_read_ptr. Needs a_write_ptr (crossed from A).
  
  // B->A FIFO:
  //   Write: B (b_write_ptr). Read: A (b_read_ptr).
  //   B needs to know if full: (b_write_ptr + 1) == b_read_ptr.
  //     B has b_write_ptr. Needs b_read_ptr (crossed from A).
  //   A needs to know if empty: b_write_ptr == b_read_ptr.
  //     A has b_read_ptr. Needs b_write_ptr (crossed from B).
  
  // So we need:
  // 1. a_write_ptr -> B (for B to check A->B empty)
  // 2. a_read_ptr -> A (for A to check A->B full)
  // 3. b_write_ptr -> A (for A to check B->A empty)
  // 4. b_read_ptr -> B (for B to check B->A full)
  
  // Wait, the outputs are:
  // a_full, a_empty (for A).
  // b_full, b_empty (for B).
  
  // a_full: A->B Full. A needs a_read_ptr (crossed from B).
  // a_empty: A->B Empty. A needs a_read_ptr (crossed from B).
  // b_full: B->A Full. B needs b_read_ptr (crossed from A).
  // b_empty: B->A Empty. B needs b_write_ptr (crossed from A).
  
  // So we need:
  // 1. a_read_ptr -> B (for B to check A->B full/empty? No, B checks A->B empty using a_write_ptr).
  //    Actually, B doesn't need a_read_ptr for A->B status. B only needs a_write_ptr to check if A->B is empty.
  //    But A needs a_read_ptr to check if A->B is full.
  //    So a_read_ptr must cross to A? No, a_read_ptr is in B domain. A needs it. So a_read_ptr -> A.
  //    a_write_ptr is in A domain. B needs it. So a_write_ptr -> B.
  
  // 2. b_read_ptr -> B (for B to check B->A full).
  //    b_write_ptr -> A (for A to check B->A empty).
  
  // So the CDC paths are:
  // 1. a_read_ptr (B domain) -> A domain.
  // 2. a_write_ptr (A domain) -> B domain.
  // 3. b_read_ptr (A domain) -> B domain.
  // 4. b_write_ptr (B domain) -> A domain.
  
  // Let's implement these.
  
  // --- CDC: a_read_ptr (B) -> A ---
  wire [ASIZE-1:0] a_read_ptr_crossed;
  assign a_read_ptr_gray = a_read_ptr ^ (a_read_ptr >> 1);
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_read_ptr_crossed <= {ASIZE{1'b0}};
    end else begin
      a_read_ptr_crossed <= a_read_ptr_gray;
    end
  end
  
  // --- CDC: a_write_ptr (A) -> B ---
  wire [ASIZE-1:0] a_write_ptr_crossed;
  assign a_write_ptr_gray = a_write_ptr ^ (a_write_ptr >> 1);
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_write_ptr_crossed <= {ASIZE{1'b0}};
    end else begin
      a_write_ptr_crossed <= a_write_ptr_gray;
    end
  end
  
  // --- CDC: b_read_ptr (A) -> B ---
  wire [ASIZE-1:0] b_read_ptr_crossed;
  assign b_read_ptr_gray = b_read_ptr ^ (b_read_ptr >> 1);
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_read_ptr_crossed <= {ASIZE{1'b0}};
    end else begin
      b_read_ptr_crossed <= b_read_ptr_gray;
    end
  end
  
  // --- CDC: b_write_ptr (B) -> A ---
  wire [ASIZE-1:0] b_write_ptr_crossed;
  assign b_write_ptr_gray = b_write_ptr ^ (b