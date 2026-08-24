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

  logic [WIDTH-1:0] src_data_hold;
  logic             src_req_toggle;

  logic             src_ack_sync_ff1;
  logic             src_ack_sync_ff2;

  logic             dst_req_sync_ff1;
  logic             dst_req_sync_ff2;
  logic             dst_ack_toggle;

  logic [WIDTH-1:0] dst_data_reg;
  logic             dst_valid_reg;

  assign src_ready_o = (src_req_toggle == src_ack_sync_ff2);
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ack_sync_ff1 <= 1'b0;
      src_ack_sync_ff2 <= 1'b0;
    end else begin
      src_ack_sync_ff1 <= dst_ack_toggle;
      src_ack_sync_ff2 <= src_ack_sync_ff1;
    end
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
      dst_req_sync_ff1 <= 1'b0;
      dst_req_sync_ff2 <= 1'b0;
    end else begin
      dst_req_sync_ff1 <= src_req_toggle;
      dst_req_sync_ff2 <= dst_req_sync_ff1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_ack_toggle <= 1'b0;
      dst_data_reg   <= '0;
      dst_valid_reg  <= 1'b0;
    end else begin
      if (dst_valid_reg) begin
        if (dst_ready_i) begin
          dst_valid_reg  <= 1'b0;
          dst_ack_toggle <= dst_req_sync_ff2;
        end
      end else if (dst_req_sync_ff2 != dst_ack_toggle) begin
        dst_data_reg  <= src_data_hold;
        dst_valid_reg <= 1'b1;
      end
    end
  end

endmodule
