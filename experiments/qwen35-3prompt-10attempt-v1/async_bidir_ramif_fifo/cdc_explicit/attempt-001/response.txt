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

  localparam LOG2_ASIZE = ASIZE;
  localparam NUM_ENTRIES = 1 << ASIZE;

  // --- Internal State Registers (Clock Domain A) ---
  // Pointers and status for Domain A
  reg [ASIZE-1:0] a_write_ptr;
  reg [ASIZE-1:0] a_read_ptr;
  reg [ASIZE-1:0] a_write_ptr_next;
  reg [ASIZE-1:0] a_read_ptr_next;
  reg [ASIZE-1:0] a_write_ptr_prev;
  reg [ASIZE-1:0] a_read_ptr_prev;
  reg [ASIZE-1:0] a_write_ptr_snapshot;
  reg [ASIZE-1:0] a_read_ptr_snapshot;
  reg a_full_reg;
  reg a_empty_reg;
  reg a_full_sync;
  reg a_empty_sync;

  // --- Internal State Registers (Clock Domain B) ---
  // Pointers and status for Domain B
  reg [ASIZE-1:0] b_write_ptr;
  reg [ASIZE-1:0] b_read_ptr;
  reg [ASIZE-1:0] b_write_ptr_next;
  reg [ASIZE-1:0] b_read_ptr_next;
  reg [ASIZE-1:0] b_write_ptr_prev;
  reg [ASIZE-1:0] b_read_ptr_prev;
  reg [ASIZE-1:0] b_write_ptr_snapshot;
  reg [ASIZE-1:0] b_read_ptr_snapshot;
  reg b_full_reg;
  reg b_empty_reg;
  reg b_full_sync;
  reg b_empty_sync;

  // --- CDC Signals (Crossing A -> B) ---
  // Write pointers and full status from A to B
  reg [ASIZE-1:0] a_ptr_to_b;
  reg a_full_to_b;
  reg a_empty_to_b;

  // --- CDC Signals (Crossing B -> A) ---
  // Write pointers and full status from B to A
  reg [ASIZE-1:0] b_ptr_to_a;
  reg b_full_to_a;
  reg b_empty_to_a;

  // --- RAM Control Signals ---
  // These are generated locally and driven to the external RAM interface
  // They do not cross clock domains; they are driven by the local clock.
  wire [ASIZE-1:0] ram_a_addr;
  wire [ASIZE-1:0] ram_b_addr;
  wire [DSIZE-1:0] ram_a_wdata;
  wire [DSIZE-1:0] ram_b_wdata;
  wire ram_a_winc;
  wire ram_b_winc;
  wire ram_a_rinc;
  wire ram_b_rinc;

  // --- Clock Generation for External RAM ---
  // The external RAM is assumed to be a dual-port device or two single-port devices.
  // We drive the clocks based on the direction of operation.
  // If A is writing, we drive A's clock. If B is writing, we drive B's clock.
  // This ensures the external RAM sees a valid clock edge when data is valid.
  assign o_ram_a_clk = a_dir ? a_clk : 1'b0;
  assign o_ram_b_clk = b_dir ? b_clk : 1'b0;

  // --- Logic for Domain A ---

  // 1. Pointer Updates (Local Logic)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_write_ptr <= '0;
      a_read_ptr  <= '0;
      a_write_ptr_next <= '0;
      a_read_ptr_next <= '0;
      a_write_ptr_prev <= '0;
      a_read_ptr_prev <= '0;
      a_write_ptr_snapshot <= '0;
      a_read_ptr_snapshot <= '0;
      a_full_reg <= 1'b0;
      a_empty_reg <= 1'b0;
    end else begin
      // Write Pointer Logic
      if (a_winc) begin
        a_write_ptr_next = a_write_ptr + 1'b1;
        if (a_write_ptr_next == '0) begin
          // Wrap around
          a_write_ptr_next = '0;
        end
      end else begin
        a_write_ptr_next = a_write_ptr;
      end

      // Read Pointer Logic
      if (a_rinc) begin
        a_read_ptr_next = a_read_ptr + 1'b1;
        if (a_read_ptr_next == '0) begin
          a_read_ptr_next = '0;
        end
      end else begin
        a_read_ptr_next = a_read_ptr;
      end

      // Update Previous Pointers (for snapshot comparison)
      a_write_ptr_prev = a_write_ptr;
      a_read_ptr_prev = a_read_ptr;

      // Update Snapshots (for CDC to B)
      a_write_ptr_snapshot = a_write_ptr;
      a_read_ptr_snapshot = a_read_ptr;

      // Full/Empty Logic (Local)
      if (FALLTHROUGH) begin
        a_full_reg = (a_write_ptr == a_read_ptr) && (a_write_ptr_next == a_read_ptr_next);
        a_empty_reg = (a_write_ptr == a_read_ptr) && (a_write_ptr_next != a_read_ptr_next);
      end else begin
        a_full_reg = (a_write_ptr == a_read_ptr) && (a_write_ptr_next == a_read_ptr_next);
        a_empty_reg = (a_write_ptr == a_read_ptr) && (a_write_ptr_next != a_read_ptr_next);
      end
    end
  end

  // 2. Data Readout (Local)
  // Read data comes from the external RAM input.
  // We select the correct data based on the read pointer.
  // Since we cannot infer internal memory, we assume the external RAM provides the data
  // at the address specified by o_ram_a_addr.
  // However, the prompt says "Read data returns on i_ram_*_rdata".
  // In a true external RAM interface, the read data is available immediately after the read enable/address setup.
  // We simply route the read data from the external port to the output.
  // Note: In a real system, the external RAM must be clocked correctly.
  // Here, we assume the external RAM is a dual-port device where Port A reads when o_ram_a_rinc is high.
  
  // To make this functional without an internal memory, we assume the external RAM is a dual-port block
  // that we are controlling. The read data is available on i_ram_a_rdata when o_ram_a_rinc is asserted.
  // We need to latch this data in Domain A to output it on a_rdata.
  
  reg [DSIZE-1:0] a_rdata_reg;
  reg a_rdata_valid;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= '0;
      a_rdata_valid <= 1'b0;
    end else begin
      if (a_rinc) begin
        // We assert the read enable on the external RAM interface
        o_ram_a_rinc = 1'b1;
        // Capture the data coming back from the external RAM
        a_rdata_reg <= i_ram_a_rdata;
        a_rdata_valid <= 1'b1;
      end else begin
        o_ram_a_rinc = 1'b0;
        if (a_rdata_valid) begin
          a_rdata_reg <= a_rdata_reg;
          a_rdata_valid <= 1'b1;
        end else begin
          a_rdata_valid <= 1'b0;
        end
      end
    end
  end

  // Output Data
  assign a_rdata = a_rdata_valid ? a_rdata_reg : '0;

  // 3. Write Data and Address Generation (Local)
  // When writing, we drive the external RAM write interface.
  // Address is the current write pointer.
  // Data is the incoming write data.
  
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      ram_a_addr <= '0;
      ram_a_wdata <= '0;
      ram_a_winc <= 1'b0;
    end else begin
      if (a_winc) begin
        ram_a_addr <= a_write_ptr;
        ram_a_wdata <= a_wdata;
        ram_a_winc <= 1'b1;
      end else begin
        ram_a_winc <= 1'b0;
      end
    end
  end

  // 4. CDC: Send Pointers and Status to Domain B
  // We use a 2-cycle handshake or simple snapshot transfer.
  // Given the requirement for safety, we transfer the snapshot of the pointers and status.
  // We will use a simple register to hold the value to be sent, updated on the clock edge.
  // To ensure stability, we can use a 2-stage pipeline or just a single register if the consumer is careful.
  // Standard practice: Update the CDC register on the clock edge, but ensure the consumer samples it.
  // Since this is a FIFO, the pointers change on write/read.
  // We will update the CDC registers on the clock edge.
  
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_ptr_to_b <= '0;
      a_full_to_b <= 1'b0;
      a_empty_to_b <= 1'b0;
    end else begin
      a_ptr_to_b <= a_write_ptr_snapshot;
      a_full_to_b <= a_full_reg;
      a_empty_to_b <= a_empty_reg;
    end
  end

  // --- Logic for Domain B ---

  // 1. Pointer Updates (Local Logic)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_write_ptr <= '0;
      b_read_ptr  <= '0;
      b_write_ptr_next <= '0;
      b_read_ptr_next <= '0;
      b_write_ptr_prev <= '0;
      b_read_ptr_prev <= '0;
      b_write_ptr_snapshot <= '0;
      b_read_ptr_snapshot <= '0;
      b_full_reg <= 1'b0;
      b_empty_reg <= 1'b0;
    end else begin
      // Write Pointer Logic
      if (b_winc) begin
        b_write_ptr_next = b_write_ptr + 1'b1;
        if (b_write_ptr_next == '0) begin
          b_write_ptr_next = '0;
        end
      end else begin
        b_write_ptr_next = b_write_ptr;
      end

      // Read Pointer Logic
      if (b_rinc) begin
        b_read_ptr_next = b_read_ptr + 1'b1;
        if (b_read_ptr_next == '0) begin
          b_read_ptr_next = '0;
        end
      end else begin
        b_read_ptr_next = b_read_ptr;
      end

      // Update Previous Pointers
      b_write_ptr_prev = b_write_ptr;
      b_read_ptr_prev = b_read_ptr;

      // Update Snapshots
      b_write_ptr_snapshot = b_write_ptr;
      b_read_ptr_snapshot = b_read_ptr;

      // Full/Empty Logic
      if (FALLTHROUGH) begin
        b_full_reg = (b_write_ptr == b_read_ptr) && (b_write_ptr_next == b_read_ptr_next);
        b_empty_reg = (b_write_ptr == b_read_ptr) && (b_write_ptr_next != b_read_ptr_next);
      end else begin
        b_full_reg = (b_write_ptr == b_read_ptr) && (b_write_ptr_next == b_read_ptr_next);
        b_empty_reg = (b_write_ptr == b_read_ptr) && (b_write_ptr_next != b_read_ptr_next);
      end
    end
  end

  // 2. Data Readout (Local)
  reg [DSIZE-1:0] b_rdata_reg;
  reg b_rdata_valid;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= '0;
      b_rdata_valid <= 1'b0;
    end else begin
      if (b_rinc) begin
        o_ram_b_rinc = 1'b1;
        b_rdata_reg <= i_ram_b_rdata;
        b_rdata_valid <= 1'b1;
      end else begin
        o_ram_b_rinc = 1'b0;
        if (b_rdata_valid) begin
          b_rdata_reg <= b_rdata_reg;
          b_rdata_valid <= 1'b1;
        end else begin
          b_rdata_valid <= 1'b0;
        end
      end
    end
  end

  assign b_rdata = b_rdata_valid ? b_rdata_reg : '0;

  // 3. Write Data and Address Generation (Local)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      ram_b_addr <= '0;
      ram_b_wdata <= '0;
      ram_b_winc <= 1'b0;
    end else begin
      if (b_winc) begin
        ram_b_addr <= b_write_ptr;
        ram_b_wdata <= b_wdata;
        ram_b_winc <= 1'b1;
      end else begin
        ram_b_winc <= 1'b0;
      end
    end
  end

  // 4. CDC: Send Pointers and Status to Domain A
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_ptr_to_a <= '0;
      b_full_to_a <= 1'b0;
      b_empty_to_a <= 1'b0;
    end else begin
      b_ptr_to_a <= b_write_ptr_snapshot;
      b_full_to_a <= b_full_reg;
      b_empty_to_a <= b_empty_reg;
    end
  end

  // --- CDC: Cross Clock Domain Status and Pointer Handling ---
  // We need to synchronize the pointers and status flags from the other domain to make decisions.
  // However, the problem statement says "Pointers in both directions cross as acknowledged binary snapshots".
  // This implies we don't necessarily need a complex handshake for the pointers themselves if the logic
  // is designed to handle the lag, but we DO need to synchronize the status flags (full/empty)
  // to prevent metastability in the decision logic.
  
  // Synchronize Full/Empty flags from B to A
  reg a_full_synced;
  reg a_empty_synced;
  reg [1:0] a_full_cnt;
  reg [1:0] a_empty_cnt;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_full_synced <= 1'b0;
      a_empty_synced <= 1'b0;
      a_full_cnt <= 2'b00;
      a_empty_cnt <= 2'b00;
    end else begin
      a_full_cnt <= a_full_cnt + 1'b1;
      a_empty_cnt <= a_empty_cnt + 1'b1;
      
      if (a_full_cnt[1]) begin
        a_full_synced <= a_full_to_b;
        a_full_cnt <= 2'b00;
      end
      if (a_empty_cnt[1]) begin
        a_empty_synced <= a_empty_to_b;
        a_empty_cnt <= 2'b00;
      end
    end
  end

  // Synchronize Full/Empty flags from A to B
  reg b_full_synced;
  reg b_empty_synced;
  reg [1:0] b_full_cnt;
  reg [1:0] b_empty_cnt;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_full_synced <= 1'b0;
      b_empty_synced <= 1'b0;
      b_full_cnt <= 2'b00;
      b_empty_cnt <= 2'b00;
    end else begin
      b_full_cnt <= b_full_cnt + 1'b1;
      b_empty_cnt <= b_empty_cnt + 1'b1;
      
      if (b_full_cnt[1]) begin
        b_full_synced <= a_full_to_b;
        b_full_cnt <= 2'b00;
      end
      if (b_empty_cnt[1]) begin
        b_empty_synced <= a_empty_to_b;
        b_empty_cnt <= 2'b00;
      end
    end
  end

  // --- Output Logic ---
  // The outputs a_full, a_empty, etc., should reflect the synchronized status from the OTHER domain
  // because the "true" status of the FIFO as seen by the writer in domain A depends on the reader in domain B.
  // Wait, the standard async FIFO behavior:
  // - a_full is generated in Domain A based on A's pointers. It indicates "I cannot write anymore".
  // - a_empty is generated in Domain A based on A's pointers. It indicates "There is data for me".
  // BUT, in a bidirectional FIFO, the "Full" status for A is determined by whether B has consumed data.
  // Actually, the pointers are local. The "Full" flag is a local calculation of (write_ptr == read_ptr).
  // The issue is that the read_ptr in A is updated by A's own read requests.
  // The write_ptr in A is updated by A's own write requests.
  // The "Full" flag in A tells A if it can write. This depends on how much B has read.
  // B's read pointer is local to B. A does not know B's read pointer directly.
  // A must rely on the synchronized status from B to know if the FIFO is truly full/empty relative to the global state.
  
  // Re-evaluating the "Bidirectional" nature:
  // In a standard unidirectional FIFO:
  //   a_full = (a_write_ptr == a_read_ptr) && (a_write_ptr_next == a_read_ptr_next)
  //   a_empty = (a_write_ptr == a_read_ptr) && (a_write_ptr_next != a_read_ptr_next)
  // These are purely local calculations. They are safe.
  
  // In a bidirectional FIFO:
  // Side A can write to the FIFO. Side B can also write to the FIFO (into the same memory space? Or separate?).
  // The prompt implies a single FIFO shared by both sides.
  // "Same bidirectional FIFO rules as a two-port async FIFO".
  // In a two-port async FIFO, there are two independent FIFOs or one shared memory with two ports?
  // Usually, a "bidirectional FIFO" in this context means a single FIFO where both sides can read and write.
  // However, the pointers are local.
  // If A writes, it increments a_write_ptr. If B writes, it increments b_write_ptr.
  // If A reads, it increments a_read_ptr. If B reads, it increments b_read_ptr.
  // The "Full" condition for A is: Can A write? A can write if the FIFO is not full.
  // The FIFO is full if (Total Writes) == (Total Reads).
  // Total Writes = a_write_ptr + b_write_ptr (modulo arithmetic is tricky here).
  // Actually, the standard implementation for a shared FIFO with two ports is to have a single global pointer set?
  // No, that requires a central arbiter.
  // The prompt says "Pointers in both directions cross as acknowledged binary snapshots".
  // This suggests we treat the pointers as independent counters that wrap around, and we use the snapshots to detect collisions.
  
  // Let's assume the standard "Two-Port Async FIFO" architecture where:
  // - There is a single physical memory (external RAM).
  // - Side A has a write pointer (a_wp) and read pointer (a_rp).
  // - Side B has a write pointer (b_wp) and read pointer (b_rp).
  // - The "Full" flag for A is true if A cannot write. This happens if the FIFO is full.
  // - The "Empty" flag for A is true if A cannot read. This happens if the FIFO is empty.
  // - The "Full" flag for B is true if B cannot write.
  // - The "Empty" flag for B is true if B cannot read.
  
  // How do we calculate Full/Empty?
  // If we assume the FIFO is circular and shared:
  // The total number of items = (a_wp - a_rp) + (b_wp - b_rp) ??? No, this is complex.
  
  // Alternative Interpretation:
  // Perhaps "Bidirectional" here means A can read/write, and B can read/write, but they operate on the SAME FIFO.
  // In this case, the "Full" status for A is determined by the global occupancy.
  // Global Occupancy = (a_wp - a_rp) + (b_wp - b_rp) is not straightforward with circular buffers.
  
  // Let's look at the "Two-Port Async FIFO" standard (e.g., Xilinx FIFO).
  // They usually have separate FIFOs for each direction (Write FIFO and Read FIFO) or a single FIFO with a single writer and single reader.
  // If it's a single FIFO with two writers and two readers, it's a "Multi-Port FIFO".
  // The prompt says "Same bidirectional FIFO rules as a two-port async FIFO".
  // A "two-port async FIFO" typically has one writer (Port A) and one reader (Port B).
  // But here we have a_dir and b_dir. This implies A can be a reader or writer, and B can be a reader or writer.
  // This is a "Dual-Port Async FIFO" where both ports can be configured as Read or Write.
  
  // Implementation Strategy for Dual-Port Async FIFO:
  // 1. Maintain local pointers for each side.
  // 2. The "Full" flag for a side is determined by comparing its write pointer with the OTHER side's read pointer.
  //    Why? Because the data written by A is consumed by B (or vice versa).
  //    If A writes, it expects B to read. If B doesn't read, A fills up.
  //    So, a_full is true when a_write_ptr == b_read_ptr (and next pointers match).
  //    Similarly, a_empty is true when a_write_ptr == b_read_ptr (and next pointers differ).
  //    Wait, if A writes and B reads, they are moving towards each other.
  //    The "Full" condition for A is when A's write pointer catches up to B's read pointer.
  //    The "Empty" condition for A is when A's write pointer is ahead of B's read pointer? No.
  
  // Let's refine the logic:
  // The FIFO is a shared resource.
  // A writes data. B reads data.
  // A reads data. B writes data.
  // The "Full" flag for A indicates "I cannot write more". This is true if the FIFO is full.
  // The FIFO is full if the number of items written by (A or B) equals the number of items read by (A or B).
  // This is hard to track with independent pointers without a global counter.
  
  // HOWEVER, the prompt says: "Pointers in both directions cross as acknowledged binary snapshots".
  // This phrasing is specific. It suggests that the pointers are exchanged to determine the state.
  // In a standard dual-port FIFO (one writer, one reader), the writer checks the reader's pointer.
  // Here, we have two potential writers and two potential readers.
  // If A is writing, it should check if the FIFO is full. The FIFO is full if B has not read enough.
  // Specifically, a_full = (a_write_ptr == b_read_ptr) && (a_write_ptr_next == b_read_ptr_next).
  // a_empty = (a_write_ptr == b_read_ptr) && (a_write_ptr_next != b_read_ptr_next).
  // This logic assumes that the "active" flow is A->B.
  // What if the flow is B->A? Then a_full would be determined by B's write pointer and A's read pointer?
  // No, the FIFO is a single buffer.
  // If A writes and B reads, the buffer fills from A's perspective as B's read pointer stays behind A's write pointer.
  // If B writes and A reads, the buffer fills from B's perspective as A's read pointer stays behind B's write pointer.
  // But what if A writes and B writes? They are writing to the same buffer. This is a race condition unless arbitrated.
  // The prompt does not mention arbitration. It says "Same bidirectional FIFO rules as a two-port async FIFO".
  // A two-port async FIFO has ONE writer and ONE reader.
  // The "bidirectional" part likely means the DATA FLOW can be A->B or B->A, controlled by a_dir and b_dir.
  // It does NOT mean both can write simultaneously to the same location.
  // So, if a_dir == 1 (A is writer), then b_dir must be 0 (B is reader).
  // If b_dir == 1 (B is writer), then a_dir must be 0 (A is reader).
  // The ports a_winc and b_winc are inputs, but the actual write enable to the FIFO is controlled by the direction.
  // If a_dir is high, A writes. If b_dir is high, B writes.
  // If both are high, it's undefined behavior or a conflict. We assume they are mutually exclusive or the external logic handles it.
  // Given the "bidirectional" nature, we assume:
  // - If a_dir == 1: A is Writer, B is Reader.
  // - If b_dir == 1: B is Writer, A is Reader.
  // - If both 0: No operation (or idle).
  // - If both 1: Conflict (we will assume no write happens or priority is given, but typically this is avoided).
  // Let's assume the direction signals dictate the role.
  
  // Revised Logic:
  // Case 1: a_dir = 1, b_dir = 0.
  //   A writes, B reads.
  //   a_full = (a_write_ptr == b_read_ptr) && (a_write_ptr_next == b_read_ptr_next)
  //   a_empty = (a_write_ptr == b_read_ptr) && (a_write_ptr_next != b_read_ptr_next)
  //   b_full = (b_write_ptr == a_read_ptr) ... Wait, B is reading, so B doesn't write.
  //   b_empty = (b_write_ptr == a_read_ptr) ... B is reading, so b_empty is not relevant for B's write capability (since B isn't writing).
  //   But the module outputs b_full and b_empty.
  //   If B is a reader, b_full should indicate "FIFO is full" (so B can't read more? No, full means can't write).
  //   If B is a reader, b_full is meaningless for B's operation, but we must output it.
  //   Usually, b_full indicates "FIFO is full" (from B's perspective as a potential writer).
  //   If B is a reader, b_full is just the status of the FIFO being full.
  //   So, b_full = (b_write_ptr == a_read_ptr) ... No.
  
  // Let's stick to the definition:
  // a_full: FIFO is full (cannot write).
  // a_empty: FIFO is empty (cannot read).
  // b_full: FIFO is full (cannot write).
  // b_empty: FIFO is empty (cannot read).
  
  // In a dual-port FIFO (one writer, one reader):
  // If A is writer, B is reader:
  //   a_full = (a_wp == b_rp) && (a_wp_next == b_rp_next)
  //   a_empty = (a_wp == b_rp) && (a_wp_next != b_rp_next)
  //   b_full = (b_wp == a_rp) ... But B is not writing. b_wp is not used for writing.
  //   However, if we consider the FIFO state globally:
  //   The FIFO is full when the writer's pointer meets the reader's pointer.
  //   So if A is writing, a_full is based on a_wp and b_rp.
  //   If B is writing, b_full is based on b_wp and a_rp.
  //   What about the other side's full/empty?
  //   If A is writing, B is reading.
  //   b_full: Can B write? B is configured as a reader. But if B were to write, it would conflict.
  //   Let's assume the "Full" flag always reflects the physical fullness of the FIFO.
  //   Physical Fullness = (Total Writes) == (Total Reads).
  //   This is hard to track with independent pointers.
  
  // Alternative Interpretation of "Bidirectional":
  // Maybe it's two separate FIFOs? No, "external dual-port RAM interface" implies one memory.
  // Maybe the pointers are shared? No, "Pointers in both directions cross".
  
  // Let's go with the most robust interpretation for a "Bidirectional Async FIFO" with external RAM:
  // The FIFO has a single logical address space.
  // Side A has a write pointer (a_wp) and read pointer (a_rp).
  // Side B has a write pointer (b_wp) and read pointer (b_rp).
  // The "Full" flag for A is true if A cannot write. This happens if the FIFO is full.
  // The FIFO is full if the distance between the global write head and global read head is 0.
  // But we don't have a global head.
  // However, in a standard dual-port FIFO (one writer, one reader), the writer checks the reader's pointer.
  // If A is the writer, A checks B's read pointer.
  // If B is the writer, B checks A's read pointer.
  // The "Full" flag for the non-writing side is less critical but can be derived.
  // If A is writing, B is reading.
  //   a_full = (a_wp == b_rp) && (a_wp_next == b_rp_next)
  //   a_empty = (a_wp == b_rp) && (a_wp_next != b_rp_next)
  //   b_full: Since B is reading, b_full is not used by B. But logically, if B were to write, it would be full if b_wp == a_rp.
  //   But since B is reading, b_wp is not advancing.
  //   Let's assume the question implies a scenario where the direction changes.
  //   If a_dir=1, A writes, B reads.
  //   If b_dir=1, B writes, A reads.
  //   We need to handle the case where a_dir and b_dir are both 1?
  //   The prompt says "See Behavior" for a_dir and b_dir.
  //   Let's assume they are mutually exclusive for write operations.
  //   If a_dir=1, A writes. If b_dir=1, B writes.
  //   If both are 1, we have a conflict. We will assume the design prevents this or prioritizes one.
  //   Let's assume if a_dir=1, A writes. If b_dir=1, B writes.
  //   The "Full" status for A is determined by B's read pointer (since B is the consumer).
  //   The "Full" status for B is determined by A's read pointer (since A is the consumer).
  //   Wait, if A is writing and B is reading, then B is the consumer.
  //   So a_full depends on b_rp.
  //   And b_full? If B is reading, B is not writing. So b_full is not relevant for B's write capability.
  //   But the output b_full exists.
  //   Perhaps b_full indicates "FIFO is full" regardless of who is writing.
  //   If A is writing, the FIFO fills up. When it is full, b_full should be 1.
  //   So b_full = a_full.
  //   Similarly, a_empty = b_empty.
  
  // Let's refine the logic based on the "Two-Port Async FIFO" standard:
  // In a two-port FIFO, there is one writer and one reader.
  // The writer checks the reader's pointer to determine Full/Empty.
  // The reader checks the writer's pointer to determine Full/Empty (for backpressure).
  // Here, we have two sides that can switch roles.
  // If a_dir=1 (A writes, B reads):
  //   a_full = (a_wp == b_rp) && (a_wp_next == b_rp_next)
  //   a_empty = (a_wp == b_rp) && (a_wp_next != b_rp_next)
  //   b_full = a_full (since FIFO is full)
  //   b_empty = a_empty (since FIFO is empty)
  // If b_dir=1 (B writes, A reads):
  //   b_full = (b_wp == a_rp) && (b_wp_next == a_rp_next)
  //   b_empty = (b_wp == a_rp) && (b_wp_next != a_rp_next)
  //   a_full = b_full
  //   a_empty = b_empty
  // If both 0: Idle.
  // If both 1: Conflict. We will assume no write occurs, or we prioritize.
  // Let's assume if a_dir=1, A writes. If b_dir=1, B writes.
  // We need to synchronize the pointers to calculate the status.
  
  // Synchronization Plan