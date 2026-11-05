module cdc_2phase #(
  parameter WIDTH = 1
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

  // Source domain: hold the payload and request signal
  reg [WIDTH-1:0] src_data_hold;
  reg             src_req;
  reg             dst_ack_src;  // synchronized ack from dst domain

  // Destination domain: hold the payload and ack signal
  reg [WIDTH-1:0] dst_data_hold;
  reg             dst_ack;
  reg             src_req_dst;  // synchronized req from src domain

  // Synchronizers for req (src -> dst)
  reg [1:0] req_sync;

  // Synchronizers for ack (dst -> src)
  reg [1:0] ack_sync;

  // Synchronizers for data (src -> dst) - 2 stages
  reg [WIDTH-1:0] data_sync1;
  reg [WIDTH-1:0] data_sync2;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_hold <= {WIDTH{1'b0}};
      src_req       <= 1'b0;
      dst_ack_src   <= 1'b0;
    end else begin
      // Accept new data when valid and ready
      if (src_valid_i && src_ready_o) begin
        src_data_hold <= src_data_i;
        src_req       <= 1'b1;
      end else if (dst_ack_src) begin
        // Ack received, clear request
        src_req <= 1'b0;
      end
    end
  end

  // Source ready: low when we have an outstanding request that hasn't been acked
  assign src_ready_o = ~src_req;

  // Synchronize req from src to dst
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync <= 2'b00;
    end else begin
      req_sync <= {req_sync[0], src_req};
    end
  end

  // Synchronize ack from dst to src
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync <= 2'b00;
    end else begin
      ack_sync <= {ack_sync[0], dst_ack};
    end
  end

  assign dst_ack_src = ack_sync[1];

  // Synchronize data from src to dst (2 stages)
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_sync1 <= {WIDTH{1'b0}};
      data_sync2 <= {WIDTH{1'b0}};
    end else begin
      data_sync1 <= src_data_hold;
      data_sync2 <= data_sync1;
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_hold <= {WIDTH{1'b0}};
      dst_ack       <= 1'b0;
      src_req_dst   <= 1'b0;
    end else begin
      // Track the synchronized request
      src_req_dst <= req_sync[1];

      // When a new request arrives (rising edge of req_sync[1]), capture data and set valid
      if (req_sync[1] && !src_req_dst) begin
        dst_data_hold <= data_sync2;
        dst_ack       <= 1'b1;
      end else if (dst_valid_o && dst_ready_i) begin
        // Transfer complete, clear ack
        dst_ack <= 1'b0;
      end
    end
  end

  // Destination valid: high when we have a pending item that hasn't been consumed
  assign dst_valid_o = dst_ack;
  assign dst_data_o  = dst_data_hold;

endmodule
