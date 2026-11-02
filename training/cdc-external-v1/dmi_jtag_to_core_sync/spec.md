Implement the SystemVerilog module `dmi_jtag_to_core_sync`.

Synchronize JTAG read and write enables into the processor clock domain and emit single-cycle register-access strobes from the synchronized rising edges.

Functional contract and interface notes:

Owner : Alex Grobman
Description:
This module Synchronizes the signals between JTAG (TCK) and
processor (Core_clk)

Required clock and reset behavior:

- Clock ports: clk.
- Reset ports: rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module dmi_jtag_to_core_sync (
// JTAG signals
input       rd_en,      // 1 bit  Read Enable from JTAG
input       wr_en,      // 1 bit  Write enable from JTAG
// Processor Signals
input       rst_n,      // Core reset
input       clk,        // Core clock
output      reg_en,     // 1 bit  Write interface bit to Processor
output      reg_wr_en   // 1 bit  Write enable to Processor
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
