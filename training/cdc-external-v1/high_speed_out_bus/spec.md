Implement the SystemVerilog module `high_speed_out_bus`.

Synchronize the returning acknowledge into clk and control an outbound request/data exchange without issuing a new transfer before the preceding handshake is complete.

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- double_flop_synchronizer: double_flop_synchronizer double_flop_synchronizer_acknowledge ( .clk(clk), .rst(rst), .enable(1'b1), .in(acknowledge), .out(acknowledge_sync) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module high_speed_out_bus #(
    parameter integer HIGH_SPEED_OUT_PINS = 8,
    parameter integer SENT_COUNTER_BIT_WIDTH = 4
) (
    input clk,
    input rst,
    input in_idle,
    input sending,
    input will_stop_sending, // next_state != `SENDING
    input data_ready_for_sending,
    input [SENT_COUNTER_BIT_WIDTH-1:0] num_sends,
    input [HIGH_SPEED_OUT_PINS-1:0] in,
    output reg request,
    input acknowledge,
    output reg [HIGH_SPEED_OUT_PINS-1:0] out,
    output reg [SENT_COUNTER_BIT_WIDTH-1:0] sent_counter,
    output done_sending
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
