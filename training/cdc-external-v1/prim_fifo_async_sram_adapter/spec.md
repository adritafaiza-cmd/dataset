Please act as a professional Verilog designer.

Implement an asynchronous ready/valid FIFO controller that stores payloads in an external dual-port SRAM and bridges its write and read clock domains.

Module name:
    prim_fifo_async_sram_adapter

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
    w_sram_gnt_i: Write-domain grant for the current SRAM request.
    w_sram_rvalid_i: Unused write-port read-response indication; expected low.
    w_sram_rdata_i: Unused write-port read-response payload; expected zero.
    w_sram_rerror_i: Unused write-port read-error flags; expected zero.
    r_sram_gnt_i: Read-domain grant for the current SRAM fetch request.
    r_sram_rvalid_i: Read-domain indication of the SRAM response to a granted request.
    r_sram_rdata_i: SRAM response word; the low Width bits form the queue payload.
    r_sram_rerror_i: Read response error flags, ignored by this controller.

Output ports:
    wready_o: Indicates the write domain can accept the offered word.
    wdepth_o: Write-domain occupancy derived from the local write position and synchronized read position.
    rvalid_o: Indicates a valid word is available to the read-domain consumer.
    rdata_o: Payload presented to the consumer in the read domain.
    rdepth_o: Read-domain occupancy derived from the synchronized write position and local consumed-read position.
    r_full_o: Full indication calculated in the read domain.
    r_notempty_o: Read-domain data-available indication, equal to rvalid_o.
    w_full_o: Full indication calculated in the write domain.
    w_sram_req_o: Write-domain request to store the offered FIFO word in SRAM.
    w_sram_write_o: SRAM write operation selector, tied high.
    w_sram_addr_o: SRAM write address formed from the base address and circular entry index.
    w_sram_wdata_o: SRAM-width payload with unused high bits zero-filled.
    w_sram_wmask_o: SRAM bit mask enabling the low Width payload bits.
    r_sram_req_o: Read-domain request to fetch an available queue entry from SRAM.
    r_sram_write_o: SRAM read operation selector, tied low.
    r_sram_addr_o: SRAM read address formed from the base address and fetch index.
    r_sram_wdata_o: Unused read-port write-data bus, tied to zero.
    r_sram_wmask_o: Unused read-port write-mask bus, tied to zero.

Parameters:
    Width: Payload bits per queue entry; default 32 and no greater than SramDw.
    Depth: Power-of-two queue capacity, at least four entries; default 16.
    SramAw: Address width of each SRAM interface; default 16.
    SramDw: SRAM data and bit-mask width; default 32.
    SramBaseAddr: Base address added to each circular-buffer entry index; default zero.
    DepthW: Derived local parameter $clog2(Depth+1) for the occupancy outputs.

Behavior:
    - Maintain binary and Gray-coded write and consumed-read positions. Synchronize each registered Gray position into the other clock domain using two-stage synchronizers, then derive local occupancy and full status.
    - Request an SRAM write for a valid input while not full. Assert wready_o only when that write can receive w_sram_gnt_i; advance the write position only on the resulting ready/valid transfer.
    - Drive the write address from SramBaseAddr plus the circular write index, zero-extend the payload to SramDw, enable the low Width mask bits, and hold w_sram_write_o high.
    - Use a separate SRAM fetch pointer that advances on granted read requests. The read position sent back to the write domain advances only when the external consumer accepts a FIFO word.
    - Require the SRAM to return r_sram_rvalid_i and its data one read-clock cycle after a granted request. Prefetch only when the outstanding response and one-word holding register can be handled without losing unread data.
    - Select read output from the holding register when occupied, otherwise from the current SRAM response. Assert rvalid_o for either source and make r_notempty_o equal rvalid_o. Preserve a response in the holding register when the consumer cannot immediately take it.
    - Drive r_sram_write_o low and its write-data and mask outputs to zero. Ignore SRAM error inputs and the unused write-port read-response inputs; no error-reporting output is provided.
    - Asynchronously reset local positions and synchronizer state with the corresponding active-low reset. The read reset also clears the buffered-word flag and data. Reset does not initialize the external SRAM; coordinate domain resets and quiesce stale SRAM responses.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_fifo_async_sram_adapter #(
  parameter int unsigned Width = 32,
  parameter int unsigned Depth = 16,

  // SRAM parameters
  parameter int unsigned       SramAw = 16,

  // If SramDw > Width, upper data bits are 0.
  parameter int unsigned       SramDw = 32,
  parameter logic [SramAw-1:0] SramBaseAddr = 'h 0,

  // derived
  localparam int unsigned DepthW = $clog2(Depth+1)
) (
  // Write port
  input                     clk_wr_i,
  input                     rst_wr_ni,
  input                     wvalid_i,
  output logic              wready_o,
  input        [Width-1:0]  wdata_i,
  output logic [DepthW-1:0] wdepth_o,

  // Read port
  input                     clk_rd_i,
  input                     rst_rd_ni,
  output logic              rvalid_o,
  input                     rready_i,
  output logic [Width-1:0]  rdata_o,
  output logic [DepthW-1:0] rdepth_o,

  output logic r_full_o,
  output logic r_notempty_o,

  output logic w_full_o,

  // TODO: watermark(threshold) ?

  // SRAM interface
  // Write SRAM port
  output logic              w_sram_req_o,
  input                     w_sram_gnt_i,
  output logic              w_sram_write_o,
  output logic [SramAw-1:0] w_sram_addr_o,
  output logic [SramDw-1:0] w_sram_wdata_o,
  output logic [SramDw-1:0] w_sram_wmask_o,
  input                     w_sram_rvalid_i, // not used
  input        [SramDw-1:0] w_sram_rdata_i,  // not used
  input        [1:0]        w_sram_rerror_i, // not used

  // Read SRAM port
  output logic              r_sram_req_o,
  input                     r_sram_gnt_i,
  output logic              r_sram_write_o,
  output logic [SramAw-1:0] r_sram_addr_o,
  output logic [SramDw-1:0] r_sram_wdata_o, // not used
  output logic [SramDw-1:0] r_sram_wmask_o, // not used
  input                     r_sram_rvalid_i,
  input        [SramDw-1:0] r_sram_rdata_i,
  input        [1:0]        r_sram_rerror_i
);
