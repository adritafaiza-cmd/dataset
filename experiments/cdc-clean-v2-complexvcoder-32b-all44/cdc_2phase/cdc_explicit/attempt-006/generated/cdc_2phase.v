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

  // Internal signals
  reg [WIDTH-1:0] data_sync;
  reg valid_sync;
  reg valid_sync_reg;
  reg [WIDTH-1:0] data_sync_reg;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else begin
      src_ready_o <= !valid_sync; // Ready to accept new data if not already holding data
    end
  end

  // Cross domain synchronization for valid signal
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_sync <= 1'b0;
      valid_sync_reg <= 1'b0;
    end else begin
      valid_sync <= src_valid_i;
      valid_sync_reg <= valid_sync;
    end
  end

  // Cross domain synchronization for data signal
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_sync <= '0;
      data_sync_reg <= '0;
    end else begin
      if (src_valid_i && !valid_sync) begin // Only update data on new valid signal
        data_sync <= src_data_i;
      end
      data_sync_reg <= data_sync;
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= '0;
    end else begin
      if (dst_ready_i && valid_sync_reg) begin // Transfer complete
        dst_valid_o <= 1'b0;
      end else if (valid_sync_reg) begin // Hold valid and data
        dst_valid_o <= 1'b1;
        dst_data_o <= data_sync_reg;
      end else begin // No data to transfer
        dst_valid_o <= 1'b0;
      end
    end
  end

endmodule
