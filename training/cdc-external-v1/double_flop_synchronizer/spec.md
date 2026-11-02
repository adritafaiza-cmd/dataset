Implement the SystemVerilog module `double_flop_synchronizer`.

Synchronize a single asynchronous level with two serial destination-clock registers, respecting enable and reset.

Functional contract and interface notes:

Use this module only for clock domain crossing or for creating a synchronous
input from an asynchronous input signal (into a chip). For regular double delays
via a register, `double_delay_register.v` should be used.

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module double_flop_synchronizer #(
    parameter integer AT_POSEDGE_RST = 1
) (
    input clk,
    input rst,
    input enable,
    input in,
    output reg out
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
