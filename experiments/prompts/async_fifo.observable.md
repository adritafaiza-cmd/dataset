Please act as a professional Verilog designer.

Implement an asynchronous FIFO with 2**ASIZE entries of DSIZE bits.

wclk and rclk are independent clocks. Please take care of any clock-domain crossings between them. The resets are active-low.

Store words written on one side and return them in order on the other. Honor full, empty, and almost flags without losing or repeating data; support the fall-through option and start empty after reset.

Give me the complete Verilog-2001 code in one source file, using this module interface.
Do not include a testbench, explanation, markdown, vendor primitives, or the reference implementation.

module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );
