Implement the SystemVerilog module `rst_regen_low`.

Implement rst regen low using the interface and behavioral contract below.

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: async_rst_n, rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- levelsync: levelsync #( .RESET_VALUE(1'b0) ) levelsync_i ( .clk_dest (clk), .rst_dest_n (async_rst_n), .src_data (1'b1), .dest_data (rst_n) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module rst_regen_low
(
 clk,
 async_rst_n, rst_n
);
input  clk;
input  async_rst_n;
output rst_n;
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
