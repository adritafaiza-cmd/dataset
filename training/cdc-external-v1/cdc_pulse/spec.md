Implement the SystemVerilog module `cdc_pulse`.

Implement cdc pulse using the interface and behavioral contract below.

Functional contract and interface notes:

cdc_pulse.sv — Pulse Synchronizer
Two modes selectable via MODE parameter:
MODE=0 (TOGGLE): Toggle-based — i_src_pulse toggles a FF, level crosses via
cdc_bit, edge detect in dst produces single-cycle pulse.
Lightweight, but back-to-back pulses must be spaced apart.
MODE=1 (COUNTER): Counter-based — delegates to cdc_counter which owns the
pulse count in the src domain and synchronizes it to dst.
dst generates pulses to match. Guarantees N-in = N-out.

Required clock and reset behavior:

- Clock ports: i_src_clk, i_dst_clk.
- Reset ports: i_src_rst_n, i_dst_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_pulse_toggle: cdc_pulse_toggle #( .SYNC_STAGES (SYNC_STAGES) ) u_impl ( .i_src_clk (i_src_clk), .i_src_rst_n (i_src_rst_n), .i_src_pulse (i_src_pulse), .i_dst_clk (i_dst_clk), .i_dst_rst_n (i_dst_rst_n), .o_dst_pulse (o_dst_pulse) );
- cdc_pulse_counter: cdc_pulse_counter #( .SYNC_STAGES (SYNC_STAGES), .CTR_WIDTH (CTR_WIDTH) ) u_impl ( .i_src_clk (i_src_clk), .i_src_rst_n (i_src_rst_n), .i_src_pulse (i_src_pulse), .i_dst_clk (i_dst_clk), .i_dst_rst_n (i_dst_rst_n), .o_dst_pulse (o_dst_pulse) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_pulse #(
    parameter int SYNC_STAGES = 2,
    parameter int MODE        = 0,       // 0 = toggle, 1 = counter
    parameter int CTR_WIDTH   = 4        // Counter width for MODE=1
) (
    input  logic i_src_clk,
    input  logic i_src_rst_n,
    input  logic i_src_pulse,
    input  logic i_dst_clk,
    input  logic i_dst_rst_n,
    output logic o_dst_pulse
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
