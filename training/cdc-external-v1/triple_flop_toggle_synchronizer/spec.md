Implement the SystemVerilog module `triple_flop_toggle_synchronizer`.

Synchronize an asynchronous toggle and detect a change using a delayed synchronized sample to produce a destination-domain event.

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- double_flop_synchronizer: double_flop_synchronizer #( .AT_POSEDGE_RST(AT_POSEDGE_RST) ) double_flop_synchronizer_inst ( .clk(clk), .rst(rst), .enable(enable), .in(in), .out(in_sync) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module triple_flop_toggle_synchronizer #(
    parameter integer AT_POSEDGE_RST = 1
) (
    input clk,
    input rst,
    input enable,
    input  in,
    output out
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
