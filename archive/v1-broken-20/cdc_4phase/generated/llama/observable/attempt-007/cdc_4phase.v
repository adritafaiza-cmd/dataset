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

  logic src_valid_int;
  logic src_ready_int;
  logic [WIDTH-1:0] src_data_int;

  logic dst_valid_int;
  logic dst_ready_int;
  logic [WIDTH-1:0] dst_data_int;

  logic src_valid_sync;
  logic src_ready_sync;
  logic [WIDTH-1:0] src_data_sync;

  logic dst_valid_sync;
  logic dst_ready_sync;
  logic [WIDTH-1:0] dst_data_sync;

  logic src_valid_sync_2;
  logic src_ready_sync_2;
  logic [WIDTH-1:0] src_data_sync_2;

  logic dst_valid_sync_2;
  logic dst_ready_sync_2;
  logic [WIDTH-1:0] dst_data_sync_2;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_int <= 1'b0;
      src_ready_int <= 1'b0;
      src_data_int <= {WIDTH{1'b0}};
    end else begin
      src_valid_int <= src_valid_i;
      src_ready_int <= src_ready_o;
      src_data_int <= src_data_i;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_ready_sync <= 1'b0;
      src_data_sync <= {WIDTH{1'b0}};
    end else begin
      src_valid_sync <= src_valid_int;
      src_ready_sync <= src_ready_int;
      src_data_sync <= src_data_int;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync_2 <= 1'b0;
      src_ready_sync_2 <= 1'b0;
      src_data_sync_2 <= {WIDTH{1'b0}};
    end else begin
      src_valid_sync_2 <= src_valid_sync;
      src_ready_sync_2 <= src_ready_sync;
      src_data_sync_2 <= src_data_sync;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_int <= 1'b0;
      dst_ready_int <= 1'b0;
      dst_data_int <= {WIDTH{1'b0}};
    end else begin
      dst_valid_int <= src_valid_sync_2;
      dst_ready_int <= src_ready_sync_2;
      dst_data_int <= src_data_sync_2;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_ready_sync <= 1'b0;
      dst_data_sync <= {WIDTH{1'b0}};
    end else begin
      dst_valid_sync <= dst_valid_int;
      dst_ready_sync <= dst_ready_int;
      dst_data_sync <= dst_data_int;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync_2 <= 1'b0;
      dst_ready_sync_2 <= 1'b0;
      dst_data_sync_2 <= {WIDTH{1'b0}};
    end else begin
      dst_valid_sync_2 <= dst_valid_sync;
      dst_ready_sync_2 <= dst_ready_sync;
      dst_data_sync_2 <= dst_data_sync;
    end
  end

  always_comb begin
    src_ready_o = src_ready_int &&!src_valid_int || src_ready_sync &&!src_valid_sync;
    dst_valid_o = dst_valid_sync_2;
    dst_data_o = dst_data_sync_2;
  end

  always_comb begin
    if (SEND_RESET_MSG &&!src_rst_ni) begin
      src_valid_i = 1'b1;
      src_data_i = RESET_MSG;
    end else begin
      src_valid_i = src_valid_i;
      src_data_i = src_data_i;
    end
  end

  always_comb begin
    if (SEND_RESET_MSG &&!dst_rst_ni) begin
      dst_valid_o = 1'b1;
      dst_data_o = RESET_MSG;
    end else begin
      dst_valid_o = dst_valid_o;
      dst_data_o = dst_data_o;
    end
  end

  always_comb begin
    if (DECOUPLED) begin
      src_ready_int = src_ready_sync &&!src_valid_sync;
      dst_valid_int = dst_valid_sync_2 && dst_ready_sync_2;
    end else begin
      src_ready_int = src_ready_sync &&!src_valid_sync && dst_ready_sync_2;
      dst_valid_int = dst_valid_sync_2 && dst_ready_sync_2 && src_ready_sync;
    end
  end

endmodule
