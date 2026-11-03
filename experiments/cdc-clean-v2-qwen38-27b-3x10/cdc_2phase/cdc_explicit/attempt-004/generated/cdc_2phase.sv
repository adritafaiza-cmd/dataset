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

  // Source domain: hold payload and request signal
  reg [WIDTH-1:0] src_data_hold;
  reg             src_req;
  reg             dst_ack_src;  // synchronized ack from dst domain

  // Destination domain: synchronized request and payload
  reg             dst_req_sync1;
  reg             dst_req_sync2;
  reg [WIDTH-1:0] dst_data_sync1;
  reg [WIDTH-1:0] dst_data_sync2;
  reg             dst_ack;
  reg [WIDTH-1:0] dst_data_hold;
  reg             dst_valid;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_hold <= {WIDTH{1'b0}};
      src_req       <= 1'b0;
      dst_ack_src   <= 1'b0;
    end else begin
      if (src_valid_i && !src_req) begin
        src_data_hold <= src_data_i;
        src_req       <= 1'b1;
      end
      if (dst_ack_src && src_req) begin
        src_req <= 1'b0;
      end
    end
  end

  assign src_ready_o = !src_req;

  // Synchronize dst_ack from dst domain to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ack_src <= 1'b0;
    end else begin
      dst_ack_src <= dst_ack;
    end
  end

  // Destination domain: synchronize src_req
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_sync1 <= 1'b0;
      dst_req_sync2 <= 1'b0;
    end else begin
      dst_req_sync1 <= src_req;
      dst_req_sync2 <= dst_req_sync1;
    end
  end

  // Destination domain: synchronize payload (2 stages)
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_sync1 <= {WIDTH{1'b0}};
      dst_data_sync2 <= {WIDTH{1'b0}};
    end else begin
      dst_data_sync1 <= src_data_hold;
      dst_data_sync2 <= dst_data_sync1;
    end
  end

  // Destination domain: handshake and output
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack       <= 1'b0;
      dst_data_hold <= {WIDTH{1'b0}};
      dst_valid     <= 1'b0;
    end else begin
      // When a new request arrives and we are not currently holding a valid item
      if (dst_req_sync2 && !dst_valid) begin
        dst_data_hold <= dst_data_sync2;
        dst_valid     <= 1'b1;
        dst_ack       <= 1'b1;
      end
      // When destination accepts the item, clear valid and ack
      if (dst_valid && dst_ready_i) begin
        dst_valid <= 1'b0;
        dst_ack   <= 1'b0;
      end
    end
  end

  assign dst_data_o  = dst_data_hold;
  assign dst_valid_o = dst_valid;

endmodule
