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

  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic src_handshake_reg;

  logic [WIDTH-1:0] dst_data_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic dst_handshake_reg;

  logic src_rst_sync;
  logic dst_rst_sync;

  logic src_rst_n;
  logic dst_rst_n;

  assign src_rst_n = ~src_rst_ni;
  assign dst_rst_n = ~dst_rst_ni;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_data_reg <= '0;
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_handshake_reg <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        src_handshake_reg <= 1'b1;
      end else if (src_handshake_reg && ~src_valid_i) begin
        src_handshake_reg <= 1'b0;
      end
      if (DECOUPLED) begin
        src_ready_reg <= 1'b1;
      end else if (src_handshake_reg) begin
        src_ready_reg <= 1'b0;
      end else if (src_valid_i) begin
        src_ready_reg <= 1'b1;
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_data_reg <= '0;
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_handshake_reg <= 1'b0;
      if (SEND_RESET_MSG) begin
        dst_data_reg <= RESET_MSG;
        dst_valid_reg <= 1'b1;
      end
    end else begin
      if (dst_valid_reg && dst_ready_i) begin
        dst_valid_reg <= 1'b0;
        dst_handshake_reg <= 1'b0;
      end else if (dst_handshake_reg && ~dst_valid_reg) begin
        dst_handshake_reg <= 1'b0;
      end
      if (dst_ready_i) begin
        dst_ready_reg <= 1'b0;
      end else if (~dst_valid_reg) begin
        dst_ready_reg <= 1'b1;
      end
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_rst_sync <= 1'b0;
    end else begin
      src_rst_sync <= dst_rst_n;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_rst_sync <= 1'b0;
    end else begin
      dst_rst_sync <= src_rst_n;
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_ready_o <= 1'b0;
    end else begin
      src_ready_o <= src_ready_reg;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_data_o <= '0;
      dst_valid_o <= 1'b0;
    end else begin
      if (dst_handshake_reg) begin
        dst_data_o <= src_data_reg;
        dst_valid_o <= 1'b1;
      end else if (dst_valid_reg && ~dst_ready_i) begin
        dst_data_o <= dst_data_reg;
      end else if (~dst_valid_reg) begin
        dst_data_o <= '0;
        dst_valid_o <= 1'b0;
      end
    end
  end

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (~src_rst_ni) begin
      src_handshake_reg <= 1'b0;
    end else if (src_valid_reg && src_ready_o) begin
      src_handshake_reg <= 1'b1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (~dst_rst_ni) begin
      dst_handshake_reg <= 1'b0;
    end else if (dst_valid_reg && dst_ready_i) begin
      dst_handshake_reg <= 1'b1;
    end
  end

endmodule
