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

  localparam INT_ASIZE = 1 << ASIZE;

  // Cross-clock pointers and flags
  // Side A logic runs on a_clk, Side B logic runs on b_clk
  // Pointers are registered on the opposite clock to allow crossing

  // --- Side A Logic (Clock: a_clk) ---
  // Controls writes to RAM from A's perspective (if A is writer)
  // Controls reads from RAM for A (if A is reader)
  // Generates flags for A based on B's pointers

  reg [ASIZE-1:0] a_wptr_reg;
  reg [ASIZE-1:0] a_rptr_reg;
  reg [ASIZE-1:0] b_wptr_reg;
  reg [ASIZE-1:0] b_rptr_reg;
  reg             a_wptr_valid;
  reg             a_rptr_valid;
  reg             b_wptr_valid;
  reg             b_rptr_valid;
  reg             a_full_reg;
  reg             a_empty_reg;
  reg             a_full_sync;
  reg             a_empty_sync;
  reg             b_full_reg;
  reg             b_empty_reg;
  reg             b_full_sync;
  reg             b_empty_sync;

  // --- Side B Logic (Clock: b_clk) ---
  // Controls writes to RAM from B's perspective (if B is writer)
  // Controls reads from RAM for B (if B is reader)
  // Generates flags for B based on A's pointers

  // Registers for B's view of pointers (sampled on b_clk)
  reg [ASIZE-1:0] b_wptr_sample;
  reg [ASIZE-1:0] b_rptr_sample;
  reg             b_wptr_sample_valid;
  reg             b_rptr_sample_valid;
  reg             b_full_sample;
  reg             b_empty_sample;
  reg             b_full_sample_sync;
  reg             b_empty_sample_sync;

  // Registers for A's view of pointers (sampled on a_clk)
  reg [ASIZE-1:0] a_wptr_sample;
  reg [ASIZE-1:0] a_rptr_sample;
  reg             a_wptr_sample_valid;
  reg             a_rptr_sample_valid;
  reg             a_full_sample;
  reg             a_empty_sample;
  reg             a_full_sample_sync;
  reg             a_empty_sample_sync;

  // --- RAM Interface Signals ---
  wire [ASIZE-1:0] ram_addr_a;
  wire [DSIZE-1:0] ram_wdata_a;
  wire             ram_winc_a;
  wire             ram_rinc_a;
  wire             ram_clk_a;

  wire [ASIZE-1:0] ram_addr_b;
  wire [DSIZE-1:0] ram_wdata_b;
  wire             ram_winc_b;
  wire             ram_rinc_b;
  wire             ram_clk_b;

  // --- Internal State Machine for Direction Handling ---
  // We need to determine who is writing and who is reading.
  // a_dir = 1 -> A writes, B reads.
  // a_dir = 0 -> B writes, A reads.
  // Note: The problem statement implies a dynamic bidirectional FIFO.
  // Usually, direction is fixed per transaction or toggled. 
  // Assuming a_dir and b_dir indicate the current desired operation mode.
  // If a_dir is high, A acts as Writer, B as Reader.
  // If a_dir is low, B acts as Writer, A as Reader.
  // We assume a_dir and b_dir are consistent (one high, one low) or handled by priority.
  // Let's assume a_dir controls the mode.

  wire a_is_writer = a_dir;
  wire b_is_writer = ~a_dir;

  // --- Side A Logic Implementation ---

  // 1. Pointer Updates (A's local pointers)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wptr_reg <= 0;
      a_rptr_reg <= 0;
      a_wptr_valid <= 0;
      a_rptr_valid <= 0;
      a_full_reg <= 0;
      a_empty_reg <= 1;
    end else begin
      // Write Pointer Update
      if (a_is_writer && a_winc) begin
        if (a_empty_reg) begin
          a_wptr_reg <= 0;
          a_empty_reg <= 0;
        end else begin
          a_wptr_reg <= a_wptr_reg + 1'b1;
        end
      end
      // Read Pointer Update
      if (a_is_reader && a_rinc) begin
        if (a_full_reg) begin
          a_rptr_reg <= a_rptr_reg + 1'b1;
          a_full_reg <= 0;
        end else begin
          a_rptr_reg <= a_rptr_reg + 1'b1;
          a_empty_reg <= 0;
        end
      end
    end
  end

  // 2. Flag Generation (A's view of Full/Empty based on B's pointers)
  // Since B's pointers are on b_clk, we sample them on a_clk.
  // We need to handle the "lag" correctly.
  // Standard Gray code or binary snapshot with valid flag.
  // Here we use binary pointers with a valid flag to indicate the snapshot is stable.

  // Sample B's pointers on a_clk
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wptr_sample <= 0;
      b_rptr_sample <= 0;
      b_wptr_sample_valid <= 0;
      b_rptr_sample_valid <= 0;
      b_full_sample <= 0;
      b_empty_sample <= 1;
    end else begin
      if (b_wptr_valid) begin
        b_wptr_sample <= b_wptr_reg;
        b_wptr_sample_valid <= 1;
      end
      if (b_rptr_valid) begin
        b_rptr_sample <= b_rptr_reg;
        b_rptr_sample_valid <= 1;
      end
      
      // Calculate Full/Empty based on sampled pointers
      // Full: wptr == rptr (if FALLTHROUGH) or wptr == rptr + 1 (if not)
      // Empty: wptr == rptr
      
      // Note: In a bidirectional setup, the "other side" pointer determines the status.
      // If A is reader, B is writer. A checks B's wptr vs B's rptr.
      // If A is writer, B is reader. A checks B's rptr vs B's wptr? 
      // Actually, the FIFO state is global. 
      // If A is writer, the FIFO fills up. A needs to know if it's full.
      // Full condition: B's write pointer == B's read pointer (if fallthrough) or +1.
      // Wait, if B is reader, B's rptr is the one moving. B's wptr is static (last written).
      // So if A is writer, A checks if B's rptr == B's wptr (full) or +1.
      
      // Let's standardize:
      // FIFO Full: Write Ptr == Read Ptr (Fallthrough) OR Write Ptr == Read Ptr + 1 (No Fallthrough)
      // FIFO Empty: Write Ptr == Read Ptr
      
      // If A is Writer: A checks B's pointers.
      // If A is Reader: A checks B's pointers.
      // The pointers b_wptr_reg and b_rptr_reg are maintained by B's logic.
      // B updates its own pointers based on its winc/rinc.
      
      // Logic for A's Full/Empty flags:
      // We compare the sampled B pointers.
      // However, we must ensure we are comparing the correct pointers.
      // If B is the writer, b_wptr_reg is the active write pointer.
      // If B is the reader, b_rptr_reg is the active read pointer.
      // But in a FIFO, there is always one writer and one reader.
      // If A is writer, B is reader. B's rptr is the one that matters for emptiness/fullness relative to B's wptr.
      // Actually, the pointers are global. 
      // Let's assume the pointers are maintained such that:
      // wptr points to the next free slot (or last filled).
      // rptr points to the next valid slot.
      
      // If A is writer: A writes to wptr. A checks if wptr == rptr (full).
      // But A doesn't have wptr_reg directly? Yes it does.
      // But A needs to know if it's full BEFORE writing.
      // A checks B's rptr. If A's wptr == B's rptr, then full.
      // Wait, if A is writer, A owns the wptr. B owns the rptr.
      // So A compares its own wptr_reg with B's rptr_sample.
      
      // If A is reader: A reads from rptr. A checks if rptr == wptr (empty).
      // A compares its own rptr_reg with B's wptr_sample.
      
      // This simplifies things:
      // If A is Writer: Full = (a_wptr_reg == b_rptr_sample) [with lag handling]
      // If A is Reader: Empty = (a_rptr_reg == b_wptr_sample) [with lag handling]
      
      // However, the problem says "Pointers in both directions cross as acknowledged binary snapshots".
      // This implies we need to handle the crossing carefully.
      // Let's implement the standard cross-clock FIFO flag logic.
      
      // We will generate a_full_reg and a_empty_reg based on the comparison of A's pointers 
      // and the sampled B pointers.
      
      // Case 1: A is Writer, B is Reader.
      // A checks if it can write. Full if a_wptr_reg == b_rptr_sample.
      // Case 2: A is Reader, B is Writer.
      // A checks if it can read. Empty if a_rptr_reg == b_wptr_sample.
      
      // To make it robust, we can always compute both, but only use the relevant one.
      // Actually, in a bidirectional FIFO, the direction changes.
      // When direction changes, the roles swap.
      
      // Let's refine the pointer logic.
      // We need to ensure that when A is writer, we use B's rptr.
      // When A is reader, we use B's wptr.
      
      // But wait, if A is writer, B is reader. B updates b_rptr.
      // If A is reader, B is writer. B updates b_wptr.
      
      // So:
      // If a_is_writer:
      //   a_full_reg = (a_wptr_reg == b_rptr_sample)
      //   a_empty_reg = (a_wptr_reg == b_rptr_sample) // Wait, if A is writer, empty means wptr == rptr?
      //   Actually, if A is writer, the FIFO is empty if wptr == rptr.
      //   But if A is writer, B is reader. B's rptr is the one that has been incremented by B.
      //   So yes, a_wptr_reg == b_rptr_sample means empty.
      //   And a_wptr_reg == b_rptr_sample - 1 means full? No.
      //   Standard: 
      //   Empty: wptr == rptr
      //   Full: wptr == rptr (fallthrough) or wptr == rptr + 1 (no fallthrough)
      
      //   If A is writer:
      //     Empty: a_wptr_reg == b_rptr_sample
      //     Full: a_wptr_reg == b_rptr_sample (if fallthrough) or a_wptr_reg == b_rptr_sample + 1 (if not)
      //     Wait, if A is writer, B is reader. B increments rptr.
      //     So if A writes, wptr increments.
      //     If wptr == rptr, it's empty.
      //     If wptr == rptr (next), it's full.
      
      //   If A is reader:
      //     Empty: a_rptr_reg == b_wptr_sample
      //     Full: a_rptr_reg == b_wptr_sample (if fallthrough) or a_rptr_reg == b_wptr_sample - 1 (if not)
      
      // This seems correct.
      
      // Let's implement the flag generation.
      // We need to handle the "lag" by using the valid flags.
      // If the valid flag is not set, we assume the FIFO is empty (safe for reader) or full (safe for writer)?
      // Usually, if we don't know the pointer, we assume empty to avoid over-read, or full to avoid over-write.
      // For a writer, if we don't know if it's full, we should assume full (don't write).
      // For a reader, if we don't know if it's empty, we should assume empty (don't read).
      
      // However, the valid flags are generated by the other side.
      // If B is reader, B sets b_rptr_valid. A samples it.
      // If b_rptr_valid is 0, A doesn't know B's rptr.
      
      // Let's simplify:
      // We will generate the flags based on the comparison, but only trust them if valid.
      // If not valid, we default to safe state.
      
      // Safe defaults:
      // If A is writer: If we don't know if full, assume full (a_full = 1).
      // If A is reader: If we don't know if empty, assume empty (a_empty = 1).
      
      // But wait, the problem says "full and empty can lag".
      // This implies we should output the lagged flags.
      
      // Let's implement the logic:
      // If a_is_writer:
      //   a_full_reg = (a_wptr_reg == b_rptr_sample) && b_rptr_sample_valid
      //   a_empty_reg = (a_wptr_reg == b_rptr_sample) && b_rptr_sample_valid
      //   Wait, if fallthrough is false, full is wptr == rptr + 1.
      
      // Let's use a helper function logic inside the always block.
      
      // Re-evaluating the pointer logic for Bidirectional FIFO.
      // In a bidirectional FIFO, the pointers are shared.
      // When A writes, A increments wptr.
      // When B reads, B increments rptr.
      // When B writes, B increments wptr.
      // When A reads, A increments rptr.
      
      // So:
      // wptr is incremented by whoever is writing.
      // rptr is incremented by whoever is reading.
      
      // If A is writer: A increments wptr. B increments rptr.
      // If A is reader: A increments rptr. B increments wptr.
      
      // So the pointers are always maintained by the active side.
      // But we need to sample the OTHER side's pointer to check status.
      
      // If A is writer:
      //   A checks B's rptr to see if full/empty.
      //   A's wptr is local.
      //   B's rptr is remote.
      
      // If A is reader:
      //   A checks B's wptr to see if full/empty.
      //   A's rptr is local.
      //   B's wptr is remote.
      
      // This confirms the previous logic.
      
      // Implementation details:
      // We need to handle the FALLTHROUGH parameter.
      // If FALLTHROUGH:
      //   Full: wptr == rptr
      //   Empty: wptr == rptr
      // If !FALLTHROUGH:
      //   Full: wptr == rptr + 1
      //   Empty: wptr == rptr
      
      // Let's code this.
      
      // Side A Flag Logic
      if (a_is_writer) begin
        // A is writer, B is reader.
        // Check Full/Empty using A's wptr and B's rptr.
        if (b_rptr_sample_valid) begin
          if (FALLTHROUGH) begin
            a_full_reg <= (a_wptr_reg == b_rptr_sample);
            a_empty_reg <= (a_wptr_reg == b_rptr_sample);
          end else begin
            a_full_reg <= (a_wptr_reg == b_rptr_sample + 1'b1);
            a_empty_reg <= (a_wptr_reg == b_rptr_sample);
          end
        end else begin
          // If B's rptr is not valid, assume worst case for writer (Full)
          // to prevent overflow.
          a_full_reg <= 1;
          a_empty_reg <= 0;
        end
      end else begin
        // A is reader, B is writer.
        // Check Full/Empty using A's rptr and B's wptr.
        if (b_wptr_sample_valid) begin
          if (FALLTHROUGH) begin
            a_full_reg <= (a_rptr_reg == b_wptr_sample);
            a_empty_reg <= (a_rptr_reg == b_wptr_sample);
          end else begin
            a_full_reg <= (a_rptr_reg == b_wptr_sample - 1'b1);
            a_empty_reg <= (a_rptr_reg == b_wptr_sample);
          end
        end else begin
          // If B's wptr is not valid, assume worst case for reader (Empty)
          // to prevent underflow.
          a_full_reg <= 0;
          a_empty_reg <= 1;
        end
      end
      
      // Sync the flags to output
      a_full_sync <= a_full_reg;
      a_empty_sync <= a_empty_reg;
      
      // Valid flags for A's own pointers (for internal use or if needed by B)
      // Actually, A's pointers are updated on a_clk, so they are always valid for A's logic.
      // But B needs to sample them.
      a_wptr_valid <= 1;
      a_rptr_valid <= 1;
      
    end
  end

  // --- Side B Logic Implementation ---
  // Similar logic, but running on b_clk.
  
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wptr_reg <= 0;
      b_rptr_reg <= 0;
      b_wptr_valid <= 0;
      b_rptr_valid <= 0;
      b_full_reg <= 0;
      b_empty_reg <= 1;
    end else begin
      // Write Pointer Update
      if (b_is_writer && b_winc) begin
        if (b_empty_reg) begin
          b_wptr_reg <= 0;
          b_empty_reg <= 0;
        end else begin
          b_wptr_reg <= b_wptr_reg + 1'b1;
        end
      end
      // Read Pointer Update
      if (b_is_reader && b_rinc) begin
        if (b_full_reg) begin
          b_rptr_reg <= b_rptr_reg + 1'b1;
          b_full_reg <= 0;
        end else begin
          b_rptr_reg <= b_rptr_reg + 1'b1;
          b_empty_reg <= 0;
        end
      end
    end
  end

  // Sample A's pointers on b_clk
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wptr_sample <= 0;
      a_rptr_sample <= 0;
      a_wptr_sample_valid <= 0;
      a_rptr_sample_valid <= 0;
      a_full_sample <= 0;
      a_empty_sample <= 1;
    end else begin
      if (a_wptr_valid) begin
        a_wptr_sample <= a_wptr_reg;
        a_wptr_sample_valid <= 1;
      end
      if (a_rptr_valid) begin
        a_rptr_sample <= a_rptr_reg;
        a_rptr_sample_valid <= 1;
      end
      
      if (b_is_writer) begin
        // B is writer, A is reader.
        // Check Full/Empty using B's wptr and A's rptr.
        if (a_rptr_sample_valid) begin
          if (FALLTHROUGH) begin
            b_full_reg <= (b_wptr_reg == a_rptr_sample);
            b_empty_reg <= (b_wptr_reg == a_rptr_sample);
          end else begin
            b_full_reg <= (b_wptr_reg == a_rptr_sample + 1'b1);
            b_empty_reg <= (b_wptr_reg == a_rptr_sample);
          end
        end else begin
          b_full_reg <= 0;
          b_empty_reg <= 1;
        end
      end else begin
        // B is reader, A is writer.
        // Check Full/Empty using B's rptr and A's wptr.
        if (a_wptr_sample_valid) begin
          if (FALLTHROUGH) begin
            b_full_reg <= (b_rptr_reg == a_wptr_sample);
            b_empty_reg <= (b_rptr_reg == a_wptr_sample);
          end else begin
            b_full_reg <= (b_rptr_reg == a_wptr_sample + 1'b1);
            b_empty_reg <= (b_rptr_reg == a_wptr_sample);
          end
        end else begin
          b_full_reg <= 1;
          b_empty_reg <= 0;
        end
      end
      
      b_full_sample_sync <= b_full_reg;
      b_empty_sample_sync <= b_empty_reg;
      
      b_wptr_valid <= 1;
      b_rptr_valid <= 1;
    end
  end

  // --- RAM Interface Generation ---
  
  // Determine which side is writing and which is reading.
  // If a_dir is high, A writes, B reads.
  // If a_dir is low, B writes, A reads.
  
  // We need to generate the RAM control signals.
  // The RAM is dual-port.
  // Port A: Address o_ram_a_addr, Write o_ram_a_wdata, WriteInc o_ram_a_winc, ReadInc o_ram_a_rinc
  // Port B: Address o_ram_b_addr, Write o_ram_b_wdata, WriteInc o_ram_b_winc, ReadInc o_ram_b_rinc
  
  // Clocks for RAM ports are driven by the respective sides.
  o_ram_a_clk <= a_clk;
  o_ram_b_clk <= b_clk;
  
  // Write Data and Address
  // If A is writer: A writes to RAM. B reads from RAM.
  // If B is writer: B writes to RAM. A reads from RAM.
  
  // We need to handle the case where both might try to write? 
  // The problem implies a bidirectional FIFO where direction is controlled.
  // We assume only one side writes at a time.
  
  // Write Enable Logic
  wire a_wen = a_is_writer && a_winc;
  wire b_wen = b_is_writer && b_winc;
  
  // Address Logic
  // If A is writer, A's wptr is the address.
  // If B is writer, B's wptr is the address.
  // Similarly for read.
  
  // We need to ensure that the address is stable during the write cycle.
  // Since the pointers are registered, they are stable on the clock edge.
  // However, the RAM write happens on the clock edge.
  // We need to make sure the address is valid.
  
  // Let's generate the addresses.
  // If A is writer: o_ram_a_addr = a_wptr_reg. o_ram_b_addr = b_rptr_reg (for read).
  // If B is writer: o_ram_b_addr = b_wptr_reg. o_ram_a_addr = a_rptr_reg (for read).
  
  // But wait, the RAM interface has separate read and write enables.
  // We need to drive the read enable on the opposite clock domain.
  // This is tricky. The RAM read data is available on the clock edge of the read port.
  // If A is reader, A reads on a_clk. The RAM read enable must be asserted on a_clk.
  // But the address for the read must be stable on a_clk.
  // The address is a_rptr_reg (A's pointer). This is stable on a_clk.
  // So we can drive the RAM read enable on a_clk.
  
  // However, the problem states: "Drive o_ram_* clocks, addresses, write data, and enables."
  // And "Read data returns on i_ram_*_rdata".
  // This implies the RAM is external.
  // We need to drive the RAM ports correctly.
  
  // Let's define the RAM port signals.
  // Port A:
  //   Write: o_ram_a_winc, o_ram_a_wdata, o_ram_a_addr
  //   Read: o_ram_a_rinc, o_ram_a_clk (which is a_clk), i_ram_a_rdata is input.
  // Port B:
  //   Write: o_ram_b_winc, o_ram_b_wdata, o_ram_b_addr
  //   Read: o_ram_b_rinc, o_ram_b_clk (which is b_clk), i_ram_b_rdata is input.
  
  // Logic for Port A:
  // If A is writer:
  //   o_ram_a_winc = a_winc
  //   o_ram_a_wdata = a_wdata
  //   o_ram_a_addr = a_wptr_reg
  //   o_ram_a_rinc = 0 (A is not reading)
  // If A is reader:
  //   o_ram_a_winc = 0
  //   o_ram_a_wdata = 0
  //   o_ram_a_addr = a_rptr_reg
  //   o_ram_a_rinc = a_rinc
  
  // Logic for Port B:
  // If B is writer:
  //   o_ram_b_winc = b_winc
  //   o_ram_b_wdata = b_wdata
  //   o_ram_b_addr = b_wptr_reg
  //   o_ram_b_rinc = 0
  // If B is reader:
  //   o_ram_b_winc = 0
  //   o_ram_b_wdata = 0
  //   o_ram_b_addr = b_rptr_reg
  //   o_ram_b_rinc = b_rinc
  
  // But wait, if A is writer, B is reader.
  // A writes to address a_wptr_reg.
  // B reads from address b_rptr_reg.
  // These addresses must be different (unless full/empty).
  
  // There is a potential issue: The RAM read enable must be asserted on the clock of the reader.
  // If A is reader, A reads on a_clk. So o_ram_a_rinc should be driven on a_clk.
  // But o_ram_a_rinc is an output. It can be driven on a_clk.
  // The address o_ram_a_addr must also be driven on a_clk.
  // Since a_rptr_reg is updated on a_clk, it is stable on a_clk.
  // So this works.
  
  // However, the problem says "Pointers in both directions cross as acknowledged binary snapshots".
  // This suggests that the pointers are sampled across clocks.
  // But for the RAM interface, we need to drive the address on the clock of the operation.
  // If A is writing, A drives the write address on a_clk.
  // If B is reading, B drives the read address on b_clk.
  // This is straightforward.
  
  // But what if the direction changes?
  // If a_dir changes, the roles swap.
  // We need to ensure that the RAM ports are configured correctly.
  
  // Let's implement the port driving logic.
  
  // Port A Driving
  assign o_ram_a_clk = a_clk;
  assign o_ram_a_winc = (a_is_writer) ? a_winc : 1'b0;
  assign o_ram_a_wdata = (a_is_writer) ? a_wdata : 1'b0;
  assign o_ram_a_addr = (a_is_writer) ? a_wptr_reg : a_rptr_reg;
  assign o_ram_a_rinc = (a_is_reader) ? a_rinc : 1'b0;
  
  // Port B Driving
  assign o_ram_b_clk = b_clk;
  assign o_ram_b_winc = (b_is_writer) ? b_winc : 1'b0;
  assign o_ram_b_wdata = (b_is_writer) ? b_wdata : 1'b0;
  assign o_ram_b_addr = (b_is_writer) ? b_wptr_reg : b_rptr_reg;
  assign o_ram_b_rinc = (b_is_reader) ? b_rinc : 1'b0;
  
  // --- Data Output Generation ---
  
  // A's Read Data
  // If A is reader, A reads from RAM.
  // The data comes from i_ram_a_rdata.
  // But we need to ensure that the read is happening at the correct time.
  // The RAM read data is available on the clock edge of the read port (a_clk).
  // So we can sample i_ram_a_rdata on a_clk.
  
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata <= 0;
    end else begin
      if (a_is_reader && a_rinc) begin
        // We just incremented the read pointer.
        // The data for the new pointer is available on i_ram_a_rdata.
        // But we need to make sure the RAM read was triggered.
        // o_ram_a_rinc is driven on a_clk.
        // So on the rising edge of a_clk, if a_rinc is high, the RAM reads.
        // The data is available after the clock edge.
        // So we sample it here.
        a_rdata <= i_ram_a_rdata;
      end else begin
        // If not reading, hold the last value or 0.
        // Usually, we hold the last valid value.
        // But if we don't read, the data is stale.
        // Let's hold the last value.
        // However, if the FIFO is empty, we should output 0 or Z.
        // Let's output 0 if empty.
        if (a_empty_reg) begin
          a_rdata <= 0;
        end else begin
          // If not empty and not reading, keep the last value?
          // Or just keep the last sampled value.
          // If we don't read, the data doesn't change.
          // But if we read, we update it.
          // So we can just keep the last value.
          // But we need to initialize it.
          // Let's use a latch or keep the last value.
          // Since it's an output, we can use a register.
          // If we don't read, we don't update.
          // But if the FIFO is empty, we should output 0.
          // So we check a_empty_reg.
          // But a_empty_reg is updated on a_clk.
          // So we can check it here.
          // If a_empty_reg is 1, output 0.
          // Else, output the last sampled value.
          // But we need to store the last sampled value.
          // Let's use a separate register for the data.
        end
      end
    end
  end
  
  // Wait, the logic above is slightly flawed.
  // If we don't read, we don't update a_rdata.
  // But if the FIFO is empty, we should output 0.
  // So we need to check a_empty_reg.
  // But a_empty_reg is updated on a_clk.
  // So we can check it here.
  // If a_empty_reg is 1, output 0.
  // Else, output the last sampled value.
  // But we need to store the last sampled value.
  // Let's use a separate register for the data.
  
  reg [DSIZE-1:0] a_rdata_reg;
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_rdata_reg <= 0;
    end else begin
      if (a_is_reader && a_rinc) begin
        a_rdata_reg <= i_ram_a_rdata;
      end else if (a_empty_reg) begin
        a_rdata_reg <= 0;
      end
      // If not reading and not empty, keep the last value.
    end
  end
  assign a_rdata = a_rdata_reg;
  
  // B's Read Data
  reg [DSIZE-1:0] b_rdata_reg;
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_rdata_reg <= 0;
    end else begin
      if (b_is_reader && b_rinc) begin
        b_rdata_reg <= i_ram_b_rdata;
      end else if (b_empty_reg) begin
        b_rdata_reg <= 0;
      end
    end
  end
  assign b_rdata = b_rdata_reg;
  
  // --- Output Flags ---
  assign a_full = a_full_sync;
  assign a_afull = a_full_sync; // Assuming afull is the same as full for this implementation
  assign a_empty = a_empty_sync;
  assign a_aempty = a_empty_sync; // Assuming aempty is the same as empty
  
  assign b_full = b_full_sample_sync;
  assign b_afull = b_full_sample_sync;
  assign b_empty = b_empty_sample_sync;
  assign b_aempty = b_empty_sample_sync;
  
  // Note: The problem statement mentions