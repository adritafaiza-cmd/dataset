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

  // Source side: capture data and generate request pulse
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_req;
  wire            src_req_pulse;

  // Destination side: acknowledge
  reg             dst_ack;
  wire            dst_ack_pulse;

  // Synchronizers
  reg [1:0] req_sync;
  reg [1:0] ack_sync;

  // Source clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_req       <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
        src_req       <= 1'b1;
      end else if (src_valid_reg && src_req && ack_sync[1]) begin
        src_valid_reg <= 1'b0;
        src_req       <= 1'b0;
      end
    end
  end

  assign src_ready_o = !src_valid_reg;

  // Synchronize request to destination clock
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync <= 2'b00;
    end else begin
      req_sync <= {req_sync[0], src_req};
    end
  end

  // Destination clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack <= 1'b0;
    end else begin
      if (req_sync[1] && !dst_ack) begin
        dst_ack <= 1'b1;
      end else if (dst_ack && !req_sync[1]) begin
        dst_ack <= 1'b0;
      end
    end
  end

  assign dst_valid_o = req_sync[1];
  assign dst_data_o  = src_data_reg;

  // Synchronize acknowledge to source clock
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync <= 2'b00;
    end else begin
      ack_sync <= {ack_sync[0], dst_ack};
    end
  end

endmodule
