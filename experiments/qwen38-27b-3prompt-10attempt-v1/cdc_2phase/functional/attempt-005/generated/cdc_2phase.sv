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

  // Source domain: capture data and generate request pulse
  reg [WIDTH-1:0] src_data_reg;
  reg             src_req;
  wire            src_accept;

  // Destination domain: track request and generate response pulse
  reg             dst_req;
  reg             dst_ack;
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;

  // Synchronizers for request (src -> dst)
  reg [1:0] req_sync;
  wire      req_synced = req_sync[1];

  // Synchronizers for response (dst -> src)
  reg [1:0] resp_sync;
  wire      resp_synced = resp_sync[1];

  // Source domain logic
  assign src_accept = src_valid_i & src_ready_o;
  assign src_ready_o = ~src_req | resp_synced;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_req      <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      if (src_accept) begin
        src_req      <= 1'b1;
        src_data_reg <= src_data_i;
      end else if (resp_synced) begin
        src_req <= 1'b0;
      end
    end
  end

  // Synchronize request to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync <= 2'b00;
    end else begin
      req_sync <= {req_sync[0], src_req};
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_req       <= 1'b0;
      dst_ack       <= 1'b0;
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
    end else begin
      // Detect rising edge of synchronized request
      if (req_synced && !dst_req) begin
        dst_req      <= 1'b1;
        dst_data_reg <= src_data_reg;
        dst_valid_reg <= 1'b1;
      end

      // When valid and ready, complete transfer and send ack
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
        dst_ack       <= 1'b1;
      end else if (dst_ack) begin
        dst_ack <= 1'b0;
      end

      // Clear request when ack is sent
      if (dst_ack) begin
        dst_req <= 1'b0;
      end
    end
  end

  // Synchronize response (ack) to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      resp_sync <= 2'b00;
    end else begin
      resp_sync <= {resp_sync[0], dst_ack};
    end
  end

  // Destination outputs
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
