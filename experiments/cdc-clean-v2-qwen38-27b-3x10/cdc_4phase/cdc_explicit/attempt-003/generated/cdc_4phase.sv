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

  // Source domain state
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_ready_reg;
  reg             src_req;
  reg             src_ack_sync;
  reg             src_ack_sync2;

  // Destination domain state
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_ack;
  reg             dst_req_sync;
  reg             dst_req_sync2;

  // Synchronizers for request (src -> dst)
  reg req_sync1;
  reg req_sync2;

  // Synchronizers for acknowledge (dst -> src)
  reg ack_sync1;
  reg ack_sync2;

  // Synchronizers for data (src -> dst) - multi-bit, synchronized
  reg [WIDTH-1:0] data_sync1;
  reg [WIDTH-1:0] data_sync2;

  // Synchronizers for valid (src -> dst)
  reg valid_sync1;
  reg valid_sync2;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_req       <= 1'b0;
      src_ack_sync  <= 1'b0;
      src_ack_sync2 <= 1'b0;
    end else begin
      // Synchronize acknowledge from destination
      src_ack_sync  <= ack_sync1;
      src_ack_sync2 <= src_ack_sync;

      // Handle reset message
      if (SEND_RESET_MSG && !src_valid_reg && src_ready_reg && !src_req) begin
        // After reset, emit RESET_MSG
        src_data_reg  <= RESET_MSG;
        src_valid_reg <= 1'b1;
        src_ready_reg <= 1'b0;
        src_req       <= 1'b1;
      end else if (src_valid_reg && src_ready_reg) begin
        // Accept new data
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
        src_ready_reg <= 1'b0;
        src_req       <= 1'b1;
      end else if (src_valid_reg && !src_ready_reg && src_ack_sync2) begin
        // Acknowledge received, can accept new data
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b1;
        src_req       <= 1'b0;
      end else if (!src_valid_reg && src_ready_reg && src_ack_sync2) begin
        // Idle, acknowledge received
        src_ready_reg <= 1'b1;
        src_req       <= 1'b0;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ack       <= 1'b0;
      dst_req_sync  <= 1'b0;
      dst_req_sync2 <= 1'b0;
    end else begin
      // Synchronize request from source
      dst_req_sync  <= req_sync1;
      dst_req_sync2 <= dst_req_sync;

      // Synchronize data and valid from source
      data_sync1    <= src_data_reg;
      data_sync2    <= data_sync1;
      valid_sync1   <= src_valid_reg;
      valid_sync2   <= valid_sync1;

      // Handle transfer
      if (dst_valid_reg && dst_ready_i) begin
        // Handshake complete
        dst_valid_reg <= 1'b0;
        dst_ack       <= 1'b0;
      end else if (!dst_valid_reg && dst_req_sync2 && valid_sync2) begin
        // New transfer available
        dst_data_reg  <= data_sync2;
        dst_valid_reg <= 1'b1;
        dst_ack       <= 1'b1;
      end else if (dst_valid_reg && !dst_ready_i) begin
        // Hold data stable
        dst_ack       <= 1'b1;
      end
    end
  end

  // Synchronizer for request (src -> dst)
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync1 <= 1'b0;
      req_sync2 <= 1'b0;
    end else begin
      req_sync1 <= src_req;
      req_sync2 <= req_sync1;
    end
  end

  // Synchronizer for acknowledge (dst -> src)
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync1 <= 1'b0;
      ack_sync2 <= 1'b0;
    end else begin
      ack_sync1 <= dst_ack;
      ack_sync2 <= ack_sync1;
    end
  end

  // Outputs
  assign src_ready_o = src_ready_reg;
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
