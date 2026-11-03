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
  reg             src_req_pulse;

  // Destination side: receive request and generate response pulse
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_ack_pulse;

  // CDC synchronizers
  // Request: src -> dst
  reg [1:0] req_sync;
  // Ack: dst -> src
  reg [1:0] ack_sync;

  // Source clock domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_req_pulse <= 1'b0;
    end else begin
      // Generate request pulse when data is accepted
      if (src_valid_i && src_ready_o) begin
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
        src_req_pulse <= 1'b1;
      end else begin
        src_req_pulse <= 1'b0;
      end

      // Clear valid when ack is received
      if (ack_sync[1] && src_valid_reg) begin
        src_valid_reg <= 1'b0;
      end
    end
  end

  // Source ready: ready when no pending data
  assign src_ready_o = ~src_valid_reg;

  // Synchronize request from src to dst
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      req_sync <= 2'b00;
    end else begin
      req_sync <= {req_sync[0], src_req_pulse};
    end
  end

  // Destination clock domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ack_pulse <= 1'b0;
    end else begin
      // Detect rising edge of synchronized request
      if (req_sync[1] && !req_sync[0]) begin
        dst_data_reg  <= src_data_reg;
        dst_valid_reg <= 1'b1;
        dst_ack_pulse <= 1'b1;
      end else begin
        dst_ack_pulse <= 1'b0;
      end

      // Clear valid when data is accepted by receiver
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
      end
    end
  end

  // Destination outputs
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Synchronize ack from dst to src
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ack_sync <= 2'b00;
    end else begin
      ack_sync <= {ack_sync[0], dst_ack_pulse};
    end
  end

endmodule
