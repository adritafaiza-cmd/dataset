Implement the SystemVerilog module `bridge_mon_cdc`.

Carries one Ocelus port monitor that runs on a slave's own clock

Functional contract and interface notes:

Module: bridge_mon_cdc
Purpose: Carries one Ocelus port monitor that runs on a slave's own clock
(s_aclk) into the bridge's aclk monbus group.
Description:
A cdc slave that two or more masters share is arbitrated on s_aclk
(bridge_cdc_slave_arb, bridge W9), so its only AXI stream is the one at
its pins. Its monitor wrappers run there. This block crosses what they
exchange with the aclk side of the bridge:
- packets out: {packet, timestamp} through one async FIFO, s_aclk to
aclk, valid/ready on both sides. A full FIFO back-pressures the
monitor, which holds its packet like any monbus source.
- monitor time in: the group's free-running mon_time_out (aclk) is
registered as Gray code and synchronized into s_aclk, so each packet
is stamped in the group's time base. One bit of a Gray count changes
per aclk edge, so a sample is always the value just before or just
after an edge, however many edges fall between s_aclk samples. It
lags aclk time by the synchronizer (about three s_aclk cycles).
- cfg in: the monitors' cfg bus (aclk, from the bridge's cfg pins or
regblock), CFG_W bits through a two-flop synchronizer each. The cfg
is quasi-static -- written while the port is idle -- so a value is
stable for many cycles before the monitor acts on it; a cfg change
during traffic may be seen a bit at a time for a cycle or two.
Parameters:
CFG_W     - width of the flattened cfg bus, >= 1
PKT_DEPTH - entries in the packet crossing
Dependencies: gaxi_fifo_async, bin2gray, gray2bin, glitch_free_n_dff_arn
(rtl/cdc)

Required clock and reset behavior:

- Clock ports: aclk, s_aclk.
- Reset ports: aresetn, s_aresetn.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- gaxi_fifo_async: gaxi_fifo_async #( .DATA_WIDTH (PKW + TSW), .DEPTH (PKT_DEPTH) ) u_pkt ( .axi_wr_aclk (s_aclk), .axi_wr_aresetn (s_aresetn), .axi_rd_aclk (aclk), .axi_rd_aresetn (aresetn), .wr_valid (s_monbus_valid), .wr_ready (s_monbus_ready), .wr_data ({s_monbus_packet, s_monbus_timestamp}), .rd_ready (monbus_ready), .rd_valid (monbus_valid), .rd_data ({monbus_packet, monbus_timestamp}) );
- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (2), .WIDTH (TSW) ) u_time_sync ( .clk (s_aclk), .rst_n (s_aresetn), .d (r_time_gray), .q (w_s_time_gray) );
- glitch_free_n_dff_arn: glitch_free_n_dff_arn #( .FLOP_COUNT (2), .WIDTH (CFG_W) ) u_cfg_sync ( .clk (s_aclk), .rst_n (s_aresetn), .d (i_cfg), .q (s_cfg) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module bridge_mon_cdc
    import ocelus_common_pkg::*;
#(
    parameter int CFG_W     = 1,
    parameter int PKT_DEPTH = 8
) (
    input  logic                aclk,
    input  logic                aresetn,
    input  logic                s_aclk,
    input  logic                s_aresetn,
    // monitor time: aclk in, s_aclk out
    input  monbus_timestamp_t   i_mon_time,
    output monbus_timestamp_t   s_mon_time,
    // cfg: aclk in, s_aclk out
    input  logic [CFG_W-1:0]    i_cfg,
    output logic [CFG_W-1:0]    s_cfg,
    // packets from the s_aclk monitor
    input  logic                s_monbus_valid,
    output logic                s_monbus_ready,
    input  monitor_packet_t     s_monbus_packet,
    input  monbus_timestamp_t   s_monbus_timestamp,
    // packets to the aclk monbus group
    output logic                monbus_valid,
    input  logic                monbus_ready,
    output monitor_packet_t     monbus_packet,
    output monbus_timestamp_t   monbus_timestamp
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
