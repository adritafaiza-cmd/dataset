Implement the SystemVerilog module `cdc_sync3`.

//   3-stage flip-flop synchronizer for single-bit CDC. Provides higher MTBF

Functional contract and interface notes:

Module  : cdc_sync3
Language: SystemVerilog
Description:
3-stage flip-flop synchronizer for single-bit CDC. Provides higher MTBF
than the 2-stage synchronizer.
CDC Principle:
Same principle as cdc_sync2 but with a third synchronizer flip-flop.
Each additional stage reduces the metastability probability by roughly
e^(Tresolution/tau) relative to the previous stage. Use 3 stages when:
- Operating at high clock frequencies (>500 MHz), where the destination
clock period may not allow sufficient metastability resolution time
between the first and second FF.
- The application demands very high MTBF (e.g., safety-critical systems).
Safety:
- Safe ONLY for single-bit signals.
- Same input stability requirements as cdc_sync2.
- Apply ASYNC_REG / keep_hierarchy constraints in synthesis tools.
Use Cases:
- High-frequency designs (>500 MHz)
- Safety-critical applications requiring very high MTBF
- When 2-stage does not provide enough resolution time at the target frequency
Limitations:
- 3-cycle latency in the destination domain (one more cycle than cdc_sync2)
- Not suitable for fast-changing or multi-bit signals
Timing Assumptions:
- Destination clock period must be long enough for the first FF to resolve
metastability before its output is sampled by the second FF.
Example Instantiation:
cdc_sync3 #(.RESET_VAL(1'b0)) u_sync3 (
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
module cdc_sync3 #(
    parameter bit RESET_VAL = 1'b0  // Reset value for synchronizer flip-flops
) (
    input  logic clk_dst,    // Destination domain clock
    input  logic rst_dst_n,  // Destination domain asynchronous reset (active low)
    input  logic data_src,   // Single-bit input from source clock domain
    output logic data_dst    // Single-bit output synchronized to destination domain
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
