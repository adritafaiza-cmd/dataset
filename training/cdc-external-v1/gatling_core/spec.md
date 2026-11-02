Implement the SystemVerilog module `gatling_core`.

Barrel RV32I core (gatling PRD 4).  One datapath -- the

Functional contract and interface notes:

Module: gatling_core
Purpose: Barrel RV32I core (gatling PRD 4).  One datapath -- the
common-rv32i decode, immediate generator and ALU, shared with
kestrel -- time-shared by NUM_HARTS hardware contexts (harts),
each with its own PC and register file, interleaved through a
four-stage F/D/X/W rotation.
The rotation.  A counter 0..NUM_HARTS-1 names the context in F;
the contexts in D, X and W are the three before it.  Every cycle
each stage holds a DIFFERENT context, so a context has exactly
one instruction in flight: its next fetch is NUM_HARTS cycles
after its last, by which time that instruction has written its
PC (end of X) and its register (end of W).  No hazard, no
forwarding, no branch penalty; every context retires one
instruction per NUM_HARTS-cycle window, and the core retires one
per clock with all contexts running.
NUM_HARTS (default 4, the tetrad) is a parameter of this module
and of gatling_regfile / gatling_mem_bram, which size their
context arrays from it.  It must be at least the pipeline depth
(4): fewer contexts than stages would put two instructions of
one context in flight and bring back the hazards.  More
contexts than stages is legal (a context then owns 1/NUM_HARTS
of the datapath).  The rotation counter wraps explicitly, so
NUM_HARTS need not be a power of two.
F  imem address = pc[ctx]                  (registered read)
D  insn = imem word; decode + immediates; register read issued
X  operands arrive; ALU, branch, next PC, halt; data access
issued; pc[ctx] written
W  load data arrives; align/extend; register write; RVFI beat
Every memory the barrel touches is a registered-read block RAM
whose latency is exactly one stage: fetch (F -> D), register read
(D -> X), load (X -> W).  There is no wait signal.
ISA and halt contract are kestrel's (PRD 3: same opcode map, same
trap/halt contract) and come from the same fubs: ecall, ebreak,
illegal, misaligned control-flow target and misaligned load/store
halt with rv32i_pkg's causes; FENCE/FENCE.I are NOPs; MRET
falls through; the SYSTEM CSR class reads zero.  Halts are
PER CONTEXT (PRD 7 item 4, context-lock, owner 2026-10-21): the
halting instruction retires as an RVFI trap beat, that context
stops fetching, and the other three keep running.  The Xcell
custom-0 opcode is not built yet, so it decodes as illegal and
locks its context the same way.
Context run control.  hart_run[c] = 0 holds context c at
RESET_ADDR with its halt cleared and kills any of its instructions
in flight; 1 lets it fetch.  The memory system drives it, one bit
per hart, so one context can be reloaded while the others run.
Context visibility is implicit (PRD 7 item 2, owner 2026-10-21):
software cannot tell the contexts apart.

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- reset_sync: reset_sync #( .N (3), .KEEP_ATTRS (1'b1), .IN_ACTIVE_LOW (1'b1), .OUT_ACTIVE_LOW(1'b1), .ASYNC_ASSERT (1'b1) ) u_reset_sync ( .clk (clk), .rst_n (rst_n), .sync_rst_n (w_aresetn) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module gatling_core #(
    parameter int          NUM_HARTS  = 4,                 // contexts; >= 4 (the pipeline depth)
    parameter logic [31:0] RESET_ADDR = 32'h0000_0000
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic [NUM_HARTS-1:0]         hart_run,       // per context: 1 = run, 0 = hold at RESET_ADDR
    // Instruction port: address in F, word expected in D (registered read)
    output logic [$clog2(NUM_HARTS)-1:0] imem_ctx,
    output logic [31:0]      imem_addr,
    input  logic [31:0]      imem_rdata,
    // Data port: request in X, read word expected in W (registered read)
    output logic             dmem_req,
    output logic [$clog2(NUM_HARTS)-1:0] dmem_ctx,
    output logic [31:0]      dmem_addr,
    input  logic [31:0]      dmem_rdata,
    output logic [3:0]       dmem_wstrb,
    output logic [31:0]      dmem_wdata,
    // Per-context halt state
    output logic [NUM_HARTS-1:0]         halted,
    output logic [NUM_HARTS-1:0][3:0]    halt_cause,     // [ctx]
    // RVFI: at most one retirement per cycle, from W; rvfi_ctx names the
    // context and rvfi_order counts that context's retirements.
    output logic             rvfi_valid,
    output logic [$clog2(NUM_HARTS)-1:0] rvfi_ctx,
    output logic [63:0]      rvfi_order,
    output logic [31:0]      rvfi_pc_rdata,
    output logic [31:0]      rvfi_pc_wdata,
    output logic [31:0]      rvfi_insn,
    output logic             rvfi_trap,
    output logic [4:0]       rvfi_rs1_addr,
    output logic [4:0]       rvfi_rs2_addr,
    output logic [31:0]      rvfi_rs1_rdata,
    output logic [31:0]      rvfi_rs2_rdata,
    output logic [4:0]       rvfi_rd_addr,
    output logic [31:0]      rvfi_rd_wdata,
    output logic [31:0]      rvfi_mem_addr,
    output logic [3:0]       rvfi_mem_rmask,
    output logic [3:0]       rvfi_mem_wmask,
    output logic [31:0]      rvfi_mem_rdata,
    output logic [31:0]      rvfi_mem_wdata
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
