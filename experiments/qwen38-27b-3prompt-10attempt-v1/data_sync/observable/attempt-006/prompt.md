Please act as a professional Verilog designer.

Implement a multi-bit destination-clock data synchronizer.

Please take care as din and dready_i enter the clk domain. The reset is active-low.

Bring each new input value into the local clock domain coherently and indicate when it is ready. Reset should leave the output indication idle.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module data_sync #(
    parameter STAGES = 2,
    parameter DWIDTH = 8
)(
    input                  clk,
    input                  rstn,
    input  [DWIDTH-1:0]    din,
    input                  dready_i,
    output reg [DWIDTH-1:0] dout,
    output reg             dready_o
);
