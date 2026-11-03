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

  logic [WIDTH-1:0] src_data_sync;
  logic [WIDTH-1:0] src_data_sync2;
  logic [WIDTH-1:0] src_data_sync3;
  logic [WIDTH-1:0] src_data_sync4;

  logic dst_valid_sync;
  logic dst_valid_sync2;
  logic dst_valid_sync3;
  logic dst_valid_sync4;

  logic dst_ready_sync;
  logic dst_ready_sync2;
  logic dst_ready_sync3;
  logic dst_ready_sync4;

  logic src_rst_sync;
  logic src_rst_sync2;
  logic src_rst_sync3;
  logic src_rst_sync4;

  logic dst_rst_sync;
  logic dst_rst_sync2;
  logic dst_rst_sync3;
  logic dst_rst_sync4;

  logic src_valid_pulse;
  logic dst_valid_pulse;

  logic src_valid_reg;
  logic src_valid_reg2;
  logic src_valid_reg3;
  logic src_valid_reg4;

  logic [WIDTH-1:0] src_data_reg;
  logic [WIDTH-1:0] src_data_reg2;
  logic [WIDTH-1:0] src_data_reg3;
  logic [WIDTH-1:0] src_data_reg4;

  logic dst_valid_reg;
  logic dst_valid_reg2;
  logic dst_valid_reg3;
  logic dst_valid_reg4;

  logic dst_ready_reg;
  logic dst_ready_reg2;
  logic dst_ready_reg3;
  logic dst_ready_reg4;

  logic src_rst_reg;
  logic src_rst_reg2;
  logic src_rst_reg3;
  logic src_rst_reg4;

  logic dst_rst_reg;
  logic dst_rst_reg2;
  logic dst_rst_reg3;
  logic dst_rst_reg4;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_valid_sync2 <= 1'b0;
      src_valid_sync3 <= 1'b0;
      src_valid_sync4 <= 1'b0;
      src_data_sync <= {WIDTH{1'b0}};
      src_data_sync2 <= {WIDTH{1'b0}};
      src_data_sync3 <= {WIDTH{1'b0}};
      src_data_sync4 <= {WIDTH{1'b0}};
      src_rst_sync <= 1'b1;
      src_rst_sync2 <= 1'b1;
      src_rst_sync3 <= 1'b1;
      src_rst_sync4 <= 1'b1;
    end else begin
      src_valid_sync <= src_valid_i;
      src_valid_sync2 <= src_valid_sync;
      src_valid_sync3 <= src_valid_sync2;
      src_valid_sync4 <= src_valid_sync3;
      src_data_sync <= src_data_i;
      src_data_sync2 <= src_data_sync;
      src_data_sync3 <= src_data_sync2;
      src_data_sync4 <= src_data_sync3;
      src_rst_sync <= 1'b0;
      src_rst_sync2 <= src_rst_sync;
      src_rst_sync3 <= src_rst_sync2;
      src_rst_sync4 <= src_rst_sync3;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_sync <= 1'b0;
      dst_valid_sync2 <= 1'b0;
      dst_valid_sync3 <= 1'b0;
      dst_valid_sync4 <= 1'b0;
      dst_ready_sync <= 1'b0;
      dst_ready_sync2 <= 1'b0;
      dst_ready_sync3 <= 1'b0;
      dst_ready_sync4 <= 1'b0;
      dst_rst_sync <= 1'b1;
      dst_rst_sync2 <= 1'b1;
      dst_rst_sync3 <= 1'b1;
      dst_rst_sync4 <= 1'b1;
    end else begin
      dst_valid_sync <= src_valid_sync4;
      dst_valid_sync2 <= dst_valid_sync;
      dst_valid_sync3 <= dst_valid_sync2;
      dst_valid_sync4 <= dst_valid_sync3;
      dst_ready_sync <= dst_ready_i;
      dst_ready_sync2 <= dst_ready_sync;
      dst_ready_sync3 <= dst_ready_sync2;
      dst_ready_sync4 <= dst_ready_sync3;
      dst_rst_sync <= src_rst_sync4;
      dst_rst_sync2 <= dst_rst_sync;
      dst_rst_sync3 <= dst_rst_sync2;
      dst_rst_sync4 <= dst_rst_sync3;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 1'b0;
      src_valid_reg2 <= 1'b0;
      src_valid_reg3 <= 1'b0;
      src_valid_reg4 <= 1'b0;
      src_data_reg <= {WIDTH{1'b0}};
      src_data_reg2 <= {WIDTH{1'b0}};
      src_data_reg3 <= {WIDTH{1'b0}};
      src_data_reg4 <= {WIDTH{1'b0}};
      src_rst_reg <= 1'b1;
      src_rst_reg2 <= 1'b1;
      src_rst_reg3 <= 1'b1;
      src_rst_reg4 <= 1'b1;
    end else begin
      src_valid_reg <= src_valid_i;
      src_valid_reg2 <= src_valid_reg;
      src_valid_reg3 <= src_valid_reg2;
      src_valid_reg4 <= src_valid_reg3;
      src_data_reg <= src_data_i;
      src_data_reg2 <= src_data_reg;
      src_data_reg3 <= src_data_reg2;
      src_data_reg4 <= src_data_reg3;
      src_rst_reg <= 1'b0;
      src_rst_reg2 <= src_rst_reg;
      src_rst_reg3 <= src_rst_reg2;
      src_rst_reg4 <= src_rst_reg3;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_valid_reg2 <= 1'b0;
      dst_valid_reg3 <= 1'b0;
      dst_valid_reg4 <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_ready_reg2 <= 1'b0;
      dst_ready_reg3 <= 1'b0;
      dst_ready_reg4 <= 1'b0;
      dst_rst_reg <= 1'b1;
      dst_rst_reg2 <= 1'b1;
      dst_rst_reg3 <= 1'b1;
      dst_rst_reg4 <= 1'b1;
    end else begin
      dst_valid_reg <= src_valid_sync4;
      dst_valid_reg2 <= dst_valid_reg;
      dst_valid_reg3 <= dst_valid_reg2;
      dst_valid_reg4 <= dst_valid_reg3;
      dst_ready_reg <= dst_ready_i;
      dst_ready_reg2 <= dst_ready_reg;
      dst_ready_reg3 <= dst_ready_reg2;
      dst_ready_reg4 <= dst_ready_reg3;
      dst_rst_reg <= src_rst_sync4;
      dst_rst_reg2 <= dst_rst_reg;
      dst_rst_reg3 <= dst_rst_reg2;
      dst_rst_reg4 <= dst_rst_reg3;
    end
  end

  assign src_valid_pulse = src_valid_sync4 && !dst_valid_sync4;
  assign dst_valid_pulse = dst_valid_sync4 && !dst_ready_sync4;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else if (src_valid_i && src_ready_o) begin
      src_ready_o <= 1'b0;
    end else if (src_valid_pulse) begin
      src_ready_o <= 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 1'b0;
      dst_data_o <= {WIDTH{1'b0}};
    end else if (dst_valid_pulse) begin
      dst_valid_o <= 1'b1;
      dst_data_o <= src_data_sync4;
    end else if (dst_ready_i && dst_valid_o) begin
      dst_valid_o <= 1'b0;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      if (SEND_RESET_MSG) begin
        src_data_o <= RESET_MSG;
      end else begin
        src_data_o <= {WIDTH{1'b0}};
      end
    end else if (src_valid_i && src_ready_o) begin
      src_data_o <= src_data_i;
    end
  end

endmodule
