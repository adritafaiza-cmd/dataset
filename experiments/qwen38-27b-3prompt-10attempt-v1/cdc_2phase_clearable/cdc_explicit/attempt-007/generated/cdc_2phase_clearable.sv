module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals
  wire src_clear_active;
  wire dst_clear_active;
  wire src_clear_req;
  wire dst_clear_req;
  wire src_clear_ack;
  wire dst_clear_ack;
  wire src_clear_done;
  wire dst_clear_done;

  // Clear request generation
  assign src_clear_req = src_clear_i;
  assign dst_clear_req = dst_clear_i;

  // Clear pending logic
  reg src_clear_pending_r;
  reg dst_clear_pending_r;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_pending_r <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_pending_r <= 1'b1;
    end else if (src_clear_done) begin
      src_clear_pending_r <= 1'b0;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_pending_r <= 1'b0;
    end else if (dst_clear_i) begin
      dst_clear_pending_r <= 1'b1;
    end else if (dst_clear_done) begin
      dst_clear_pending_r <= 1'b0;
    end
  end

  assign src_clear_pending_o = src_clear_pending_r;
  assign dst_clear_pending_o = dst_clear_pending_r;

  // Handshake signals
  reg src_valid_r;
  reg [WIDTH-1:0] src_data_r;
  reg dst_ready_r;
  reg dst_valid_r;
  reg [WIDTH-1:0] dst_data_r;

  // Source side: accept data when valid and ready
  wire src_accept = src_valid_i & src_ready_o & ~src_clear_pending_r;

  // Destination side: accept data when valid and ready
  wire dst_accept = dst_valid_r & dst_ready_i & ~dst_clear_pending_r;

  // Source ready: ready when not holding data and not in clear
  assign src_ready_o = ~src_valid_r & ~src_clear_pending_r;

  // Destination valid: valid when holding data
  assign dst_valid_o = dst_valid_r;
  assign dst_data_o = dst_data_r;

  // Source data register
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_r <= 1'b0;
      src_data_r <= {WIDTH{1'b0}};
    end else if (src_clear_i) begin
      src_valid_r <= 1'b0;
      src_data_r <= {WIDTH{1'b0}};
    end else if (src_accept) begin
      src_valid_r <= 1'b1;
      src_data_r <= src_data_i;
    end else if (src_clear_ack) begin
      src_valid_r <= 1'b0;
      src_data_r <= {WIDTH{1'b0}};
    end
  end

  // Destination data register
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
    end else if (dst_clear_i) begin
      dst_valid_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
    end else if (dst_accept) begin
      dst_valid_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
    end else if (dst_clear_ack) begin
      dst_valid_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
    end
  end

  // Clear handshake: source requests clear, destination acknowledges
  // Use a simple two-phase handshake for clear
  reg src_clear_req_r;
  reg dst_clear_ack_r;

  // Source clear request
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_clear_req_r <= 1'b0;
    end else if (src_clear_i) begin
      src_clear_req_r <= 1'b1;
    end else if (dst_clear_ack_r) begin
      src_clear_req_r <= 1'b0;
    end
  end

  // Destination clear acknowledge
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_clear_ack_r <= 1'b0;
    end else if (src_clear_req_r) begin
      dst_clear_ack_r <= 1'b1;
    end else if (dst_clear_i) begin
      dst_clear_ack_r <= 1'b0;
    end
  end

  // Clear done signals
  assign src_clear_done = src_clear_req_r & dst_clear_ack_r;
  assign dst_clear_done = dst_clear_i & ~dst_clear_pending_r;

  // Data transfer: when source has valid data and destination is ready
  // Use a simple valid/ready handshake with data transfer
  reg data_transfer_r;

  // Source side: transfer data to destination
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_transfer_r <= 1'b0;
    end else if (src_valid_r & dst_ready_r & ~src_clear_pending_r) begin
      data_transfer_r <= 1'b1;
    end else begin
      data_transfer_r <= 1'b0;
    end
  end

  // Destination side: receive data from source
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
    end else if (dst_clear_i) begin
      dst_valid_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
    end else if (data_transfer_r) begin
      dst_valid_r <= 1'b1;
      dst_data_r <= src_data_r;
    end else if (dst_accept) begin
      dst_valid_r <= 1'b0;
      dst_data_r <= {WIDTH{1'b0}};
    end
  end

  // Destination ready: ready when not holding data and not in clear
  assign dst_ready_r = ~dst_valid_r & ~dst_clear_pending_r;

endmodule
