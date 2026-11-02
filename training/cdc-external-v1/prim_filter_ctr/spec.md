Implement the SystemVerilog module `prim_filter_ctr`.

Synchronize an asynchronous input and update the filtered output only after the input has remained stable for the configured count.

Functional contract and interface notes:

Primitive counter-based input filter, with enable.
Configurable number of cycles. Cheaper version of filter for
large values of #Cycles
when in reset, stored value is zero
when enable is false, output is input
when enable is true, output is stored value,
new input must be opposite value from stored value for
#Cycles before switching to new value.

Required clock and reset behavior:

- Clock ports: clk_i.
- Reset ports: rst_ni.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- prim_flop_2sync: prim_flop_2sync #( .Width(1) ) prim_flop_2sync ( .clk_i, .rst_ni, .d_i(filter_i), .q_o(filter_synced) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module prim_filter_ctr #(
  // If this parameter is set, an additional 2-stage synchronizer will be
  // added at the input.
  parameter bit AsyncOn = 0,
  parameter int unsigned CntWidth = 2
) (
  input                clk_i,
  input                rst_ni,
  input                enable_i,
  input                filter_i,
  input [CntWidth-1:0] thresh_i,
  output logic         filter_o
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
