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

  // Source side: capture data when valid and ready
  // Destination side: release when ready
  // Use a simple 2-phase handshake with a toggle bit for CDC

  // Source side registers
  reg [WIDTH-1:0] src_data_r;
  reg             src_valid_r;
  reg             src_toggle_r;

  // Destination side registers (synchronized)
  reg [WIDTH-1:0] dst_data_r;
  reg             dst_valid_r;
  reg             dst_toggle_r;

  // Synchronization of toggle from source to destination
  reg [2:0] src_toggle_sync;
  wire      src_toggle_synced = src_toggle_sync[2];

  // Synchronization of toggle from destination to source
  reg [2:0] dst_toggle_sync;
  wire      dst_toggle_synced = dst_toggle_sync[2];

  // Source side logic
  wire src_can_send = src_valid_i && !src_valid_r;
  wire src_ready = !src_valid_r;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r   <= {WIDTH{1'b0}};
      src_valid_r  <= 1'b0;
      src_toggle_r <= 1'b0;
    end else begin
      if (src_can_send) begin
        src_data_r   <= src_data_i;
        src_valid_r  <= 1'b1;
        src_toggle_r <= ~src_toggle_r;
      end else if (src_valid_r && dst_toggle_synced != src_toggle_r) begin
        // Destination has acknowledged, clear valid
        src_valid_r  <= 1'b0;
      end
    end
  end

  assign src_ready_o = src_ready;

  // Destination side logic
  wire dst_can_accept = dst_ready_i && !dst_valid_r;
  wire dst_valid = dst_valid_r;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r   <= {WIDTH{1'b0}};
      dst_valid_r  <= 1'b0;
      dst_toggle_r <= 1'b0;
    end else begin
      if (src_toggle_synced != dst_toggle_r) begin
        // New data arrived from source
        dst_data_r   <= src_data_r;
        dst_valid_r  <= 1'b1;
        dst_toggle_r <= src_toggle_synced;
      end else if (dst_valid_r && dst_can_accept) begin
        // Data accepted by destination, clear valid
        dst_valid_r  <= 1'b0;
      end
    end
  end

  assign dst_data_o  = dst_data_r;
  assign dst_valid_o = dst_valid;

  // Synchronizers
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_toggle_sync <= 3'b000;
    end else begin
      src_toggle_sync <= {src_toggle_sync[1:0], src_toggle_r};
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_toggle_sync <= 3'b000;
    end else begin
      dst_toggle_sync <= {dst_toggle_sync[1:0], dst_toggle_r};
    end
  end

endmodule
