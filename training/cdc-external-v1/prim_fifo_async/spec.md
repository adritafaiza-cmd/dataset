Please act as a professional Verilog designer.

Implement a parameterized queue that preserves word order between independent write and read clocks using synchronized Gray-coded pointers.

Module name:
    prim_fifo_async

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
    wdepth_o: Write-domain occupancy derived from the local write position and synchronized read position.
    rvalid_o: Indicates a valid word is available to the read-domain consumer.
    rdata_o: Payload presented to the consumer in the read domain.
    rdepth_o: Read-domain occupancy derived from the synchronized write position and local consumed-read position.

Parameters:
    Width: Number of bits in each queued word; default 16.
    Depth: Storage capacity in words; use a positive power of two, including one; default 4.
    OutputZeroIfEmpty: Drive the read data bus to zero when the read side sees an empty queue; default disabled.
    OutputZeroIfInvalid: Drive the read data bus to zero whenever rvalid_o is low; default disabled.
    DepthW: Derived local parameter $clog2(Depth+1), providing enough bits for each occupancy output.

Behavior:
    - Store wdata_i on a rising write-clock edge only when wvalid_i and wready_o are both high. Advance the read position on a rising read-clock edge only when rvalid_o and rready_i are both high.
    - Keep local binary positions and registered Gray representations. Pass each Gray position through a two-stage synchronizer in the opposite clock domain before using it for status; register the decoded read position once more in the write domain.
    - Use the wrap phase to distinguish full from empty. Deassert wready_o when locally full and rvalid_o when locally empty; occupancy reports reflect the delayed remote positions, not instantaneous global occupancy.
    - Handle capacities of one and two explicitly. For larger capacities, encode the lower address in reflected Gray order while retaining the wrap phase so an increment changes only one transmitted bit.
    - Read storage at the current read position without an output register. Apply the selected zero-output options; otherwise data is not meaningful when rvalid_o is low.
    - Asynchronously clear each domain’s pointer and synchronizer state when its active-low reset is asserted. Do not reset the storage array; coordinate the two domain resets to restart an empty queue, since independent reset recovery is not provided.

Give me the complete code in one source file.
Do not include a testbench, explanation, markdown, vendor primitives,
or the reference implementation.

module prim_fifo_async #(
  parameter  int unsigned Width  = 16,
  parameter  int unsigned Depth  = 4,
  parameter  bit OutputZeroIfEmpty = 1'b0, // if == 1 always output 0 when FIFO is empty
  parameter  bit OutputZeroIfInvalid = 1'b0, // if == 1 always output 0 when rvalid_o is low
  localparam int unsigned DepthW = $clog2(Depth+1) // derived parameter representing [0..Depth]
) (
  // write port
  input  logic              clk_wr_i,
  input  logic              rst_wr_ni,
  input  logic              wvalid_i,
  output logic              wready_o,
  input  logic [Width-1:0]  wdata_i,
  output logic [DepthW-1:0] wdepth_o,

  // read port
  input  logic              clk_rd_i,
  input  logic              rst_rd_ni,
  output logic              rvalid_o,
  input  logic              rready_i,
  output logic [Width-1:0]  rdata_o,
  output logic [DepthW-1:0] rdepth_o
);
