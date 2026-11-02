Implement the SystemVerilog module `cdc_bit`.

Pass one asynchronous input through SYNC_STAGES destination-clock registers. Reset the entire pipeline to RESET_VALUE and expose only its final stage.

Functional contract and interface notes:

cdc_bit.sv — N-Stage Single-Bit Synchronizer
Fundamental CDC building block: shift register of SYNC_STAGES flip-flops
with ASYNC_REG attribute for proper FPGA placement.

Required clock and reset behavior:

- Clock ports: i_clk.
- Reset ports: i_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_bit #(
    parameter int   SYNC_STAGES = 2,
    parameter logic RESET_VALUE = 1'b0
) (
    input  logic i_clk,
    input  logic i_rst_n,
    input  logic i_async_in,
    output logic o_sync_out
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
