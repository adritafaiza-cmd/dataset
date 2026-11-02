Implement the SystemVerilog module `kestrel_core`.

Single-cycle RV32I core — PC register, decode truth table,

Functional contract and interface notes:

Module: kestrel_core
Purpose: Single-cycle RV32I core — PC register, decode truth table,
immediate generator, ALU, register file, writeback, next-PC mux,
halt, and first-class RVFI retire ports.
Task 7 adds the load/store datapath: naturally aligned byte,
half and word accesses in one cycle, byte-lane rotation within
the word.  A misaligned address halts (2026-10-20, owner: the
hardware cross-word retry sat on the register-write and PC-hold
path): cause 4 for a load, 5 for a store, the access is not
performed.  RISC-V permits either hardware or trap handling;
kestrel has no exception machinery, so like the other traps it
halts.  rv32ui-p-ma_data, which needs hardware support, now halts
on its first misaligned load.  RVFI follows riscv-formal's
RISCV_FORMAL_ALIGNED_MEM convention (word address, lane masks).
Task 8 adds the system layer.  Halt is a holding register:
any nonzero decode halt_cause latches halt, freezes the PC, and
stops retirement; the halting instruction retires as an RVFI
trap beat (rvfi_valid=1, rvfi_trap=1) and rvfi_valid stays low
thereafter.  FENCE/FENCE.I retire as NOPs; MRET falls through
to pc+4 (the riscv-tests p-env always points mepc at the next
instruction); the SYSTEM CSR class retires through a zero
writeback (kestrel has no CSR state — reads return zero, writes
drop), which lets the p-env preamble run; anything else in
SYSTEM or MISC-MEM is an illegal-instruction halt (cause 0xF).
Task 9 adds the instruction-address-misaligned halt.  RV32I
(IALIGN=32, no C extension) mandates a trap when taken control
flow — a taken branch, JAL, or JALR — targets an address that
is not 4-byte aligned, and rvfi.md requires that beat on RVFI.
Kestrel has no exception machinery, so like ecall/ebreak/
illegal it halts: cause 3 (HALT_IALIGN, encoding in rv32i_pkg)
from the halt holding register below, the beat retiring with
rvfi_trap=1, the rd writeback suppressed, and the PC frozen.
The riscv-formal insn_{beq,bne,blt,bge,bltu,bgeu,jal,jalr}
checks prove it.
Memory wait (2026-10-20, owner: a registered-read wrapper for
block RAM).  `mem_wait` high means the memories have not
answered this cycle: every piece of architectural state holds
(PC, regfile write, halt latch, retry bits, retire counter), RVFI
reports no retirement, and the combinational halt term is masked
(insn is not valid yet).  Tied low, the core is exactly the
single-cycle core above; kestrel_mem_bram drives it to put
synchronous-read memory behind the same ports.
Next-PC fetch port (2026-10-20).  `imem_addr_next` is the value
the PC register takes at the next edge (RESET_ADDR while in
reset).  A registered-read instruction memory addressed by it
presents the word at `pc` one clock later, so block RAM's own
output register stands in for an instruction register and the
execute cycle starts at the RAM output.

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
module kestrel_core #(
    parameter logic [31:0] RESET_ADDR = 32'h0000_0000
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        mem_wait,       // 1: memories not ready -- hold all state
    output logic [31:0] imem_addr,
    output logic [31:0] imem_addr_next, // PC after this edge (registered-read fetch)
    input  logic [31:0] imem_rdata,
    output logic        dmem_req,
    output logic [31:0] dmem_addr,
    input  logic [31:0] dmem_rdata,
    output logic [3:0]  dmem_wstrb,
    output logic [31:0] dmem_wdata,
    output logic        halt,
    output logic [3:0]  halt_cause,
    output logic        rvfi_valid,
    output logic [63:0] rvfi_order,
    output logic [31:0] rvfi_pc_rdata,
    output logic [31:0] rvfi_pc_wdata,
    output logic [31:0] rvfi_insn,
    output logic        rvfi_trap,
    output logic [4:0]  rvfi_rs1_addr,
    output logic [4:0]  rvfi_rs2_addr,
    output logic [31:0] rvfi_rs1_rdata,
    output logic [31:0] rvfi_rs2_rdata,
    output logic [4:0]  rvfi_rd_addr,
    output logic [31:0] rvfi_rd_wdata,
    output logic [31:0] rvfi_mem_addr,
    output logic [3:0]  rvfi_mem_rmask,
    output logic [3:0]  rvfi_mem_wmask,
    output logic [31:0] rvfi_mem_rdata,
    output logic [31:0] rvfi_mem_wdata
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
