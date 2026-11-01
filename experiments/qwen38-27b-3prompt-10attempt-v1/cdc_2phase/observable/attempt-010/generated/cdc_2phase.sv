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

  // Source side: hold data and valid when not ready
  reg [WIDTH-1:0] src_data_r;
  reg             src_valid_r;
  reg             src_ready_r;

  // Destination side: hold data and valid when not ready
  reg [WIDTH-1:0] dst_data_r;
  reg             dst_valid_r;
  reg             dst_ready_r;

  // CDC: source valid to destination
  // Use a 2-phase handshake with a single bit that toggles
  // Actually, let's use a simpler approach:
  // Source side: when src_valid_i is high and src_ready_r is high, capture data
  // Then assert a "pending" signal that crosses to destination
  // Destination side: when it sees pending, it can accept the data
  // After destination accepts, it deasserts pending (back to source)

  // Let's use a 2-phase valid/ready with CDC:
  // src_valid_r crosses to dst as dst_src_valid
  // dst_ready_r crosses to src as src_dst_ready

  // Source side logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r  <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
      src_ready_r <= 1'b1;
    end else begin
      if (src_valid_i && src_ready_r) begin
        src_data_r  <= src_data_i;
        src_valid_r <= 1'b1;
        src_ready_r <= 1'b0;
      end else if (!src_valid_i && src_ready_r) begin
        // Stay idle
      end else if (src_valid_r && src_dst_ready) begin
        // Destination has accepted, clear valid
        src_valid_r <= 1'b0;
        src_ready_r <= 1'b1;
      end
    end
  end

  assign src_ready_o = src_ready_r;

  // Destination side logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r  <= {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
      dst_ready_r <= 1'b1;
    end else begin
      if (dst_src_valid && dst_ready_r) begin
        dst_data_r  <= dst_src_data;
        dst_valid_r <= 1'b1;
        dst_ready_r <= 1'b0;
      end else if (!dst_src_valid && dst_ready_r) begin
        // Stay idle
      end else if (dst_valid_r && dst_ready_i) begin
        // Receiver has accepted, clear valid
        dst_valid_r <= 1'b0;
        dst_ready_r <= 1'b1;
      end
    end
  end

  assign dst_data_o  = dst_data_r;
  assign dst_valid_o = dst_valid_r;

  // CDC signals
  // src_valid_r needs to cross to dst domain
  // dst_ready_r needs to cross to src domain
  // src_data_r needs to cross to dst domain (but only valid when src_valid_r is high)

  // For the data, we can use a multi-bit synchronizer since the data is stable
  // while src_valid_r is high. We synchronize the data bits.

  // Synchronize src_valid_r to dst domain
  reg [1:0] src_valid_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_valid_sync <= 2'b00;
    else
      src_valid_sync <= {src_valid_sync[0], src_valid_r};
  end
  wire dst_src_valid = src_valid_sync[1];

  // Synchronize dst_ready_r to src domain
  reg [1:0] dst_ready_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_ready_sync <= 2'b00;
    else
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_r};
  end
  wire src_dst_ready = dst_ready_sync[1];

  // Synchronize src_data_r to dst domain
  // Data is stable when src_valid_r is high, so we can synchronize it
  reg [WIDTH-1:0] src_data_sync1;
  reg [WIDTH-1:0] src_data_sync2;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_data_sync1 <= {WIDTH{1'b0}};
      src_data_sync2 <= {WIDTH{1'b0}};
    end else begin
      src_data_sync1 <= src_data_r;
      src_data_sync2 <= src_data_sync1;
    end
  end
  wire [WIDTH-1:0] dst_src_data = src_data_sync2;

endmodule
