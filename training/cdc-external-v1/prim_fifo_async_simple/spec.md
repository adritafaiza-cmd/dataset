Please act as a professional Verilog designer.

Implement a small asynchronous ready/valid queue that transfers a held data word through a synchronized request/acknowledge exchange and a read-side holding register.

Module name:
    prim_fifo_async_simple

Language:
    SystemVerilog

Clocks:
    clk_wr_i: Rising-edge clock for queue writes and write-side status.
    clk_rd_i: Rising-edge clock for queue reads and read-side status.

Resets:
    rst_wr_ni: active low; asynchronous assertion.
    rst_rd_ni: active low; asynchronous assertion.

Input ports:
    clk_wr_i: Rising-edge clock for queue writes and write-side status.
    rst_wr_ni: Active-low asynchronous reset of the write-domain control.
    wvalid_i: Indicates a producer word is offered in the write domain.
    wdata_i: Payload presented by the producer in the write domain.
    clk_rd_i: Rising-edge clock for queue reads and read-side status.
    rst_rd_ni: Active-low asynchronous reset of the read-domain control.
    rready_i: Indicates the read-domain consumer accepts a valid word.

Output ports:
    wready_o: Indicates the write domain can accept the offered word.
    rvalid_o: Indicates a valid word is available to the read-domain consumer.
    rdata_o: Payload presented to the consumer in the read domain.

Parameters:
    Width: Width of both data holding registers and the external data buses; default 16.
    EnRstChks: Enable the request/acknowledge helper’s reset consistency assertions; default disabled.
    EnRzHs: Select a four-phase return-to-zero handshake when one, or a two-phase toggle handshake when zero; default zero.

Behavior:
    - Accept a write only on wvalid_i && wready_o and retain its data in a write-clocked register. Track a pending transfer until its synchronized acknowledgement arrives.
    - Translate pending writes into requests to prim_sync_reqack. Its request and acknowledgement synchronizers carry control between the domains; the held data bus must remain stable during that exchange.
    - When a destination request is present and the read holding register is free, copy the held write data into that register and acknowledge the request.
    - Assert rvalid_o for the buffered read word and keep its data unchanged while the consumer stalls. Clear read-valid after rready_i accepts the word; do not overwrite a still-valid word.
    - Asynchronously clear pending state, write-ready, and read-valid with their respective active-low resets. Write-ready starts low and becomes available after the write-domain control advances; neither payload register is reset.
    - Use coordinated domain resets for the default toggle protocol. The return-to-zero option permits its handshake control to recover from a domain-only reset, but reset can discard an in-flight word.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_fifo_async_simple #(
  parameter int unsigned Width  = 16,
  parameter bit          EnRstChks = 1'b0, // Enable reset-related assertion checks, disabled by
                                           // default.
  parameter bit          EnRzHs = 1'b0     // By Default, the faster NRZ handshake protocol
                                           // (EnRzHs = 0) is used. Enable the RZ handshake protocol
                                           // if the FSMs need to be partial-reset-safe.
) (
  // write port
  input  logic              clk_wr_i,
  input  logic              rst_wr_ni,
  input  logic              wvalid_i,
  output logic              wready_o,
  input  logic [Width-1:0]  wdata_i,

  // read port
  input  logic              clk_rd_i,
  input  logic              rst_rd_ni,
  output logic              rvalid_o,
  input  logic              rready_i,
  output logic [Width-1:0]  rdata_o
);
