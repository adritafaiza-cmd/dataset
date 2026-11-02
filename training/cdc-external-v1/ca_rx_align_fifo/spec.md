Implement the SystemVerilog module `ca_rx_align_fifo`.

Implement ca rx align fifo using the interface and behavioral contract below.

Functional contract and interface notes:

Functional Descript: Channel Alignment IP, RX channel alignment FIFO

Required clock and reset behavior:

- Clock ports: lane_clk, com_clk.
- Reset ports: rst_lane_n, rst_com_n, soft_reset, soft_reset_lane.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- asyncfifo: asyncfifo #( .FIFO_WIDTH_WID (1), .FIFO_DEPTH_WID (8)) asyncfifo_soft_reset ( .rddata (soft_reset_lane), .rd_numfilled (), .wr_numempty (), .wr_full (), .rd_empty (reset_fifo_rd_empty), .wr_overflow_pulse (), .rd_underflow_pulse (), .clk_write (com_clk), .rst_write_n (rst_com_n), .clk_read (lane_clk), .rst_read_n (rst_lane_n), .wrdata (soft_reset), .write_push (1'b1), .read_pop (reset_fifo_rd_pop), .rd_soft_reset (1'b0), .wr_soft_reset (1'b0));
- asyncfifo: asyncfifo #( .FIFO_WIDTH_WID (FIFO_WIDTH_WID), .FIFO_DEPTH_WID (FIFO_DEPTH_WID)) asyncfifo_i ( .rddata (rx_dout[FIFO_WIDTH_WID-1:0]), .rd_numfilled (rd_numfilled[FIFO_ADDR_WID-1:0]), .wr_numempty (wr_numempty[FIFO_ADDR_WID-1:0]), .wr_full (wr_full), .rd_empty (rd_empty), .wr_overflow_pulse (wr_overflow_pulse), .rd_underflow_pulse (rd_underflow_pulse), .clk_write (lane_clk), .rst_write_n (rst_lane_n), .clk_read (com_clk), .rst_read_n (rst_com_n), .wrdata (rx_din[FIFO_WIDTH_WID-1:0]), .write_push (fifo_push), .read_pop (fifo_pop), .rd_soft_reset (1'b0), .wr_soft_reset (soft_reset_lane));

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module ca_rx_align_fifo
  #(
    parameter BITS_PER_CHANNEL = 80,
    parameter AD_WIDTH = 4,
    parameter SYNC_FIFO = 1
    )
  (
   input logic                         lane_clk,
   input logic                         rst_lane_n,
   input logic                         com_clk,
   input logic                         rst_com_n,
   input logic                         fifo_push,
   input logic                         fifo_pop,
   input logic                         soft_reset,
   input logic [BITS_PER_CHANNEL-1:0]  rx_din,
   output logic [BITS_PER_CHANNEL-1:0] rx_dout,
   output logic                        rd_empty,
   output logic                        wr_overflow_pulse,
   input logic [5:0]                   fifo_full_val,
   input logic [5:0]                   fifo_pfull_val,
   input logic [2:0]                   fifo_empty_val,
   input logic [2:0]                   fifo_pempty_val,
   output logic                        soft_reset_lane,
   output logic                        fifo_full,
   output logic                        fifo_pfull,
   output logic                        fifo_empty,
   output logic                        fifo_pempty
   );
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
