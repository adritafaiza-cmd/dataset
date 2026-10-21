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

  // Internal pointers: Write pointers (W) and Read pointers (R)
  // We use separate pointers for each domain to avoid ambiguity during crossing.
  // Domain A pointers: Used by A for writing, sampled by B for reading.
  // Domain B pointers: Used by B for writing, sampled by A for reading.
  
  reg [ASIZE-1:0] a_wptr;
  reg [ASIZE-1:0] a_rptr;
  reg [ASIZE-1:0] b_wptr;
  reg [ASIZE-1:0] b_rptr;

  // Data storage
  reg [DSIZE-1:0] mem [0: {1<<ASIZE}-1];

  // Status flags
  reg a_full_int;
  reg a_empty_int;
  reg b_full_int;
  reg b_empty_int;

  // Cross-domain pointers (snapshots)
  wire [ASIZE-1:0] a_wptr_b; // A write pointer seen by B
  wire [ASIZE-1:0] a_rptr_b; // A read pointer seen by B
  wire [ASIZE-1:0] b_wptr_a; // B write pointer seen by A
  wire [ASIZE-1:0] b_rptr_a; // B read pointer seen by A

  // Generate cross-domain pointers using Gray code logic or simple async flip-flops
  // Since ASIZE is small (4), we can just use simple registers to capture the pointer value
  // at the receiving clock edge.
  
  reg [ASIZE-1:0] a_wptr_reg_b;
  reg [ASIZE-1:0] a_rptr_reg_b;
  reg [ASIZE-1:0] b_wptr_reg_a;
  reg [ASIZE-1:0] b_rptr_reg_a;

  // --- Domain A Logic (Clock: a_clk) ---

  // Write Pointer Update (Domain A)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_wptr <= 0;
    else if (a_winc)
      a_wptr <= a_wptr + 1'b1;
  end

  // Read Pointer Update (Domain A)
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n)
      a_rptr <= 0;
    else if (a_rinc && !a_empty) // Only increment if not empty to prevent underflow
      a_rptr <= a_rptr + 1'b1;
  end

  // Full/Empty Logic (Domain A)
  // Full: Write pointer == Read pointer + 1 (circular buffer)
  // Empty: Write pointer == Read pointer
  always @(*) begin
    a_full_int = 1'b0;
    a_empty_int = 1'b0;
    
    if (a_wptr == a_rptr)
      a_empty_int = 1'b1;
    else if (a_wptr == (a_rptr + 1'b1) [ASIZE-1:0])
      a_full_int = 1'b1;
  end

  // Read Data Output (Domain A)
  // Sample the data at the read pointer
  always @(*) begin
    if (a_empty_int)
      a_rdata = 0; // Or don't care, but 0 is safe
    else
      a_rdata = mem[a_rptr];
  end

  // --- Domain B Logic (Clock: b_clk) ---

  // Write Pointer Update (Domain B)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_wptr <= 0;
    else if (b_winc)
      b_wptr <= b_wptr + 1'b1;
  end

  // Read Pointer Update (Domain B)
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n)
      b_rptr <= 0;
    else if (b_rinc && !b_empty) // Only increment if not empty
      b_rptr <= b_rptr + 1'b1;
  end

  // Full/Empty Logic (Domain B)
  always @(*) begin
    b_full_int = 1'b0;
    b_empty_int = 1'b0;
    
    if (b_wptr == b_rptr)
      b_empty_int = 1'b1;
    else if (b_wptr == (b_rptr + 1'b1) [ASIZE-1:0])
      b_full_int = 1'b1;
  end

  // Read Data Output (Domain B)
  always @(*) begin
    if (b_empty_int)
      b_rdata = 0;
    else
      b_rdata = mem[b_rptr];
  end

  // --- Cross Domain Pointer Sampling ---

  // Capture A pointers in B domain
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wptr_reg_b <= 0;
      a_rptr_reg_b <= 0;
    end else begin
      a_wptr_reg_b <= a_wptr;
      a_rptr_reg_b <= a_rptr;
    end
  end

  // Capture B pointers in A domain
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wptr_reg_a <= 0;
      b_rptr_reg_a <= 0;
    end else begin
      b_wptr_reg_a <= b_wptr;
      b_rptr_reg_a <= b_rptr;
    end
  end

  // --- Write Logic with Direction Control ---

  // Determine which side is writing based on direction signals
  // a_dir = 1 -> A is writing to the FIFO (from A's perspective)
  // b_dir = 1 -> B is writing to the FIFO (from B's perspective)
  // Note: The problem says "Move words in either direction, as selected on each side".
  // Usually, in bidirectional FIFOs:
  // If a_dir == 1, A writes, B reads.
  // If b_dir == 1, B writes, A reads.
  // We assume exclusive control or a specific protocol. 
  // Given the interface, we assume:
  // a_dir controls A's write enable.
  // b_dir controls B's write enable.
  // However, they share the same memory. We must ensure only one side writes at a time 
  // or handle the pointer logic carefully. 
  // Standard interpretation: 
  // If a_dir is high, A is the master (writes), B is slave (reads).
  // If b_dir is high, B is the master (writes), A is slave (reads).
  // If both are low, no one writes.
  // If both are high, undefined behavior (collision). We assume valid usage where only one writes.

  // Write Enable for Domain A
  wire a_we = (a_dir && a_winc);
  
  // Write Enable for Domain B
  wire b_we = (b_dir && b_winc);

  // Write Data Selection
  // If A is writing, data comes from a_wdata.
  // If B is writing, data comes from b_wdata.
  // We need to write to the memory at the respective write pointer.
  
  // Since we have two write pointers (a_wptr and b_wptr), we need to decide which pointer to increment
  // and where to write.
  
  // Logic:
  // If a_dir is active, A writes. We write to mem[a_wptr] and increment a_wptr.
  // If b_dir is active, B writes. We write to mem[b_wptr] and increment b_wptr.
  // This implies the memory is shared, but the logical "head" and "tail" are managed by the active direction.
  // Wait, if A writes and B reads, the pointers are a_wptr and a_rptr.
  // If B writes and A reads, the pointers are b_wptr and b_rptr.
  // But they share the same physical memory `mem`.
  // This creates a conflict if both try to write to the same location or if the pointers diverge.
  // Standard Bidirectional FIFO implementation usually involves:
  // 1. A single write pointer and single read pointer if the direction is fixed.
  // 2. Or, two independent FIFOs? No, the prompt implies one shared resource.
  // 3. Or, the pointers are coupled.
  
  // Re-reading the prompt: "Move words in either direction... Pointers in both directions cross as acknowledged binary snapshots".
  // This suggests a single logical FIFO where the direction determines who writes and who reads.
  // However, the interface has `a_winc`, `a_wdata` and `b_winc`, `b_wdata`.
  // And `a_dir`, `b_dir`.
  
  // Interpretation:
  // The FIFO has a single physical buffer.
  // When `a_dir` is asserted, A owns the FIFO. A writes (using a_winc/a_wdata), B reads (using b_rinc).
  // The pointers used are effectively `a_wptr` and `a_rptr`.
  // When `b_dir` is asserted, B owns the FIFO. B writes (using b_winc/b_wdata), A reads (using a_rinc).
  // The pointers used are effectively `b_wptr` and `b_rptr`.
  // BUT, the pointers must be consistent. If A writes, `a_wptr` moves. If B writes, `b_wptr` moves.
  // If they are independent, how do we know where the data is?
  // Usually, in such designs, there is ONE write pointer and ONE read pointer for the whole FIFO.
  // The direction signal selects which side drives the write pointer and which side drives the read pointer.
  // However, the prompt asks for `a_wptr` and `b_wptr` logic implicitly by having separate clocks and resets.
  // Let's assume the standard "Dual Port" behavior but synchronized by direction.
  // Actually, the most robust way for a shared memory with direction control is:
  // There is a single Write Pointer (WP) and a single Read Pointer (RP).
  // If a_dir is high: WP is driven by A, RP is driven by B.
  // If b_dir is high: WP is driven by B, RP is driven by A.
  // But the clocks are different.
  
  // Alternative Interpretation (Independent Pointers):
  // Maybe the FIFO is actually two FIFOs? No, "bidirectional" usually means one buffer.
  // Let's look at the "Pointers in both directions cross" hint.
  // This implies we have pointers for A (a_wptr, a_rptr) and pointers for B (b_wptr, b_rptr).
  // If A is writing, it updates a_wptr. If B is writing, it updates b_wptr.
  // If A is reading, it updates a_rptr. If B is reading, it updates b_rptr.
  // The memory access must be consistent.
  // If A writes, it writes to `a_wptr`. If B reads, it reads from `b_rptr`.
  // For this to work, `a_wptr` and `b_rptr` must be the same logical pointer when A is writing and B is reading.
  // But they are in different domains.
  
  // Correct Approach for Shared Memory Bidirectional FIFO:
  // We maintain ONE physical write pointer and ONE physical read pointer in the memory.
  // However, since the clocks are different, we cannot have a single register updated by both domains directly without metastability.
  // Instead, we use the "Direction" to select which domain controls the Write Pointer and which controls the Read Pointer.
  // But the Write Pointer must be updated in the domain that is writing.
  // And the Read Pointer must be updated in the domain that is reading.
  // The memory is accessed at the Write Pointer (for write) and Read Pointer (for read).
  // The pointers must be synchronized.
  
  // Let's refine the architecture:
  // We have two sets of pointers: Set A (a_wptr, a_rptr) and Set B (b_wptr, b_rptr).
  // When `a_dir` is active:
  //   - A writes: Updates `a_wptr`. Writes to `mem[a_wptr]`.
  //   - B reads: Updates `b_rptr`. Reads from `mem[b_rptr]`.
  //   - Constraint: `a_wptr` and `b_rptr` must track the same logical position.
  //   - How? `a_wptr` is updated in domain A. `b_rptr` is updated in domain B.
  //   - We need to ensure `a_wptr` (seen by B) == `b_rptr` (seen by A) when full/empty checks happen?
  //   - No, the pointers themselves are the state.
  //   - If A writes, `a_wptr` increments. B sees `a_wptr` via cross-domain sampling.
  //   - If B reads, `b_rptr` increments. A sees `b_rptr` via cross-domain sampling.
  //   - The Full/Empty condition is: `a_wptr` (crossed to B) == `b_rptr` (crossed to A)?
  //   - No, that's not right.
  
  // Let's reconsider the standard implementation for this specific prompt style.
  // Often, "Bidirectional FIFO" with independent clocks implies:
  // The FIFO is empty initially.
  // If A wants to write, it asserts `a_dir`. A writes to the FIFO. The FIFO fills up.
  // B reads from the FIFO.
  // If B wants to write, it asserts `b_dir`. B writes to the FIFO. The FIFO fills up.
  // A reads from the FIFO.
  // The key is that the FIFO has ONE logical content.
  // Therefore, there should be ONE Write Pointer and ONE Read Pointer.
  // But since the clocks are different, we can't have a single register updated by both.
  // Solution:
  // We have two pointers for the Write side: `wp_a` (controlled by A) and `wp_b` (controlled by B).
  // We have two pointers for the Read side: `rp_a` (controlled by A) and `rp_b` (controlled by B).
  // BUT, only one pair is active at a time based on `a_dir` and `b_dir`.
  // Actually, the pointers must be coupled.
  // If A is writing, `wp_a` is the valid write pointer. `wp_b` is irrelevant or follows `wp_a`.
  // If B is writing, `wp_b` is the valid write pointer. `wp_a` is irrelevant.
  // Same for read.
  // The memory is accessed at `wp` and `rp`.
  // The Full/Empty logic compares `wp` and `rp`.
  // Since `wp` and `rp` are in different domains, we compare the crossed versions.
  
  // Revised Architecture:
  // 1. Write Pointers:
  //    - `wp_a`: Updated by A when `a_dir` is high.
  //    - `wp_b`: Updated by B when `b_dir` is high.
  //    - When `a_dir` is high, `wp_a` is the active write pointer. `wp_b` is ignored (or held constant).
  //    - When `b_dir` is high, `wp_b` is the active write pointer. `wp_a` is ignored.
  //    - Wait, if `a_dir` is high, A writes. B reads. B needs to know where the data is.
  //      B samples `wp_a`. So B compares `wp_a` (sampled) with `rp_b`.
  // 2. Read Pointers:
  //    - `rp_a`: Updated by A when `a_dir` is low (A is reading).
  //    - `rp_b`: Updated by B when `b_dir` is high (B is reading).
  //    - When `a_dir` is high (A writes, B reads): `rp_b` is active. A samples `rp_b` to check empty?
  //      No, A doesn't need to check empty if it's writing. But B needs to check empty.
  //      B checks `rp_b` vs `wp_a`.
  //    - When `b_dir` is high (B writes, A reads): `rp_a` is active. B samples `rp_a` to check empty?
  //      B checks `rp_a` vs `wp_b`.
  
  // This seems complex to manage with just two pointers per side.
  // Let's simplify:
  // We maintain TWO independent FIFO structures logically, but they share the same memory array?
  // No, that would be two FIFOs.
  
  // Let's go with the most common interpretation for this specific interview/exam question pattern:
  // The FIFO has a single logical stream.
  // There is a single Write Pointer (WP) and a single Read Pointer (RP).
  // However, because of the clocks, we implement them as:
  // - `wp_a`: Pointer maintained in Domain A. Updated by A when A writes.
  // - `wp_b`: Pointer maintained in Domain B. Updated by B when B writes.
  // - `rp_a`: Pointer maintained in Domain A. Updated by A when A reads.
  // - `rp_b`: Pointer maintained in Domain B. Updated by B when B reads.
  //
  // Logic:
  // - If `a_dir` is high: A writes. `wp_a` increments. `rp_b` is the read pointer (maintained by B).
  //   The data is written at `wp_a`. Read at `rp_b`.
  //   Full/Empty: Compare `wp_a` (crossed to B) and `rp_b`.
  // - If `b_dir` is high: B writes. `wp_b` increments. `rp_a` is the read pointer (maintained by A).
  //   The data is written at `wp_b`. Read at `rp_a`.
  //   Full/Empty: Compare `wp_b` (crossed to A) and `rp_a`.
  //
  // Problem: What if both are writing? Or switching?
  // Assumption: Only one direction is active at a time.
  // Also, the pointers must be consistent.
  // If A writes, `wp_a` moves. `wp_b` should ideally stay same or be irrelevant.
  // If B writes, `wp_b` moves. `wp_a` should stay same.
  // But how do we ensure `wp_a` and `wp_b` don't drift apart if the direction switches?
  // If A writes, `wp_a` advances. Then B takes over. B must start reading from where A left off.
  // So `wp_b` must be initialized to `wp_a` (crossed) when B starts writing?
  // Or, simpler: The pointers are independent, but the "Active" pointer is the one used for memory access.
  // When `a_dir` is high, we use `wp_a` for write and `rp_b` for read.
  // When `b_dir` is high, we use `wp_b` for write and `rp_a` for read.
  // The Full/Empty status is calculated based on the active pair.
  //
  // Implementation Details:
  // - `wp_a` updates on `a_clk` if `a_dir` and `a_winc`.
  // - `wp_b` updates on `b_clk` if `b_dir` and `b_winc`.
  // - `rp_a` updates on `a_clk` if `a_rinc` and `!a_dir` (A is reading).
  // - `rp_b` updates on `b_clk` if `b_rinc` and `!b_dir` (B is reading).
  //
  // Wait, if `a_dir` is high, A is writing. B is reading.
  // A writes to `wp_a`. B reads from `rp_b`.
  // Full check in B: `wp_a` (sampled) == `rp_b`.
  // Empty check in B: `wp_a` (sampled) == `rp_b`.
  //
  // If `b_dir` is high, B is writing. A is reading.
  // B writes to `wp_b`. A reads from `rp_a`.
  // Full check in A: `wp_b` (sampled) == `rp_a`.
  // Empty check in A: `wp_b` (sampled) == `rp_a`.
  //
  // This requires 4 pointers.
  // Cross domain sampling:
  // - `wp_a` is sampled by B -> `wp_a_b`
  // - `rp_b` is sampled by A -> `rp_b_a`
  // - `wp_b` is sampled by A -> `wp_b_a`
  // - `rp_a` is sampled by B -> `rp_a_b`
  //
  // Full/Empty Logic:
  // - `a_full`: When A is reading (`!a_dir`), check `wp_b_a` vs `rp_a`.
  //   Wait, if A is reading, B is writing. So `wp_b` is the write pointer.
  //   `a_full` = (`wp_b_a` == `rp_a` + 1).
  //   `a_empty` = (`wp_b_a` == `rp_a`).
  // - `b_full`: When B is reading (`!b_dir`), check `wp_a_b` vs `rp_b`.
  //   `b_full` = (`wp_a_b` == `rp_b` + 1).
  //   `b_empty` = (`wp_a_b` == `rp_b`).
  //
  // What if both are writing? Undefined.
  // What if both are reading? Undefined (no one writes).
  // What if direction switches?
  // If A was writing (`wp_a` advanced), then B starts writing.
  // B needs to know the current `wp_a` to continue?
  // No, if B starts writing, it implies A stopped writing.
  // If A stopped writing, `wp_a` stopped advancing.
  // B starts writing, `wp_b` starts advancing.
  // But `wp_a` and `wp_b` are independent registers.
  // If A wrote 5 items, `wp_a` = 5.
  // B starts writing. `wp_b` starts at 0? Then B will overwrite A's data if not careful.
  // This implies `wp_b` must be initialized to the current `wp_a` (crossed) when B takes over?
  // Or, the design assumes that the "Write Pointer" is a single logical entity, but implemented as two registers that are kept in sync?
  // No, that's too complex for a standard FIFO.
  //
  // Alternative Interpretation:
  // The FIFO is always "owned" by one side for writing, and the other for reading.
  // The pointers are:
  // - `wp`: The physical write pointer.
  // - `rp`: The physical read pointer.
  // But we can't have a single register updated by two clocks.
  // So we have `wp_a` and `wp_b`.
  // We enforce that `wp_a` and `wp_b` are always equal (cross-domain).
  // How?
  // If `a_dir` is high, `wp_a` updates. `wp_b` is held constant (or updated by A's value).
  // If `b_dir` is high, `wp_b` updates. `wp_a` is held constant.
  // But how does the other side know the value?
  // `wp_b` is sampled by A. `wp_a` is sampled by B.
  // If `a_dir` is high, `wp_a` moves. `wp_b` stays.
  // B sees `wp_a` (via sampling). B knows the write position.
  // If `b_dir` becomes high, B starts writing.
  // B uses `wp_b`. But `wp_b` is stale (it was the old value).
  // This is a problem.
  //
  // Solution: The pointers are NOT independent.
  // There is ONE write pointer logic, but it is driven by the active direction.
  // There is ONE read pointer logic, but it is driven by the active direction.
  // But the registers are in different domains.
  //
  // Let's try a different approach often used in such problems:
  // The FIFO has a single Write Pointer (WP) and Read Pointer (RP).
  // WP is updated in the domain of the writer.
  // RP is updated in the domain of the reader.
  // We have two pointers for WP: `wp_a` (in A) and `wp_b` (in B).
  // We have two pointers for RP: `rp_a` (in A) and `rp_b` (in B).
  //
  // Constraint: `wp_a` and `wp_b` must represent the same logical value.
  // `rp_a` and `rp_b` must represent the same logical value.
  //
  // Update Logic:
  // - If `a_dir`: `wp_a` increments. `wp_b` is ignored (but must be kept valid for B to read? No, B reads from RP).
  //   Wait, if `a_dir`, A writes. B reads.
  //   B needs to know the write pointer to check Full.
  //   B samples `wp_a`. So `wp_a` must be valid.
  //   `wp_b` is not used for writing, but might be used for reading? No, B reads from `rp_b`.
  //   So `wp_b` is irrelevant when `a_dir` is high?
  //   But if `b_dir` becomes high later, B needs to write.
  //   B needs to start writing after the last item A wrote.
  //   So `wp_b` must be initialized to the current `wp_a` (crossed) when `b_dir` becomes high?
  //   This requires a handshake or a specific reset condition.
  //   The prompt says "start empty after reset".
  //   So initially `wp_a` = 0, `wp_b` = 0.
  //   If A writes, `wp_a` -> 1. `wp_b` stays 0.
  //   If B then takes over, B sees `wp_b` = 0. But data is at 1.
  //   B will overwrite data at 0. Collision!
  //
  // Conclusion: The pointers MUST be synchronized.
  // The only way to do this without a complex handshake is if the "Write Pointer" is a single logical value,
  // and we use the direction to select which domain updates it, BUT we must ensure the other domain sees the updated value.
  // This is impossible with simple registers unless we copy the value.
  //
  // Correct Design Pattern for this specific prompt:
  // The FIFO is implemented with TWO independent FIFOs? No.
  // The FIFO is implemented with a SINGLE Write Pointer and SINGLE Read Pointer, but the registers are duplicated.
  // We force the pointers to be equal by copying the value across domains when the direction changes?
  // No, that's too complex.
  //
  // Let's reconsider the "Pointers in both directions cross as acknowledged binary snapshots" hint.
  // This implies we don't need perfect synchronization of the pointers themselves, just the status.
  // But for a FIFO to work, the pointers must be consistent.
  //
  // Maybe the intended solution is:
  // `wp_a` and `wp_b` are independent.
  // `rp_a` and `rp_b` are independent.
  // When `a_dir` is high:
  //   A writes to `wp_a`. B reads from `rp_b`.
  //   Full/Empty is checked by B using `wp_a` (sampled) and `rp_b`.
  //   A does not check Full/Empty (it's the writer).
  // When `b_dir` is high:
  //   B writes to `wp_b`. A reads from `rp_a`.
  //   Full/Empty is checked by A using `wp_b` (sampled) and `rp_a`.
  //   B does not check Full/Empty.
  //
  // The problem of pointer drift:
  // If A writes, `wp_a` advances. `wp_b` stays.
  // If B then writes, `wp_b` advances from 0.
  // This overwrites A's data.
  // UNLESS: The direction change implies a reset of the pointers? No.
  // UNLESS: The pointers are coupled such that `wp_b` is always equal to `wp_a` (crossed).
  // How?
  // If `a_dir` is high, `wp_a` updates. `wp_b` is updated by A's value (crossed to B).
  // If `b_dir` is high, `wp_b` updates. `wp_a` is updated by B's value (crossed to A).
  // This requires a feedback loop.
  //
  // Let's assume the standard solution for this specific problem statement (which appears in some FPGA design contexts):
  // We maintain two pointers for Write: `wp_a` and `wp_b`.
  // We maintain two pointers for Read: `rp_a` and `rp_b`.
  // We assume that the user ensures that only one side writes at a time, AND that when the direction switches,
  // the pointers are aligned.
  // BUT, the prompt says "start empty after reset".
  // If A writes, `wp_a` moves. `wp_b` stays.
  // If B writes, `wp_b` moves. `wp_a` stays.
  // This implies the FIFO is effectively two separate FIFOs that share the same memory space but have disjoint pointer ranges?
  // No, that's not a FIFO.
  //
  // Let's try the most logical interpretation that avoids pointer drift:
  // The FIFO has ONE Write Pointer (WP) and ONE Read Pointer (RP).
  // WP is updated in the domain of the writer.
  // RP is updated in the domain of the reader.
  // We have `wp_a` and `wp_b`.
  // We have `rp_a` and `rp_b`.
  // We enforce:
  // `wp_b` = `wp_a` (crossed to B) when `a_dir` is high.
  // `wp_a` = `wp_b` (crossed to A) when `b_dir` is high.
  // This creates a metastability issue if we try to update both simultaneously.
  //
  // Actually, there is a simpler way:
  // The pointers are independent, but the "Full/Empty" logic is local to the reader.
  // The writer just writes to its pointer.
  // The reader reads from its pointer.
  // The "Full" signal is generated by the reader based on the writer's pointer (crossed).
  // The "Empty" signal is generated by the reader based on the writer's pointer (crossed).
  //
  // The pointer drift issue:
  // If A writes, `wp_a` moves. `wp_b` stays.
  // If B reads, it uses `rp_b`. It checks `wp_a` (crossed).
  // If B then writes, it uses `wp_b`. It starts from 0.
  // This means B will overwrite A's data.
  // This implies that the FIFO CANNOT switch direction without resetting the pointers or clearing the FIFO.
  // OR, the pointers are coupled.
  //
  // Given the constraints and the "professional" requirement, I will implement the coupled pointer version.
  // We will use a single logical write pointer, but implemented as two registers that are kept in sync.
  // We will use a single logical read pointer, but implemented as two registers that are kept in sync.
  //
  // Logic:
  // - `wp_a` and `wp_b` are always kept equal (cross-domain).
  // - `rp_a` and `rp_b` are always kept equal (cross-domain).
  // - Update `wp_a` if `a_dir` and `a_winc`.
  // - Update `wp_b` if `b_dir` and `b_winc`.
  // - If `a_dir` is high, `wp_b` is updated by `wp_a` (crossed).
  // - If `b_dir` is high, `wp_a` is updated by `wp_b` (crossed).
  // - Same for `rp`.
  //
  // Wait, if `a_dir` is high, `wp_a` updates. `wp_b` is updated by `wp_a`.
  // If `b_dir` becomes high, `wp_b` updates. `wp_a` is updated by `wp_b`.
  // This works!
  //
  // Implementation:
  // `wp_a` updates on `a_clk` if `a_dir` and `a_winc`.
  // `wp_b` updates on `b_clk` if `b_dir` and `b_winc`.
  // Additionally:
  // `wp_b` is updated on `b_clk` with `wp_a` (crossed) if `a_dir` is high?
  // No, if `a_dir` is high, `wp_a` is the master. `wp_b` should follow `wp_a`.
  // But `wp_b` is in domain B.
  // So:
  // `wp_b` <= `wp_a` (crossed) when `a_dir` is high.
  // `wp_a` <= `wp_b` (crossed) when `b_dir` is high.
  //
  // But what if both are high? Undefined.
  // What if neither is high? Pointers stay constant.
  //
  // Let's refine the update logic:
  // `wp_a` is updated by `a_winc` if `a_dir`.
  // `wp_b` is updated by `b_winc` if `b_dir`.
  // AND:
  // `wp_b` is updated by `wp_a` (crossed) if `a_dir` is high (to keep them in sync).
  // `wp_a` is updated by `wp_b` (crossed) if `b_dir` is high (to keep them in sync).
  //
  // This ensures that `wp_a` and `wp_b` are always equal (within one