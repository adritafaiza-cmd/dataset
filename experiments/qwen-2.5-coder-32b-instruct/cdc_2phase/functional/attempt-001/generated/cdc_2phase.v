module cdc_2phase #(
  parameter WIDTH = 1
)(
  input                  src_rst_ni,
  input                  src_clk_i,
  input      [WIDTH-1:0] src_data_i,
  input                  src_valid_i,
  output                 src_ready_o,

  input                  dst_rst_ni,
  input                  dst_clk_i,
  output     [WIDTH-1:0] dst_data_o,
  output                 dst_valid_o,
  input                  dst_ready_i
);

  // Internal signals
  logic [WIDTH-1:] data_ff;
  logic             valid_ff;
  logic             src_ready;
  logic             dst_valid;

  // Synchronizers for control signals
  logic src_valid_synced;
  logic dst_ready_synced;

  // Synchronize src_valid_i to dst_clk_i domain
  sync_cell u_src_valid_sync (
    .clk_i   (dst_clk_i),
    .rst_ni  (dst_rst_ni),
    .async_i (src_valid_i),
    .sync_o  (src_valid_synced)
  );

  // Synchronize dst_ready_i to src_clk_i domain
  sync_cell u_dst_ready_sync (
    .clk_i   (src_clk_i),
    .rst_ni  (src_rst_ni),
    .async_i (dst_ready_i),
    .sync_o  (dst_ready_synced)
  );

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
      data_ff   <= '0;
      valid_ff  <= 1'b0;
    end else begin
      if (src_valid_i && dst_ready_synced && !valid_ff) begin
        data_ff   <= src_data_i;
        valid_ff  <= 1'b1;
        src_ready <= 1'b0;
      end else if (dst_ready_synced && valid_ff) begin
        src_ready <= 1'b1;
      end else begin
        src_ready <= 1'b;
      end
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid <= 1'b0;
    end else begin
      if (src_valid_synced && !valid_ff) begin
        dst_valid <= 1'b1;
      end else if (dst_ready_i && dst_valid) begin
        dst_valid <= 1'b;
      end
    end
  end

  // Output assignments
  assign src_ready_o = src_ready;
  assign dst_valid_o = dst_valid;
  assign dst_data_o  = data_ff;

endmodule

// Synchronizer cell
module sync_cell (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic async_i,
  output logic sync_o
);

  logic meta;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      meta  <= 1'b0;
      sync_o <= 1'b0;
    end else begin
      meta  <= async_i;
      sync_o <= meta;
    end
  end

endmodule
