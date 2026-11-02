Implement the SystemVerilog module `cdc_sync2`.

//   2-stage flip-flop synchronizer for single-bit clock domain crossing (CDC).

Functional contract and interface notes:

Module  : cdc_sync2
Language: SystemVerilog
Description:
2-stage flip-flop synchronizer for single-bit clock domain crossing (CDC).
CDC Principle:
When a signal crosses clock domains, the capturing flip-flop may enter a
metastable state. By chaining two flip-flops in the destination domain,
the probability that metastability propagates to downstream logic is reduced
exponentially (by roughly e^(Tresolution/tau) per stage). For most designs
below a few hundred MHz, 2 stages provide sufficient MTBF.
Safety:
- Safe ONLY for single-bit signals.
- The input must be quasi-static (stable for at least one destination clock
cycle) or use cdc_pulse_sync / cdc_toggle_sync for pulsed signals.
- Multi-bit signals require special handling (Gray code or handshake).
- Apply ASYNC_REG / keep_hierarchy constraints in the synthesis tool to
prevent the optimizer from merging or moving synchronizer FFs.
Use Cases:
- Control/status bits crossing clock domains
- Enable, valid, or flag signals
- Building block for cdc_pulse_sync, cdc_toggle_sync, cdc_reset_sync
Limitations:
- 2-cycle latency in the destination domain
- Not suitable for fast-changing signals or multi-bit buses
Timing Assumptions:
- The signal must remain stable for at least 2 destination clock cycles
between transitions (quasi-static) unless a toggle/pulse synchronizer
is used upstream.
Example Instantiation:
cdc_sync2 #(.RESET_VAL(1'b0)) u_sync (
.clk_dst   (clk_dst),
.rst_dst_n (rst_dst_n),
.data_src  (flag_src),
.data_dst  (flag_dst)
);

Required clock and reset behavior:

- Clock ports: clk_dst.
- Reset ports: rst_dst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_sync2 #(
    parameter bit RESET_VAL = 1'b0  // Reset value for synchronizer flip-flops
) (
    input  logic clk_dst,    // Destination domain clock
    input  logic rst_dst_n,  // Destination domain asynchronous reset (active low)
    input  logic data_src,   // Single-bit input from source clock domain
    output logic data_dst    // Single-bit output synchronized to destination domain
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
