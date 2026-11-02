Implement the SystemVerilog module `cdc_handshake`.

Implement cdc handshake using the interface and behavioral contract below.

Functional contract and interface notes:

cdc_handshake.sv — Handshake-Based Bus Synchronizer
Four-phase toggle handshake for safe multi-bit data transfer across
clock domains. Data is held stable in a holding register while
req/ack toggles cross domains via cdc_bit.

Required clock and reset behavior:

- Clock ports: i_src_clk, i_dst_clk.
- Reset ports: i_src_rst_n, i_dst_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_bit: cdc_bit #( .SYNC_STAGES (SYNC_STAGES), .RESET_VALUE (1'b0) ) u_sync_ack ( .i_clk (i_src_clk), .i_rst_n (i_src_rst_n), .i_async_in (ack_toggle), .o_sync_out (ack_sync) );
- cdc_bit: cdc_bit #( .SYNC_STAGES (SYNC_STAGES), .RESET_VALUE (1'b0) ) u_sync_req ( .i_clk (i_dst_clk), .i_rst_n (i_dst_rst_n), .i_async_in (req_toggle), .o_sync_out (req_sync) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_handshake #(
    parameter int WIDTH       = 8,
    parameter int SYNC_STAGES = 2
) (
    // Source domain
    input  logic               i_src_clk,
    input  logic               i_src_rst_n,
    input  logic [WIDTH-1:0]   i_src_data,
    input  logic               i_src_valid,
    output logic               o_src_ready,
    // Destination domain
    input  logic               i_dst_clk,
    input  logic               i_dst_rst_n,
    output logic [WIDTH-1:0]   o_dst_data,
    output logic               o_dst_valid
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
