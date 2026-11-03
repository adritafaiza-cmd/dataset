module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals for the four-phase handshake
  logic [WIDTH-1:0] sync_data;
  logic sync_valid;
  logic sync_ready;

  // Instantiate the asynchronous FIFO
  async_fifo #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) async_fifo_inst (
    .rst_ni(src_rst_ni),
    .clk_wr_i(src_clk_i),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .clk_rd_i(dst_clk_i),
    .data_o(sync_data),
    .valid_o(sync_valid),
    .ready_i(sync_ready)
  );

  // Synchronize the valid signal from the FIFO to the destination clock domain
  logic sync_valid_meta;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_valid_meta <= 1'b0;
      sync_valid <= 1'b0;
    end else begin
      sync_valid_meta <= sync_valid;
      sync_valid <= sync_valid_meta;
    end
  end

  // Synchronize the data and ready signals
  logic [WIDTH-1:0] sync_data_meta;
  logic sync_ready_meta;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_data_meta <= RESET_MSG;
      sync_data <= RESET_MSG;
      sync_ready_meta <= 1'b0;
      sync_ready <= 1'b0;
    end else begin
      sync_data_meta <= sync_data;
      sync_data <= sync_data_meta;
      sync_ready_meta <= dst_ready_i;
      sync_ready <= sync_ready_meta;
    end
  end

  // Assign the synchronized signals to the output ports
  assign dst_data_o = sync_data;
  assign dst_valid_o = sync_valid;

endmodule

module async_fifo #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  rst_ni,
  input  clk_wr_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  input  clk_rd_i,
  output [WIDTH-1:0] data_o,
  output valid_o,
  input  ready_i
);

  localparam MAX_DEPTH = 16;
  localparam ADDR_WIDTH = $clog2(MAX_DEPTH);

  // FIFO memory and pointers
  logic [WIDTH-1:0] fifo_mem [0:MAX_DEPTH-1];
  logic [ADDR_WIDTH-1:0] fifo_wr_ptr;
  logic [ADDR_WIDTH-1:0] fifo_rd_ptr;
  logic [ADDR_WIDTH-1:0] fifo_wr_ptr_gray;
  logic [ADDR_WIDTH-1:0] fifo_rd_ptr_gray;
  logic [ADDR_WIDTH-1:0] fifo_wr_ptr_gray_sync;
  logic [ADDR_WIDTH-1:0] fifo_rd_ptr_gray_sync;
  logic fifo_full;
  logic fifo_empty;

  // Gray code conversion
  function automatic logic [ADDR_WIDTH-1:0] binary_to_gray(input logic [ADDR_WIDTH-1:0] bin);
    return (bin ^ (bin >> 1));
  endfunction

  // Write side logic
  always_ff @(posedge clk_wr_i or negedge rst_ni) begin
    if (!rst_ni) begin
      fifo_wr_ptr <= '0;
      fifo_wr_ptr_gray <= '0;
    end else if (valid_i && !fifo_full) begin
      fifo_mem[fifo_wr_ptr] <= data_i;
      fifo_wr_ptr <= fifo_wr_ptr + 1;
      fifo_wr_ptr_gray <= binary_to_gray(fifo_wr_ptr + 1);
    end
  end

  // Read side logic
  always_ff @(posedge clk_rd_i or negedge rst_ni) begin
    if (!rst_ni) begin
      fifo_rd_ptr <= '0;
      fifo_rd_ptr_gray <= '0;
    end else if (valid_o && ready_i) begin
      fifo_rd_ptr <= fifo_rd_ptr + 1;
      fifo_rd_ptr_gray <= binary_to_gray(fifo_rd_ptr + 1);
    end
  end

  // Synchronize write pointer gray code to read clock domain
  always_ff @(posedge clk_rd_i or negedge rst_ni) begin
    if (!rst_ni) begin
      fifo_wr_ptr_gray_sync <= '0;
    end else begin
      fifo_wr_ptr_gray_sync <= fifo_wr_ptr_gray;
    end
  end

  // Synchronize read pointer gray code to write clock domain
  always_ff @(posedge clk_wr_i or negedge rst_ni) begin
    if (!rst_ni) begin
      fifo_rd_ptr_gray_sync <= '0;
    end else begin
      fifo_rd_ptr_gray_sync <= fifo_rd_ptr_gray;
    end
  end

  // Determine full and empty conditions
  assign fifo_full = (fifo_wr_ptr_gray_sync == binary_to_gray({{ADDR_WIDTH-1{1'b1}}, ~fifo_rd_ptr_gray[ADDR_WIDTH-1]}));
  assign fifo_empty = (fifo_wr_ptr_gray_sync == fifo_rd_ptr_gray_sync);

  // Output valid and data
  assign valid_o = !fifo_empty;
  assign data_o = fifo_mem[fifo_rd_ptr];

  // Ready output
  assign ready_o = !fifo_full;

endmodule
