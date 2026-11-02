Implement the SystemVerilog module `levelsync_sr`.

Implement levelsync sr using the interface and behavioral contract below.

Functional contract and interface notes:

Functional Descript:
This seems like a trivial block, just two FF in a row.
However, for timing checks / gate level sims, etc.,  it
is _VERY_ advantageous to have all of these in a known local.
like inside these blocks.
It is concieveable we may want to hardcode this, so that
we can forcibly apply don't touches, etc.
This block is the same as levelsync.v, except it has
a set and a reset, with reset winning in a tie.

Required clock and reset behavior:

- Clock ports: clk_dest.
- Reset ports: rst_dest_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module levelsync_sr
   (/*AUTOARG*/
   //Outputs
   dest_data,
   //Inputs
   clk_dest, rst_dest_n, set_dest_n, src_data
   );
parameter RESET_VALUE = 1'b0;
parameter SET_VALUE   = 1'b1;
input   rst_dest_n;
input   set_dest_n;
input   clk_dest;
input   src_data;
output  dest_data;
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
