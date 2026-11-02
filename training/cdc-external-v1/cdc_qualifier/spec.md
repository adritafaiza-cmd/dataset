Implement the SystemVerilog module `cdc_qualifier`.

Transfer a held data bus using a synchronized qualifier. The source must keep the bus stable for the qualifier transfer interval; expose data only after the qualifier has safely crossed.

Functional contract and interface notes:

cdc_qualifier.sv — Valid-Qualified Data Bus Synchronizer
Synchronizes a level-held i_valid into the destination clock domain via
cdc_bit, then uses the synchronized valid as a load-enable to capture
i_data into a destination-domain register. Caller must hold both i_data
and i_valid stable for at least SYNC_STAGES+1 i_clk cycles — long enough
for the valid synchronizer to settle before data is sampled.
o_data lags o_valid by one extra i_clk cycle: o_valid is itself a
registered output of cdc_bit, so the load-enable it drives is only
visible to this module's always_ff one cycle after o_valid appears to
assert. Total latency from i_valid asserting to o_data updating is
SYNC_STAGES+1 i_clk cycles.

Required clock and reset behavior:

- Clock ports: i_clk.
- Reset ports: i_rst_n.
- Keep the asynchronous crossing in the design. Synchronize controls in their receiving clock domain before consuming them. A raw crossing wire must not replace a synchronizer.
- For a reset-release synchronizer, preserve asynchronous assertion and clocked staged release, including the configured polarity and stage count. Data synchronizers and reset-release synchronizers have different contracts.
- For a held-bus handshake, retain the payload until acknowledgement. For a Gray-pointer FIFO, keep local binary addressing and synchronize the Gray pointers before deriving status. These rules apply where that mechanism is present.

Crossing subinterfaces and required parameter/port bindings (dependencies are supplied in deps/):

- cdc_bit: cdc_bit #( .SYNC_STAGES (SYNC_STAGES), .RESET_VALUE (1'b0) ) u_sync_valid ( .i_clk (i_clk), .i_rst_n (i_rst_n), .i_async_in (i_valid), .o_sync_out (o_valid) );

Exact module interface (retain parameter defaults, types, widths, names, and directions):

```systemverilog
module cdc_qualifier #(
    parameter int unsigned WIDTH       = 8,
    parameter int unsigned SYNC_STAGES = 2
) (
    // Destination clock domain
    input  logic                i_clk,
    input  logic                i_rst_n,
    // Source domain — i_data must remain stable while i_valid is held high
    input  logic [WIDTH-1:0]    i_data,
    input  logic                i_valid,
    // Destination domain
    output logic [WIDTH-1:0]    o_data,
    output logic                o_valid
);
```

Return only the complete module source. Do not emit a testbench or remove the synchronizing path.
