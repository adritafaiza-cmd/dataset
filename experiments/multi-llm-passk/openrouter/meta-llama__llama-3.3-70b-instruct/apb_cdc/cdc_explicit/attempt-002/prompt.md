Please act as a professional Verilog designer.

Implement an APB clock-domain bridge.

Module name:
    apb_cdc

Language:
    Verilog-2001

Clocks:
    src_pclk_i: Independent asynchronous clock (async to dst_pclk_i).
    dst_pclk_i: Independent asynchronous clock (async to src_pclk_i).

Resets:
    src_preset_ni: reset.
    dst_preset_ni: reset.

Input ports:
    src_pclk_i: Clock.
    src_preset_ni: Reset reset.
    src_psel_i: See Behavior.
    src_penable_i: See Behavior.
    src_pwrite_i: See Behavior.
    src_paddr_i: Address.
    src_pwdata_i: Data payload.
    src_pstrb_i: Write strobes.
    src_pprot_i: Protection bits.
    dst_pclk_i: Clock.
    dst_preset_ni: Reset reset.
    dst_pready_i: Handshake ready.
    dst_prdata_i: Data payload.
    dst_pslverr_i: See Behavior.

Output ports:
    src_pready_o: Handshake ready.
    src_prdata_o: Data payload.
    src_pslverr_o: See Behavior.
    dst_psel_o: See Behavior.
    dst_penable_o: See Behavior.
    dst_pwrite_o: See Behavior.
    dst_paddr_o: Address.
    dst_pwdata_o: Data payload.
    dst_pstrb_o: Write strobes.
    dst_pprot_o: Protection bits.

Parameters:
    ADDR_WIDTH: Address or pointer width.
    DATA_WIDTH: Data width in bits.
    LOG_DEPTH: Log2 of the number of FIFO entries.

Behavior:
    - Accept standard APB transfers on the source ports.
    - Forward each accepted request exactly once to the destination with a setup phase then an access phase.
    - Keep destination request fields stable until dst_pready_i completes the transfer.
    - Return read data and slave error to the source.
    - Assert src_pready_o only after the destination transfer completes.
    - Do not lose, duplicate, or reorder requests. One outstanding transaction is enough.
    - Reset must idle both interfaces and must not create a transaction.

CDC requirement:
    The implementation must be safe for clock-domain and reset-domain crossings
    and must pass structural CDC/RDC analysis with zero unsafe crossings. Reset
    release must be safe in each clock domain, and transferred multi-bit data must
    remain coherent. Select the architecture yourself.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module apb_cdc #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter LOG_DEPTH = 1
)(
    input                      src_pclk_i,
    input                      src_preset_ni,
    input                      src_psel_i,
    input                      src_penable_i,
    input                      src_pwrite_i,
    input  [ADDR_WIDTH-1:0]    src_paddr_i,
    input  [DATA_WIDTH-1:0]    src_pwdata_i,
    input  [DATA_WIDTH/8-1:0]  src_pstrb_i,
    input  [2:0]               src_pprot_i,
    output                     src_pready_o,
    output [DATA_WIDTH-1:0]    src_prdata_o,
    output                     src_pslverr_o,
    input                      dst_pclk_i,
    input                      dst_preset_ni,
    output                     dst_psel_o,
    output                     dst_penable_o,
    output                     dst_pwrite_o,
    output [ADDR_WIDTH-1:0]    dst_paddr_o,
    output [DATA_WIDTH-1:0]    dst_pwdata_o,
    output [DATA_WIDTH/8-1:0]  dst_pstrb_o,
    output [2:0]               dst_pprot_o,
    input                      dst_pready_i,
    input  [DATA_WIDTH-1:0]    dst_prdata_i,
    input                      dst_pslverr_i
);
