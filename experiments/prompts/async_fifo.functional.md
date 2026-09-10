Please act as a professional Verilog designer.

Implement an asynchronous FIFO with 2**ASIZE entries of DSIZE bits.

Module name:
    async_fifo

Language:
    Verilog-2001

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
    awfull: Almost full, write domain.
    rdata: Read data.
    rempty: FIFO empty, read domain.
    arempty: Almost empty, read domain.

Parameters:
    DSIZE: Payload width in bits.
    ASIZE: Log2 of the number of FIFO entries.
    FALLTHROUGH: First-word fall-through when TRUE.

Behavior:
    - A write is accepted on a rising wclk edge when winc is high and wfull is low.
    - Writes attempted while full must not alter FIFO contents.
    - A read is accepted on a rising rclk edge when rinc is high and rempty is low.
    - Reads attempted while empty must not advance the FIFO.
    - Accepted data must be returned exactly once and in write order.
    - wfull is generated in the write domain and rempty in the read domain.
    - awfull indicates that the FIFO is approaching full, and arempty indicates that it is approaching empty.
    - After reset, wfull must be low and rempty must be high.
    - When FALLTHROUGH equals "TRUE", rdata presents the current oldest unread word without requiring an additional registered-read cycle. Otherwise, rdata may be updated by an accepted read.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

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
