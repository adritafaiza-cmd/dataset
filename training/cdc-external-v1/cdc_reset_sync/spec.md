Implement the SystemVerilog module `cdc_reset_sync`.

//   Reset synchronizer with asynchronous assertion and synchronous deassertion.

Functional contract and interface notes:

Module  : cdc_reset_sync
Language: SystemVerilog
Description:
Reset synchronizer with asynchronous assertion and synchronous deassertion.
Generates a clean, glitch-free reset in a target clock domain from an
asynchronous reset source.
CDC Principle (Async Assert / Sync Deassert):
This is a well-established technique for distributing resets across clock
domains safely:
Assertion (immediate):
When rst_async_n goes low, the output rst_sync_n is immediately driven
low (asynchronous), ensuring that all downstream flip-flops enter reset
Deassertion (synchronized):
When rst_async_n goes high, the release is NOT immediate. Instead, it
must propagate through a chain of SYNC_STAGES flip-flops clocked by
clk. All flip-flops in the chain are preset to '1' asynchronously and
only release rst_sync_n after SYNC_STAGES clean clock edges, ensuring
the local reset deasserts synchronously with clk. This prevents
metastability on the reset release edge.
Safety:
- Async assert ensures no combinatorial reset propagation delay.
- Sync deassert eliminates metastability when reset is released.
- All flip-flops driven by rst_sync_n will exit reset at the same clock edge.
Use Cases:
- Generating domain-local resets from a global asynchronous reset source
- Power-on reset distribution to multiple clock domains
- Generating reset for logic after a PLL lock signal
Limitations:
- Clock must be running during reset deassertion for synchronous release.
- SYNC_STAGES >= 2 is required (default 2).
- The metastability window is very small for the assertion path (since the
reset release goes through synchronizer FFs), but assertion itself is
asynchronous and purely combinatorial.
Timing Assumptions:
- rst_async_n is assumed to meet hold/recovery time on the clock edge it
is released on. If not, the SYNC_STAGES chain provides sufficient
resolution time.
Example Instantiation:
cdc_reset_sync #(.SYNC_STAGES(2)) u_rst_sync (
.clk         (clk),
.rst_async_n (por_rst_n),
.rst_sync_n  (local_rst_n)
);

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst_async_n, rst_sync_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_reset_sync #(
    parameter int SYNC_STAGES = 2  // Number of synchronizer stages (>= 2)
) (
    input  logic clk,          // Target clock domain clock
    input  logic rst_async_n,  // Asynchronous reset input (active low)
    output logic rst_sync_n    // Synchronized reset output (active low)
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
