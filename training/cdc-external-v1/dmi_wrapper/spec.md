Implement the SystemVerilog module `dmi_wrapper`.

Connect the JTAG DMI transport to the core-domain debug register interface, synchronizing the access enables while maintaining the transport address and write-data protocol.

Functional contract and interface notes:

Owner : Anusha Narayanamoorthy
Description:
Wrapper module for JTAG_TAP and DMI synchronizer

Required clock and reset behavior:

- Clock ports: tck, core_clk.
- Reset ports: trst_n, core_rst_n, dmi_hard_reset.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- dmi_jtag_to_core_sync: dmi_jtag_to_core_sync i_dmi_jtag_to_core_sync( .wr_en(wr_en), .rd_en(rd_en), .rst_n(core_rst_n), .clk(core_clk), .reg_en(reg_en), .reg_wr_en(reg_wr_en) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module dmi_wrapper(
  // JTAG signals
  input              trst_n,              // JTAG reset
  input              tck,                 // JTAG clock
  input              tms,                 // Test mode select
  input              tdi,                 // Test Data Input
  output             tdo,                 // Test Data Output
  output             tdoEnable,           // Test Data Output enable
  // Processor Signals
  input              core_rst_n,          // Core reset
  input              core_clk,            // Core clock
  //jtag_id is supposed to be connected to a constant in the top level
  /* pragma coverage off*/
  input [31:1]       jtag_id,             // JTAG ID
  /* pragma coverage on*/
  input [31:0]       rd_data,             // 32 bit Read data from  Processor
  output [31:0]      reg_wr_data,         // 32 bit Write data to Processor
  output [6:0]       reg_wr_addr,         // 7 bit reg address to Processor
  output             reg_en,              // 1 bit  Read enable to Processor
  output             reg_wr_en,           // 1 bit  Write enable to Processor
  output             dmi_hard_reset
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
