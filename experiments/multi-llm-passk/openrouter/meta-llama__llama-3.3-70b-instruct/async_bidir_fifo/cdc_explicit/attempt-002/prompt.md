Please act as a professional Verilog designer.

Implement a bidirectional asynchronous FIFO.

Module name:
    async_bidir_fifo

Language:
    Verilog-2001

Clocks:
    a_clk: Independent asynchronous clock (async to b_clk).
    b_clk: Independent asynchronous clock (async to a_clk).

Resets:
    a_rst_n: active-low.
    b_rst_n: active-low.

Input ports:
    a_clk: Clock.
    a_rst_n: Active-low reset.
    a_winc: See Behavior.
    a_wdata: Data payload.
    a_rinc: See Behavior.
    a_dir: See Behavior.
    b_clk: Clock.
    b_rst_n: Active-low reset.
    b_winc: See Behavior.
    b_wdata: Data payload.
    b_rinc: See Behavior.
    b_dir: See Behavior.

Output ports:
    a_rdata: Data payload.
    a_full: FIFO full flag.
    a_afull: FIFO full flag.
    a_empty: FIFO empty flag.
    a_aempty: FIFO empty flag.
    b_rdata: Data payload.
    b_full: FIFO full flag.
    b_afull: FIFO full flag.
    b_empty: FIFO empty flag.
    b_aempty: FIFO empty flag.

Parameters:
    DSIZE: Payload width in bits.
    ASIZE: Log2 of the number of FIFO entries.
    FALLTHROUGH: First-word fall-through when TRUE.

Behavior:
    - a_dir / b_dir select the direction on that side: 1 means write, 0 means read.
    - Accepted writes must appear in order on the opposite side when that side reads.
    - Full/empty and almost-full/almost-empty flags are local to each side.
    - After reset the FIFO is empty.
    - FALLTHROUGH selects first-word fall-through.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir
       );
