Please act as a professional Verilog designer.

Implement an asynchronous FIFO with 2**ADDR_WIDTH entries of DATA_WIDTH bits.

wclk and rclk are independent clocks. Please take care of any clock-domain crossings between them. The resets are active-low.

Queue words between the write and read sides. Preserve order, keep the flags and pointer outputs meaningful in their respective domains, and start empty after reset.

Give me the complete SystemVerilog code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wfull,
    output wire [ADDR_WIDTH:0]     waddr,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    rempty,
    output wire [ADDR_WIDTH:0]     raddr
);
