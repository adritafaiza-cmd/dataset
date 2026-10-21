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
  reg [ASIZE-1:0] a_wptr, a_rptr;
  reg [ASIZE-1:0] b_wptr, b_rptr;

  // Cross-domain pointers (snapshots)
  reg [ASIZE-1:0] a_wptr_b, a_rptr_b;
  reg [ASIZE-1:0] b_wptr_a, b_rptr_a;

  // Status flags
  reg a_full_int, a_empty_int;
  reg b_full_int, b_empty_int;
  reg a_full_sync, a_empty_sync;
  reg b_full_sync, b_empty_sync;

  // Write enable signals for RAM
  reg o_ram_a_winc_int;
  reg o_ram_b_winc_int;

  // Read enable signals for RAM
  reg o_ram_a_rinc_int;
  reg o_ram_b_rinc_int;

  // Direction control
  reg a_dir_sync;
  reg b_dir_sync;

  // Full/Empty thresholds
  // Full: wptr == rptr + 1 (with wrap around logic handled by comparator)
  // Empty: wptr == rptr
  // Since we use external RAM, we manage pointers locally.
  // Full condition: (wptr + 1) == rptr (considering wrap)
  // Empty condition: wptr == rptr

  // Generate full/empty logic based on pointers
  // Note: In a circular buffer, full is typically (wptr + 1) == rptr
  // However, since we have separate write/read pointers per side, 
  // and they operate on the same physical memory but logically separate queues?
  // Wait, the problem says "Move words in either direction using the external RAM ports".
  // This implies a single shared memory space or two separate logical spaces?
  // "Bidirectional" usually means A->B and B->A.
  // If it's a single FIFO, we can't have A writing and B writing simultaneously to the same address without collision.
  // The standard interpretation for "Bidirectional FIFO" with external RAM is:
  // The RAM acts as the storage. Side A has its own write pointer and read pointer.
  // Side B has its own write pointer and read pointer.
  // BUT, they share the same physical RAM.
  // If A writes to addr X, B cannot write to addr X at the same time.
  // The prompt says "Move words in either direction".
  // This implies the RAM is the shared medium.
  // However, standard async FIFOs are unidirectional.
  // A bidirectional FIFO using a single RAM block typically requires:
  // 1. Two separate FIFOs (one for A->B, one for B->A) sharing the same RAM? No, that's inefficient.
  // 2. A single FIFO where direction is controlled. But then how do we have independent full/empty for both?
  // Let's re-read carefully: "Move words in either direction using the external RAM ports for storage."
  // "Preserve order, observe full/empty status... Pointers in both directions cross as acknowledged binary snapshots"
  // This strongly suggests a single logical FIFO structure where data flows A->B or B->A.
  // BUT, if it's a single FIFO, A and B cannot both be writing at the same time.
  // The interface has `a_winc` and `b_winc`.
  // If both are high, what happens?
  // Standard solution for bidirectional FIFO with shared RAM:
  // The RAM is treated as a single FIFO.
  // Side A owns the "head" and "tail" for A->B flow?
  // Actually, the most common architecture for "Bidirectional FIFO" in this context (like in high-speed SerDes) is:
  // Two independent FIFOs sharing the same physical memory bank? No, that's complex.
  // OR, it's a single FIFO where the "direction" bit determines who owns the write pointer.
  // But the interface has `a_dir` and `b_dir`.
  // Let's assume the standard interpretation for this specific prompt style (often found in FPGA challenges):
  // It is a SINGLE FIFO. 
  // A writes when `a_dir` is active (or `a_dir` indicates A is the sender).
  // B writes when `b_dir` is active.
  // They cannot write simultaneously.
  // However, the prompt asks for `a_full`, `a_empty`, `b_full`, `b_empty`.
  // If it's a single FIFO, `a_full` and `b_full` are the same state (the FIFO is full).
  // `a_empty` and `b_empty` are the same state.
  // Why would they be separate outputs?
  // Maybe the RAM is actually TWO separate FIFOs? 
  // "Move words in either direction using the external RAM ports".
  // If I have one RAM, I can't have two independent FIFOs unless they are disjoint in address space.
  // But the parameters are `DSIZE` and `ASIZE`. No size for direction.
  // Let's reconsider the "Bidirectional FIFO" definition in literature (e.g., Xilinx, Synopsys).
  // Often, a bidirectional FIFO is implemented as two unidirectional FIFOs back-to-back or sharing a buffer.
  // BUT, the prompt specifies "external dual-port RAM interface".
  // Dual-port RAM allows simultaneous read and write.
  // Scenario: A writes to Port A, B reads from Port A. B writes to Port B, A reads from Port B.
  // This creates TWO FIFOs: FIFO_AB (A->B) and FIFO_BA (B->A).
  // They share the same physical RAM chip, but use different address ranges or the same address space with different pointers?
  // If they share the same address space, they collide.
  // If they use different address ranges, we need to know the split.
  // The prompt does NOT specify address splitting.
  // Alternative interpretation: The RAM is the storage for ONE FIFO.
  // The "Bidirectional" aspect means the FIFO can be used for A->B OR B->A, but not both at once?
  // But then why `a_winc` and `b_winc`?
  // Let's look at the "Pointers in both directions cross" part.
  // This implies two sets of pointers: (a_wptr, a_rptr) and (b_wptr, b_rptr).
  // If they are independent, they must be independent FIFOs.
  // How can two independent FIFOs share one RAM?
  // They must be mapped to different address spaces within the RAM.
  // BUT the prompt doesn't give parameters for the split.
  // Is it possible the prompt implies a SINGLE FIFO where the "direction" is just a label, and the pointers are shared?
  // If pointers are shared, `a_wptr` == `b_wptr` and `a_rptr` == `b_rptr`.
  // Then `a_full` == `b_full`.
  // Why separate outputs?
  // Maybe the "Bidirectional" means the FIFO can be read by A and written by B, OR read by B and written by A.
  // But the interface has `a_winc` and `b_winc`.
  // Let's assume the most robust interpretation for a "Bidirectional FIFO" with external RAM:
  // It is a SINGLE FIFO.
  // The "A" side controls the Write pointer when `a_dir` is asserted (or simply when A wants to write).
  // The "B" side controls the Write pointer when `b_dir` is asserted.
  // The Read pointer is controlled by the receiver.
  // Wait, if A writes and B reads, then A controls W, B controls R.
  // If B writes and A reads, then B controls W, A controls R.
  // In this case, there is only ONE Write Pointer and ONE Read Pointer for the whole FIFO.
  // But the interface has `a_wptr` (implied by `a_winc`) and `b_wptr` (implied by `b_winc`).
  // And `a_rptr` (implied by `a_rinc`) and `b_rptr` (implied by `b_rinc`).
  // This implies 4 pointers.
  // This confirms the "Two Independent FIFOs" theory.
  // How do they share RAM?
  // They must be mapped to different halves of the RAM?
  // Or, perhaps the "external RAM" is just a black box, and we are generating the signals to drive it.
  // If we assume the RAM is large enough to hold both, we need to define the address mapping.
  // Since no mapping is provided, maybe the RAM is actually TWO separate memory blocks?
  // No, "external dual-port RAM" usually implies one chip.
  // Let's look at the "Pointers in both directions cross" sentence again.
  // "Pointers in both directions cross as acknowledged binary snapshots".
  // This is standard async FIFO terminology.
  // Hypothesis: The design is a SINGLE FIFO.
  // The "A" side is the transmitter for A->B. The "B" side is the transmitter for B->A.
  // But they cannot transmit simultaneously.
  // The `a_dir` and `b_dir` inputs might be used to arbitrate?
  // Or, more likely, the prompt describes a FIFO where:
  // - A writes to the FIFO (A->B direction).
  // - B reads from the FIFO.
  // - B writes to the FIFO (B->A direction).
  // - A reads from the FIFO.
  // This is a SINGLE FIFO.
  // The pointers are:
  // - W_ptr: Controlled by whoever is writing (A or B).
  // - R_ptr: Controlled by whoever is reading (A or B).
  // But the interface has `a_winc`, `b_winc`, `a_rinc`, `b_rinc`.
  // This implies A can write AND read? And B can write AND read?
  // If A writes and B reads, W_ptr moves on A_clk, R_ptr moves on B_clk.
  // If B writes and A reads, W_ptr moves on B_clk, R_ptr moves on A_clk.
  // This is the standard "Bidirectional FIFO" (e.g., in PCIe or Ethernet MACs).
  // In this case, there is only ONE W_ptr and ONE R_ptr for the entire FIFO.
  // Why does the interface have `a_winc` and `b_winc`?
  // Because the write enable is gated by `a_dir` or `b_dir`?
  // If `a_dir` is high, A writes. If `b_dir` is high, B writes.
  // What if both are high? Arbitration needed? Or error?
  // What if neither is high? No write.
  // Similarly for read: `a_rinc` and `b_rinc`.
  // If `a_rinc` is high, A reads. If `b_rinc` is high, B reads.
  // This creates a SINGLE FIFO with:
  // - Write pointer updated by A (if `a_dir`) or B (if `b_dir`).
  // - Read pointer updated by A (if `a_rinc`) or B (if `b_rinc`).
  // BUT, the pointers must be synchronized across domains.
  // The prompt says: "Pointers in both directions cross as acknowledged binary snapshots".
  // This usually refers to the cross-domain pointer synchronization (e.g., A's write pointer is sent to B).
  // If it's a single FIFO, there is only one W_ptr and one R_ptr.
  // So A needs to know the W_ptr (to check full) and R_ptr (to check empty).
  // B needs to know the W_ptr and R_ptr.
  // So we need:
  // - W_ptr (local to write domain)
  // - R_ptr (local to read domain)
  // - W_ptr_sync (sent to read domain)
  // - R_ptr_sync (sent to write domain)
  // But the interface has `a_winc` and `b_winc`.
  // This implies the write pointer might be maintained separately for A and B?
  // No, that would be two FIFOs.
  // Let's reconsider the "Two Independent FIFOs" hypothesis.
  // Maybe the RAM is used as two separate FIFOs: FIFO_AB and FIFO_BA.
  // FIFO_AB: A writes, B reads.
  // FIFO_BA: B writes, A reads.
  // They share the same RAM chip.
  // How? By using different address ranges.
  // But the prompt doesn't specify the ranges.
  // Is it possible the RAM is just a generic storage and we treat it as two logical FIFOs?
  // If so, we need to define the address mapping.
  // Common practice: Use the lower half for A->B and upper half for B->A?
  // Or, since `ASIZE` is given, maybe the total size is `2^ASIZE`.
  // If we assume the RAM is large enough, we can split it.
  // BUT, without explicit parameters for the split, this is ambiguous.
  // Let's look at the "Pointers in both directions cross" again.
  // If it's two FIFOs:
  // FIFO_AB: A_wptr, A_rptr.
  // FIFO_BA: B_wptr, B_rptr.
  // A needs to know FIFO_AB status (full/empty) and FIFO_BA status (full/empty)?
  // No, A only cares about FIFO_BA (what B sent to A).
  // B only cares about FIFO_AB (what A sent to B).
  // So A needs: FIFO_AB_R_ptr (to read from B? No, A reads from FIFO_BA).
  // A writes to FIFO_AB. A reads from FIFO_BA.
  // B writes to FIFO_BA. B reads from FIFO_AB.
  // So:
  // - A needs FIFO_AB_W_ptr (to check full before writing) and FIFO_BA_R_ptr (to check empty before reading).
  // - B needs FIFO_AB_R_ptr (to check full before reading) and FIFO_BA_W_ptr (to check full before writing).
  // This requires 4 pointers total:
  // 1. FIFO_AB_W_ptr (controlled by A)
  // 2. FIFO_AB_R_ptr (controlled by B)
  // 3. FIFO_BA_W_ptr (controlled by B)
  // 4. FIFO_BA_R_ptr (controlled by A)
  // This matches the interface perfectly!
  // `a_winc` -> increments FIFO_AB_W_ptr.
  // `b_rinc` -> increments FIFO_AB_R_ptr.
  // `b_winc` -> increments FIFO_BA_W_ptr.
  // `a_rinc` -> increments FIFO_BA_R_ptr.
  // And the RAM must support this.
  // How to map addresses?
  // We need to generate `o_ram_a_addr` and `o_ram_b_addr`.
  // Since the prompt doesn't specify the split, I will assume a simple split:
  // FIFO_AB uses addresses [0 : 2^(ASIZE-1)-1].
  // FIFO_BA uses addresses [2^(ASIZE-1) : 2^ASIZE-1].
  // Wait, `ASIZE` is the address size. Total size = 2^ASIZE.
  // If we split, each FIFO gets 2^(ASIZE-1) depth.
  // But the parameters don't specify the depth of each FIFO.
  // Is it possible the RAM is just ONE FIFO, and the "bidirectional" is just a naming convention for the ports?
  // No, the "Two Independent FIFOs" model fits the 4-pointer requirement best.
  // Let's assume the RAM is used as two logical FIFOs.
  // To make it work without explicit split parameters, I will assume the user intends for the RAM to be treated as two separate FIFOs, and I will implement the address generation logic to split the space.
  // However, there is a risk: if the user expects a single FIFO, this will fail.
  // Let's re-read: "Move words in either direction using the external RAM ports for storage."
  // "Preserve order, observe full/empty status and the fall-through option".
  // "Pointers in both directions cross as acknowledged binary snapshots".
  // This phrasing "Pointers in both directions" strongly supports the Two FIFOs model.
  // Direction 1: A->B (FIFO_AB). Pointers: A_W, B_R.
  // Direction 2: B->A (FIFO_BA). Pointers: B_W, A_R.
  // Address Mapping:
  // Since no split is given, I will assume the RAM is large enough and we use the lower half for A->B and upper half for B->A.
  // Wait, if `ASIZE` is 4, total 16 words. Half is 8.
  // Is it possible the RAM is just one FIFO, and the "bidirectional" means the FIFO can be used for A->B OR B->A, but not both?
  // If so, `a_winc` and `b_winc` would be mutually exclusive.
  // But the prompt doesn't say they are mutually exclusive.
  // Let's go with the Two FIFOs model. It's the only one that makes sense with 4 independent pointer increments.
  // Address Strategy:
  // FIFO_AB (A->B): Base address 0.
  // FIFO_BA (B->A): Base address 2^(ASIZE-1).
  // This assumes the RAM is exactly 2x the size of one FIFO.
  // But `ASIZE` is the parameter.
  // If the user provides a RAM of size `2^ASIZE`, and we split it, each FIFO has depth `2^(ASIZE-1)`.
  // This seems like a reasonable assumption for a "Bidirectional FIFO" with a single RAM block.
  // However, there is another possibility: The RAM is just a generic storage, and we don't care about the physical split, we just manage the logical pointers.
  // But we need to generate `o_ram_a_addr`.
  // I will implement the split:
  // If direction is A->B (implied by `a_winc` active?), use lower half.
  // If direction is B->A (implied by `b_winc` active?), use upper half.
  // But what if both are active?
  // The prompt says "Move words in either direction".
  // I will assume simultaneous operation is allowed (Two FIFOs).
  // Address calculation:
  // For A->B (Write): Addr = a_wptr. (Range 0 to 2^(ASIZE-1)-1)
  // For B->A (Write): Addr = b_wptr + 2^(ASIZE-1). (Range 2^(ASIZE-1) to 2^ASIZE-1)
  // For A->B (Read): Addr = b_rptr. (Range 0 to 2^(ASIZE-1)-1)
  // For B->A (Read): Addr = a_rptr + 2^(ASIZE-1). (Range 2^(ASIZE-1) to 2^ASIZE-1)
  // Wait, the read pointers are controlled by the receiver.
  // A reads from B->A. So A controls the read pointer for the B->A FIFO.
  // B reads from A->B. So B controls the read pointer for the A->B FIFO.
  // So:
  // - A_W_ptr controls Write for FIFO_AB.
  // - B_R_ptr controls Read for FIFO_AB.
  // - B_W_ptr controls Write for FIFO_BA.
  // - A_R_ptr controls Read for FIFO_BA.
  // This matches the interface:
  // `a_winc` -> A_W_ptr
  // `b_rinc` -> B_R_ptr
  // `b_winc` -> B_W_ptr
  // `a_rinc` -> A_R_ptr
  // Perfect.
  // Now, Full/Empty logic:
  // FIFO_AB Full: A_W_ptr == B_R_ptr + 1 (with wrap).
  // FIFO_AB Empty: A_W_ptr == B_R_ptr.
  // FIFO_BA Full: B_W_ptr == A_R_ptr + 1 (with wrap).
  // FIFO_BA Empty: B_W_ptr == A_R_ptr.
  // Cross-domain synchronization:
  // A needs to know FIFO_AB status (Full/Empty) to control `a_winc`?
  // No, A controls `a_winc`. A needs to know if FIFO_AB is full.
  // FIFO_AB Full is determined by A_W_ptr and B_R_ptr.
  // A knows A_W_ptr. A needs B_R_ptr (synced to A_clk).
  // So we need to send B_R_ptr to A.
  // Similarly, B needs A_W_ptr (synced to B_clk) to know if FIFO_AB is full.
  // And B needs to know FIFO_BA status (Full/Empty).
  // FIFO_BA Full is determined by B_W_ptr and A_R_ptr.
  // B knows B_W_ptr. B needs A_R_ptr (synced to B_clk).
  // So we need to send A_R_ptr to B.
  // Summary of Cross-Domain Signals:
  // 1. A needs B_R_ptr (for FIFO_AB Full check).
  // 2. B needs A_W_ptr (for FIFO_AB Full check).
  // 3. B needs A_R_ptr (for FIFO_BA Full check).
  // 4. A needs B_W_ptr (for FIFO_BA Full check).
  // Wait, do we need Empty checks?
  // Yes, for "fall-through" and proper operation.
  // But typically, Full is the critical one for write enable.
  // Empty is critical for read enable.
  // So:
  // A needs B_R_ptr (to check FIFO_AB Full) and B_W_ptr (to check FIFO_BA Empty).
  // B needs A_W_ptr (to check FIFO_AB Empty) and A_R_ptr (to check FIFO_BA Full).
  // Wait, let's re-verify:
  // FIFO_AB: A writes, B reads.
  // A needs to know if FIFO_AB is Full. Full = A_W_ptr == B_R_ptr + 1.
  // A knows A_W_ptr. Needs B_R_ptr (synced to A).
  // B needs to know if FIFO_AB is Empty. Empty = A_W_ptr == B_R_ptr.
  // B knows B_R_ptr. Needs A_W_ptr (synced to B).
  // FIFO_BA: B writes, A reads.
  // B needs to know if FIFO_BA is Full. Full = B_W_ptr == A_R_ptr + 1.
  // B knows B_W_ptr. Needs A_R_ptr (synced to B).
  // A needs to know if FIFO_BA is Empty. Empty = B_W_ptr == A_R_ptr.
  // A knows A_R_ptr. Needs B_W_ptr (synced to A).
  // So we need 4 cross-domain pointer transfers:
  // 1. B_R_ptr -> A (for FIFO_AB Full)
  // 2. A_W_ptr -> B (for FIFO_AB Empty)
  // 3. A_R_ptr -> B (for FIFO_BA Full)
  // 4. B_W_ptr -> A (for FIFO_BA Empty)
  // This is a lot of cross-domain traffic.
  // Is there a simpler interpretation?
  // Maybe the "Bidirectional FIFO" is a SINGLE FIFO, and the "direction" is just a label for the ports?
  // If it's a single FIFO:
  // W_ptr is shared. R_ptr is shared.
  // A writes -> increments W_ptr.
  // B writes -> increments W_ptr.
  // A reads -> increments R_ptr.
  // B reads -> increments R_ptr.
  // This would require arbitration on W_ptr and R_ptr.
  // But the interface has `a_winc` and `b_winc`.
  // If both are high, who wins?
  // This suggests the Two FIFOs model is correct.
  // Let's proceed with the Two FIFOs model.
  // Address Split:
  // FIFO_AB (A->B): Addresses 0 to 2^(ASIZE-1)-1.
  // FIFO_BA (B->A): Addresses 2^(ASIZE-1) to 2^ASIZE-1.
  // We need to generate the address based on the pointer.
  // For FIFO_AB: Addr = Pointer.
  // For FIFO_BA: Addr = Pointer + 2^(ASIZE-1).
  // Wait, the RAM is dual-port.
  // Port A (for A->B):
  // - Write: Addr = A_W_ptr. Data = A_Wdata. Inc = A_Winc.
  // - Read: Addr = B_R_ptr. Data = i_ram_a_rdata. Inc = B_Rinc.
  // Port B (for B->A):
  // - Write: Addr = B_W_ptr + Offset. Data = B_Wdata. Inc = B_Winc.
  // - Read: Addr = A_R_ptr + Offset. Data = i_ram_b_rdata. Inc = A_Rinc.
  // Offset = 2^(ASIZE-1).
  // Wait, the RAM has two ports: Port A and Port B.
  // We can assign:
  // Port A -> FIFO_AB (A->B).
  // Port B -> FIFO_BA (B->A).
  // This is efficient.
  // Port A (A->B):
  // - Write Enable: `o_ram_a_winc` = `a_winc`.
  // - Write Addr: `o_ram_a_addr` = `a_wptr`.
  // - Write Data: `o_ram_a_wdata` = `a_wdata`.
  // - Read Enable: `o_ram_a_rinc` = `b_rinc`.
  // - Read Addr: `o_ram_a_addr` = `b_rptr`. (Wait, address must be valid for Port A).
  // - Read Data: `i_ram_a_rdata`.
  // Port B (B->A):
  // - Write Enable: `o_ram_b_winc` = `b_winc`.
  // - Write Addr: `o_ram_b_addr` = `b_wptr` + Offset.
  // - Write Data: `o_ram_b_wdata` = `b_wdata`.
  // - Read Enable: `o_ram_b_rinc` = `a_rinc`.
  // - Read Addr: `o_ram_b_addr` = `a_rptr` + Offset.
  // - Read Data: `i_ram_b_rdata`.
  // This setup works perfectly.
  // Full/Empty Logic:
  // FIFO_AB (Port A):
  // - Full: `a_wptr` == `b_rptr` + 1 (with wrap).
  // - Empty: `a_wptr` == `b_rptr`.
  // FIFO_BA (Port B):
  // - Full: `b_wptr` == `a_rptr` + 1 (with wrap).
  // - Empty: `b_wptr` == `a_rptr`.
  // Cross-Domain Pointers:
  // We need to send `b_rptr` to A (for FIFO_AB Full check).
  // We need to send `a_wptr` to B (for FIFO_AB Empty check).
  // We need to send `a_rptr` to B (for FIFO_BA Full check).
  // We need to send `b_wptr` to A (for FIFO_BA Empty check).
  // Wait, do we need Empty checks?
  // The prompt says "observe full/empty status".
  // So yes.
  // Synchronization:
  // We need to synchronize these pointers across clock domains.
  // Since `a_clk` and `b_clk` are independent, we use a standard 2-stage synchronizer.
  // However, the pointers are updated on their respective clocks.
  // `b_rptr` is updated on `b_clk`. A needs to see it on `a_clk`.
  // `a_wptr` is updated on `a_clk`. B needs to see it on `b_clk`.
  // This is standard.
  // One detail: "Pointers in both directions cross as acknowledged binary snapshots".
  // This implies we just send the binary value.
  // Full/Empty flags:
  // `a_full`: FIFO_AB Full.
  // `a_empty`: FIFO_AB Empty.
  // `b_full`: FIFO_BA Full.
  // `b_empty`: FIFO_BA Empty.
  // `a_afull`: Asynchronous Full (from B's perspective? Or just the raw flag?).
  // The prompt says "a_afull", "a_aempty".
  // Usually, `_afull` means "Asynchronous Full" (i.e., the flag seen by the other domain).
  // Or it means "Full" as seen by the local domain?
  // Standard naming:
  // `full`: Synchronous full (local domain).
  // `afull`: Asynchronous full (crossed domain).
  // But in a bidirectional FIFO, each side has its own "local" full/empty.
  // For A:
  // - Local Full: FIFO_AB Full (A knows A_W_ptr and B_R_ptr_synced).
  // - Local Empty: FIFO_AB Empty.
  // - Remote Full: FIFO_BA Full (B knows B_W_ptr and A_R_ptr_synced).
  // - Remote Empty: FIFO_BA Empty.
  // Wait, the outputs are `a_full`, `a_afull`, `a_empty`, `a_aempty`.
  // This suggests 4 flags for A.
  // `a_full`: FIFO_AB Full (A's write side).
  // `a_empty`: FIFO_AB Empty (A's write side).
  // `a_afull`: FIFO_BA Full (A's read side, but seen asynchronously?).
  // `a_aempty`: FIFO_BA Empty (A's read side).
  // Actually, the standard naming in many FIFOs is:
  // `full`: Synchronous full (for local write enable).
  // `afull`: Asynchronous full (for cross-domain check).
  // But here, A has two FIFOs.
  // Let's assume:
  // `a_full`: FIFO_AB Full (A's write pointer vs B's read pointer).
  // `a_empty`: FIFO_AB Empty.
  // `a_afull`: FIFO_BA Full (B's write pointer vs A's read pointer).
  // `a_aempty`: FIFO_BA Empty.
  // Wait, why `a_afull`?
  // Maybe `a_full` is the synchronous version (A sees it directly), and `a_afull` is the asynchronous version (B sees it)?
  // No, the outputs are from the module.
  // Let's assume:
  // `a_full`: FIFO_AB Full (A's perspective).
  // `a_empty`: FIFO_AB Empty.
  // `a_afull`: FIFO_BA Full (A's perspective, but maybe this is the flag that A uses to know when B is full?).
  // Actually, let's look at the standard "Bidirectional FIFO" interface.
  // Often, `full` and `empty` are for the write side, and `afull` and `aempty` are for the read side (asynchronous).
  // But here we have two directions.
  // Let's assume:
  // `a_full`: FIFO_AB Full (A writes, B reads).
  // `a_empty`: FIFO_AB Empty.
  // `a_afull`: FIFO_BA Full (B writes, A reads).
  // `a_aempty`: FIFO_BA Empty.
  // And similarly for B.
  // This makes sense. A needs to know if FIFO_AB is full (to stop writing) and if FIFO_BA is full (to know B is full, maybe for flow control?).
  // Wait, if A reads from FIFO_BA, A needs to know if FIFO_BA is empty (to stop reading).
  // So `a_aempty` is crucial for A's read operation.
  // `a_afull` might be used by B to know if A is full? No, B knows FIFO_BA full from its own pointers.
  // Maybe `a_afull` is the flag that A sends to B?
  // No, the outputs are `a_full`, `a_afull`, etc.
  // Let's assume the naming convention:
  // `a_full`: FIFO_AB Full (A's write side).
  // `a_empty`: FIFO_AB Empty.
  // `a_afull`: FIFO_BA Full (A's read side, but "asynchronous" because it's determined by B's pointer).
  // `a_aempty`: FIFO_BA Empty.
  // This seems consistent.
  // Implementation details:
  // 1. Define pointers.
  // 2. Define address offset.
  // 3. Implement cross-domain pointer synchronization.
  // 4. Implement Full/Empty logic.
  // 5. Implement address generation.
  // 6. Implement data routing.
  // 7. Handle resets.

  // Constants
  localparam ADDR_OFFSET = 1 << (ASIZE - 1);

  // Pointers
  reg [ASIZE-1:0] a_wptr, a_rptr;
  reg [ASIZE-1:0] b_wptr, b_rptr;

  // Cross-domain pointers (snapshots)
  reg [ASIZE-1:0] a_wptr_b, a_rptr_b;
  reg [ASIZE-1:0] b_wptr_a, b_rptr_a;

  // Synchronizers for cross-domain pointers
  // a_wptr -> b (for b to check FIFO_AB Empty)
  // a_rptr -> b (for b to check FIFO_BA Full)
  // b_wptr -> a (for a to check FIFO_BA Empty