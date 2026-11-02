Implement the SystemVerilog module `levelsync`.

Implement levelsync using the interface and behavioral contract below.

Functional contract and interface notes:

Functional Descript:
This seems like a trivial block, just two FF in a row.
However, for timing checks / gate level sims, etc.,  it
is _VERY_ advantageous to have all of these in a known local.
like inside these blocks.
It is concieveable we may want to hardcode this, so that
we can forcibly apply don't touches, etc. to specific
instances.
Note, to add in "realistic" simulation events,
we add a semi-random delay to the "input" of the first
FF.  This represents the uncertain nature of the async
sampling (i.e. the clk_dest fires too soon to get the
latest src_data).  We do this by adding a # delay.
Note that in true, legit synthesis, the #delay would
be synthesized away.  Still, I like the minimize the
number of synthesis warnings, so I only enable this
during simulations.

Required clock and reset behavior:

- Clock ports: clk_dest.
- Reset ports: rst_dest_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module levelsync
   (/*AUTOARG*/
   //Outputs
   dest_data,
   //Inputs
   clk_dest, rst_dest_n, src_data
   );
parameter RESET_VALUE = 1'b0;
input   rst_dest_n;
input   clk_dest;
input   src_data;
output  dest_data;
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
