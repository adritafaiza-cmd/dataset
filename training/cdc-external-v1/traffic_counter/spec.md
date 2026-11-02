Implement the SystemVerilog module `traffic_counter`.

Router tap synchronizer + 32-bit wrapping counter bank

Functional contract and interface notes:

Module: traffic_counter
Purpose: Router tap synchronizer + 32-bit wrapping counter bank

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_synchronizer: cdc_synchronizer #(.WIDTH(4), .FLOP_COUNT(2)) u_rx_sync (.clk, .rst_n, .async_in(tap_rx_stb), .sync_out(rx_stb_sync));
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(4), .FLOP_COUNT(2)) u_tx_sync (.clk, .rst_n, .async_in(tap_tx_stb), .sync_out(tx_stb_sync));
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(4), .FLOP_COUNT(2)) u_local_inject_sync (.clk, .rst_n, .async_in(tap_local_inject_stb), .sync_out(local_inject_stb_sync));
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(4), .FLOP_COUNT(2)) u_local_consume_sync(.clk, .rst_n, .async_in(tap_local_consume_stb), .sync_out(local_consume_stb_sync));
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(32), .FLOP_COUNT(2)) u_occupancy_sync (.clk, .rst_n, .async_in(tap_occupancy), .sync_out(occupancy_sync));
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(1), .FLOP_COUNT(2)) u_stall_sync (.clk, .rst_n, .async_in(tap_stall_stb), .sync_out(stall_stb_sync));
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(1), .FLOP_COUNT(2)) u_parity_sync (.clk, .rst_n, .async_in(tap_parity_err_stb), .sync_out(parity_err_sync));
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(1), .FLOP_COUNT(2)) u_protocol_sync (.clk, .rst_n, .async_in(tap_protocol_err_stb), .sync_out(protocol_err_sync));
- cdc_synchronizer: cdc_synchronizer #(.WIDTH(1), .FLOP_COUNT(2)) u_overflow_sync (.clk, .rst_n, .async_in(tap_overflow_stb), .sync_out(overflow_stb_sync));

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module traffic_counter #(
    parameter int IBUF_DEPTH = 8
)(
    input  logic        clk,
    input  logic        rst_n,
    // --- router tap (source domain is the tile router / delta_clk)
    input  logic [3:0]  tap_rx_stb,
    input  logic [3:0]  tap_tx_stb,
    input  logic [3:0]  tap_local_inject_stb,
    input  logic [3:0]  tap_local_consume_stb,
    input  logic [31:0] tap_occupancy,
    input  logic        tap_stall_stb,
    input  logic        tap_parity_err_stb,
    input  logic        tap_protocol_err_stb,
    input  logic        tap_overflow_stb,
    // --- counter bank outputs (serv_clk domain)
    output logic [31:0] pkt_rx_count [4],
    output logic [31:0] pkt_tx_count [4],
    output logic [31:0] pkt_local_inject,
    output logic [31:0] pkt_local_consume,
    output logic [31:0] buffer_overflow_count,
    output logic [31:0] stall_cycles,
    output logic [7:0]  buffer_occupancy [4],
    // --- synchronized error pulses (one cycle in serv_clk)
    output logic        parity_err_pulse,
    output logic        protocol_err_pulse,
    output logic        overflow_err_pulse,
    // --- control
    input  logic        clear_stats
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
