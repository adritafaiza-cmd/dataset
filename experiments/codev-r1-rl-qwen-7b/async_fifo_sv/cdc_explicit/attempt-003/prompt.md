Please act as a professional Verilog designer.

Implement an asynchronous FIFO with 2**ADDR_WIDTH entries of DATA_WIDTH bits.

Module name:
    async_fifo

Language:
    SystemVerilog

Clocks:
    wclk: Independent asynchronous clock (async to rclk). No fixed frequency or phase relationship.
    rclk: Independent asynchronous clock (async to wclk).

Resets:
    wrst_n: active-low.
    rrst_n: active-low.

Input ports:
    wclk: Write-domain clock.
    wrst_n: Active-low write-domain reset.
    winc: Write increment / write request.
    wdata: Write data.
    rclk: Read-domain clock.
    rrst_n: Active-low read-domain reset.
    rinc: Read increment / read request.

Output ports:
    wfull: FIFO full, write domain.
    waddr: Address.
    rdata: Read data.
    rempty: FIFO empty, read domain.
    raddr: Address.

Parameters:
    DATA_WIDTH: Data width in bits.
    ADDR_WIDTH: Address or pointer width.
    SYNC_STAGES: Implementation depth parameter. Choose a safe crossing yourself.

Behavior:
    - A write is accepted when winc is high and wfull is low.
    - A read is accepted when rinc is high and rempty is low.
    - Data must return exactly once in write order.
    - After reset, wfull is low and rempty is high.
    - waddr and raddr are debug pointer outputs.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
