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

  // Internal signals
  logic [WIDTH-1:0] src_data_reg;
  logic src_valid_reg;
  logic src_ready_reg;
  logic dst_valid_reg;
  logic dst_ready_reg;
  logic [WIDTH-1:0] dst_data_reg;
  logic src_valid_next;
  logic src_ready_next;
  logic dst_valid_next;
  logic dst_ready_next;
  logic [1:0] src_phase;
  logic [1:0] dst_phase;

  // Clock domain crossing logic for source
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b0;
      src_phase <= 2'b00;
    end else begin
      src_data_reg <= src_data_i;
      src_valid_reg <= src_valid_i;
      src_ready_reg <= src_ready_o;
      src_phase <= src_phase + 1;
    end
  end

  // Clock domain crossing logic for destination
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b0;
      dst_data_reg <= {WIDTH{1'b0}};
      dst_phase <= 2'b00;
    end else begin
      dst_valid_reg <= dst_valid_o;
      dst_ready_reg <= dst_ready_i;
      dst_data_reg <= dst_data_i;
      dst_phase <= dst_phase + 1;
    end
  end

  // Combining logic to handle handshake and data transfer
  always_comb begin
    src_ready_o = 1'b0;
    dst_valid_o = 1'b0;
    dst_data_o = {WIDTH{1'b0}};

    if (src_phase == 2'b00) begin
      src_ready_o = src_valid_reg;
    end

    if (dst_phase == 2'b00) begin
      dst_valid_o = src_valid_reg;
      dst_data_o = src_data_reg;
    end

    if (dst_phase == 2'b10 && dst_ready_reg) begin
      dst_valid_o = 1'b0;
    end
  end

  // Reset handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_next <= 1'b0;
    end else begin
      src_valid_next <= src_valid_reg;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_next <= 1'b0;
    end else begin
      dst_valid_next <= dst_valid_reg;
    end
  end

  // SEND_RESET_MSG handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      if (SEND_RESET_MSG) begin
        src_data_reg <= RESET_MSG;
      end else begin
        src_data_reg <= {WIDTH{1'b0}};
      end
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      if (SEND_RESET_MSG) begin
        dst_data_reg <= RESET_MSG;
      end else begin
        dst_data_reg <= {WIDTH{1'b0}};
      end
    end
  end

endmodule
