module cdc_bit_sync (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic async_i,
  output logic sync_o
);

  logic sync_ff1;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      sync_ff1 <= 1'b0;
      sync_o   <= 1'b0;
    end else begin
      sync_ff1 <= async_i;
      sync_o   <= sync_ff1;
    end
  end

endmodule


module cdc_2phase #(
  parameter WIDTH = 1
)(
  input  logic             src_rst_ni,
  input  logic             src_clk_i,
  input  logic [WIDTH-1:0] src_data_i,
  input  logic             src_valid_i,
  output logic             src_ready_o,

  input  logic             dst_rst_ni,
  input  logic             dst_clk_i,
  output logic [WIDTH-1:0] dst_data_o,
  output logic             dst_valid_o,
  input  logic             dst_ready_i
);

  logic [WIDTH-1:0] src_data_hold;
  logic             src_req_toggle;
  logic             src_ack_sync;

  logic             dst_req_sync;
  logic             dst_ack_toggle;

  cdc_bit_sync u_sync_req (
    .clk_i   (dst_clk_i),
    .rst_ni  (dst_rst_ni),
    .async_i (src_req_toggle),
    .sync_o  (dst_req_sync)
  );

  cdc_bit_sync u_sync_ack (
    .clk_i   (src_clk_i),
    .rst_ni  (src_rst_ni),
    .async_i (dst_ack_toggle),
    .sync_o  (src_ack_sync)
  );

  always_comb begin
    src_ready_o = src_rst_ni &&
                  (src_req_toggle == src_ack_sync);
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_hold  <= '0;
      src_req_toggle <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_data_hold  <= src_data_i;
      src_req_toggle <= ~src_req_toggle;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o     <= '0;
      dst_valid_o    <= 1'b0;
      dst_ack_toggle <= 1'b0;
    end else begin
      if (dst_valid_o) begin
        if (dst_ready_i) begin
          dst_valid_o    <= 1'b0;
          dst_ack_toggle <= dst_req_sync;
        end
      end else if (dst_req_sync != dst_ack_toggle) begin
        dst_data_o  <= src_data_hold;
        dst_valid_o <= 1'b1;
      end
    end
  end

endmodule
