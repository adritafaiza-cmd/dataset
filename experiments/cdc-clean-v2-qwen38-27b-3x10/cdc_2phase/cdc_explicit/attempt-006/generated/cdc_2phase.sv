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

  // Source domain: hold data and generate request
  reg [WIDTH-1:0] src_data_hold;
  reg             src_req;
  wire            src_ack;

  // Destination domain: synchronize request, hold data, generate ack
  reg             dst_req_sync1;
  reg             dst_req_sync2;
  reg             dst_ack;
  reg [WIDTH-1:0] dst_data_hold;
  reg             dst_valid;

  // Synchronize ack from dst to src
  reg             src_ack_sync1;
  reg             src_ack_sync2;

  // Synchronize data from src to dst (two stages)
  reg [WIDTH-1:0] dst_data_sync1;
  reg [WIDTH-1:0] dst_data_sync2;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_hold <= {WIDTH{1'b0}};
      src_req       <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_hold <= src_data_i;
        src_req       <= 1'b1;
      end else if (src_ack) begin
        src_req       <= 1'b0;
      end
    end
  end

  assign src_ready_o = ~src_req;

  // Synchronize ack from dst domain to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ack_sync1 <= 1'b0;
      src_ack_sync2 <= 1'b0;
    end else begin
      src_ack_sync1 <= dst_ack;
      src_ack_sync2 <= src_ack_sync1;
    end
  end

  assign src_ack = src_ack_sync2;

  // Destination domain: synchronize request
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req_sync1 <= 1'b0;
      dst_req_sync2 <= 1'b0;
    end else begin
      dst_req_sync1 <= src_req;
      dst_req_sync2 <= dst_req_sync1;
    end
  end

  // Synchronize data from src to dst (two stages)
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_sync1 <= {WIDTH{1'b0}};
      dst_data_sync2 <= {WIDTH{1'b0}};
    end else begin
      dst_data_sync1 <= src_data_hold;
      dst_data_sync2 <= dst_data_sync1;
    end
  end

  // Destination domain: manage ack and valid
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack       <= 1'b0;
      dst_valid     <= 1'b0;
      dst_data_hold <= {WIDTH{1'b0}};
    end else begin
      if (dst_req_sync2 && !dst_ack) begin
        // New request arrived, capture data and assert valid
        dst_data_hold <= dst_data_sync2;
        dst_valid     <= 1'b1;
        dst_ack       <= 1'b1;
      end else if (dst_valid && dst_ready_i) begin
        // Transfer complete, deassert valid
        dst_valid     <= 1'b0;
        dst_ack       <= 1'b0;
      end
    end
  end

  assign dst_data_o  = dst_data_hold;
  assign dst_valid_o = dst_valid;

endmodule
