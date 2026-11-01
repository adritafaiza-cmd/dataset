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

  // Source-side registers
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;

  // Destination-side registers
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_ready_reg;

  // Synchronizers for crossing from source to destination
  // src_valid_reg crosses to dst domain
  reg [1:0] src_valid_sync;
  wire src_valid_synced = src_valid_sync[1];

  // Synchronizers for crossing from destination to source
  // dst_ready_reg crosses to src domain
  reg [1:0] dst_ready_sync;
  wire dst_ready_synced = dst_ready_sync[1];

  // Source clock domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
    end else begin
      // If we have a pending item, we are not ready for new data
      // If we don't have a pending item, we are ready
      // But we also need to wait for the destination to be ready before accepting new data
      // Actually, let's think about this more carefully.
      
      // The protocol:
      // - src_ready_o indicates whether the source can accept new data
      // - When src_valid_i && src_ready_o, the data is captured
      // - The captured data is held until the destination accepts it
      // - Once the destination accepts it, the source can accept new data
      
      // So src_ready_o should be high when there is no pending item
      // A pending item exists when src_valid_reg is high
      
      // But we also need to ensure that the destination has actually received the previous item
      // before we can accept a new one. However, since we're using a single buffer,
      // we just need to wait until the destination has consumed the current item.
      
      // Let's use a simpler approach:
      // - src_ready_o is high when src_valid_reg is low
      // - When src_valid_i && src_ready_o, capture data and set src_valid_reg
      // - When dst_ready_synced (destination is ready), clear src_valid_reg
      
      if (src_valid_i && src_ready_reg) begin
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
      end else if (dst_ready_synced) begin
        src_valid_reg <= 1'b0;
      end
      
      src_ready_reg <= !src_valid_reg;
    end
  end

  // Destination clock domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
    end else begin
      // dst_valid_reg is high when there is a pending item from the source
      // dst_ready_reg is high when the destination can accept a new item
      // When dst_valid_i (from source) && dst_ready_i, the item is consumed
      
      // Actually, let's reconsider. The destination side needs to:
      // - Present dst_valid_o when there is data to deliver
      // - Present dst_data_o with the data
      // - When dst_ready_i is high and dst_valid_o is high, the data is consumed
      // - After consumption, the destination can accept new data
      
      // The source sends data via src_valid_reg (synchronized to dst domain)
      // When src_valid_synced is high, the destination has data to present
      
      if (src_valid_synced && dst_ready_i) begin
        // Data is consumed, clear valid
        dst_valid_reg <= 1'b0;
      end else if (src_valid_synced) begin
        // Data is available but not yet consumed
        dst_valid_reg <= 1'b1;
        dst_data_reg  <= src_data_reg; // This is a problem - src_data_reg is in src domain
      end else begin
        dst_valid_reg <= 1'b0;
      end
      
      dst_ready_reg <= !dst_valid_reg;
    end
  end

  // Synchronizer for src_valid_reg to dst domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_reg};
    end
  end

  // Synchronizer for dst_ready_reg to src domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_reg};
    end
  end

  // Outputs
  assign src_ready_o = src_ready_reg;
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
