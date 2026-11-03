module cdc_4phase #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
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

  logic src_valid_sync;
  logic src_valid_sync2;
  logic src_valid_sync3;
  logic src_valid_sync4;
  logic src_valid_sync5;
  logic src_valid_sync6;
  logic src_valid_sync7;

  logic src_data_sync;
  logic src_data_sync2;
  logic src_data_sync3;
  logic src_data_sync4;
  logic src_data_sync5;
  logic src_data_sync6;
  logic src_data_sync7;

  logic dst_valid;
  logic dst_valid2;
  logic dst_valid3;
  logic dst_valid4;
  logic dst_valid5;
  logic dst_valid6;
  logic dst_valid7;

  logic dst_data;
  logic dst_data2;
  logic dst_data3;
  logic dst_data4;
  logic dst_data5;
  logic dst_data6;
  logic dst_data7;

  logic src_ready;
  logic src_ready2;
  logic src_ready3;
  logic src_ready4;
  logic src_ready5;
  logic src_ready6;
  logic src_ready7;

  logic dst_rst_sync;
  logic dst_rst_sync2;
  logic dst_rst_sync3;
  logic dst_rst_sync4;
  logic dst_rst_sync5;
  logic dst_rst_sync6;
  logic dst_rst_sync7;

  logic src_rst_sync;
  logic src_rst_sync2;
  logic src_rst_sync3;
  logic src_rst_sync4;
  logic src_rst_sync5;
  logic src_rst_sync6;
  logic src_rst_sync7;

  logic send_reset_msg;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_rst_sync <= 1'b1;
      src_rst_sync2 <= 1'b1;
      src_rst_sync3 <= 1'b1;
      src_rst_sync4 <= 1'b1;
      src_rst_sync5 <= 1'b1;
      src_rst_sync6 <= 1'b1;
      src_rst_sync7 <= 1'b1;
    end else begin
      src_rst_sync <= 1'b0;
      src_rst_sync2 <= src_rst_sync;
      src_rst_sync3 <= src_rst_sync2;
      src_rst_sync4 <= src_rst_sync3;
      src_rst_sync5 <= src_rst_sync4;
      src_rst_sync6 <= src_rst_sync5;
      src_rst_sync7 <= src_rst_sync6;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_rst_sync <= 1'b1;
      dst_rst_sync2 <= 1'b1;
      dst_rst_sync3 <= 1'b1;
      dst_rst_sync4 <= 1'b1;
      dst_rst_sync5 <= 1'b1;
      dst_rst_sync6 <= 1'b1;
      dst_rst_sync7 <= 1'b1;
    end else begin
      dst_rst_sync <= 1'b0;
      dst_rst_sync2 <= dst_rst_sync;
      dst_rst_sync3 <= dst_rst_sync2;
      dst_rst_sync4 <= dst_rst_sync3;
      dst_rst_sync5 <= dst_rst_sync4;
      dst_rst_sync6 <= dst_rst_sync5;
      dst_rst_sync7 <= dst_rst_sync6;
    end
  end

  always_ff @(posedge src_clk_i) begin
    if (src_rst_sync7) begin
      src_valid_sync <= 1'b0;
      src_valid_sync2 <= 1'b0;
      src_valid_sync3 <= 1'b0;
      src_valid_sync4 <= 1'b0;
      src_valid_sync5 <= 1'b0;
      src_valid_sync6 <= 1'b0;
      src_valid_sync7 <= 1'b0;
    end else begin
      src_valid_sync <= src_valid_i;
      src_valid_sync2 <= src_valid_sync;
      src_valid_sync3 <= src_valid_sync2;
      src_valid_sync4 <= src_valid_sync3;
      src_valid_sync5 <= src_valid_sync4;
      src_valid_sync6 <= src_valid_sync5;
      src_valid_sync7 <= src_valid_sync6;
    end
  end

  always_ff @(posedge src_clk_i) begin
    if (src_rst_sync7) begin
      src_data_sync <= RESET_MSG;
      src_data_sync2 <= RESET_MSG;
      src_data_sync3 <= RESET_MSG;
      src_data_sync4 <= RESET_MSG;
      src_data_sync5 <= RESET_MSG;
      src_data_sync6 <= RESET_MSG;
      src_data_sync7 <= RESET_MSG;
    end else begin
      src_data_sync <= src_data_i;
      src_data_sync2 <= src_data_sync;
      src_data_sync3 <= src_data_sync2;
      src_data_sync4 <= src_data_sync3;
      src_data_sync5 <= src_data_sync4;
      src_data_sync6 <= src_data_sync5;
      src_data_sync7 <= src_data_sync6;
    end
  end

  always_ff @(posedge dst_clk_i) begin
    if (dst_rst_sync7) begin
      dst_valid <= 1'b0;
      dst_valid2 <= 1'b0;
      dst_valid3 <= 1'b0;
      dst_valid4 <= 1'b0;
      dst_valid5 <= 1'b0;
      dst_valid6 <= 1'b0;
      dst_valid7 <= 1'b0;
    end else begin
      dst_valid <= src_valid_sync7;
      dst_valid2 <= dst_valid;
      dst_valid3 <= dst_valid2;
      dst_valid4 <= dst_valid3;
      dst_valid5 <= dst_valid4;
      dst_valid6 <= dst_valid5;
      dst_valid7 <= dst_valid6;
    end
  end

  always_ff @(posedge dst_clk_i) begin
    if (dst_rst_sync7) begin
      dst_data <= RESET_MSG;
      dst_data2 <= RESET_MSG;
      dst_data3 <= RESET_MSG;
      dst_data4 <= RESET_MSG;
      dst_data5 <= RESET_MSG;
      dst_data6 <= RESET_MSG;
      dst_data7 <= RESET_MSG;
    end else begin
      dst_data <= src_data_sync7;
      dst_data2 <= dst_data;
      dst_data3 <= dst_data2;
      dst_data4 <= dst_data3;
      dst_data5 <= dst_data4;
      dst_data6 <= dst_data5;
      dst_data7 <= dst_data6;
    end
  end

  always_ff @(posedge src_clk_i) begin
    if (src_rst_sync7) begin
      src_ready <= 1'b0;
      src_ready2 <= 1'b0;
      src_ready3 <= 1'b0;
      src_ready4 <= 1'b0;
      src_ready5 <= 1'b0;
      src_ready6 <= 1'b0;
      src_ready7 <= 1'b0;
    end else begin
      src_ready <= dst_valid7 && dst_ready_i;
      src_ready2 <= src_ready;
      src_ready3 <= src_ready2;
      src_ready4 <= src_ready3;
      src_ready5 <= src_ready4;
      src_ready6 <= src_ready5;
      src_ready7 <= src_ready6;
    end
  end

  always_ff @(posedge dst_clk_i) begin
    if (dst_rst_sync7) begin
      send_reset_msg <= SEND_RESET_MSG;
    end else begin
      send_reset_msg <= 1'b0;
    end
  end

  assign src_ready_o = src_ready7;
  assign dst_data_o = (send_reset_msg && dst_rst_sync7) ? RESET_MSG : dst_data7;
  assign dst_valid_o = (send_reset_msg && dst_rst_sync7) ? 1'b1 : dst_valid7;

endmodule
