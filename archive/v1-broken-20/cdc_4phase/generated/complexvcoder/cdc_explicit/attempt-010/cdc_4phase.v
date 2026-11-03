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
  logic dst_valid_reg;
  logic [WIDTH-1:0] dst_data_reg;

  // Source phase 1: Clock domain crossing for source valid/ready
  logic src_valid_1;
  logic src_ready_1;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_1 <= 0;
      src_ready_1 <= 1;
    end else begin
      src_valid_1 <= src_valid_i;
      src_ready_1 <= src_ready_o;
    end
  end

  // Source phase 2: Clock domain crossing for source data
  logic [WIDTH-1:0] src_data_2;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_2 <= {WIDTH{1'b0}};
    end else begin
      src_data_2 <= src_data_i;
    end
  end

  // Source phase 3: Clock domain crossing for source valid/ready
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_ready_o <= 1;
    end else begin
      src_valid_reg <= src_valid_1;
      src_ready_o <= src_ready_1;
    end
  end

  // Source phase 4: Clock domain crossing for source data
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      src_data_reg <= src_data_2;
    end
  end

  // Destination phase 1: Clock domain crossing for destination valid/ready
  logic dst_valid_1;
  logic dst_ready_1;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_1 <= 0;
      dst_ready_1 <= 1;
    end else begin
      dst_valid_1 <= dst_valid_o;
      dst_ready_1 <= dst_ready_i;
    end
  end

  // Destination phase 2: Clock domain crossing for destination data
  logic [WIDTH-1:0] dst_data_2;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_2 <= {WIDTH{1'b0}};
    end else begin
      dst_data_2 <= dst_data_reg;
    end
  end

  // Destination phase 3: Clock domain crossing for destination valid/ready
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_ready_o <= 1;
    end else begin
      dst_valid_reg <= dst_valid_1;
      dst_ready_o <= dst_ready_1;
    end
  end

  // Destination phase 4: Clock domain crossing for destination data
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= {WIDTH{1'b0}};
    end else begin
      dst_data_o <= dst_data_2;
    end
  end

  // Handshake mechanism
  assign dst_valid_o = src_valid_reg;
  assign src_ready_o = dst_ready_reg;

  // Reset handling
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
      src_ready_o <= 1;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
      dst_ready_o <= 1;
    end
  end

endmodule
