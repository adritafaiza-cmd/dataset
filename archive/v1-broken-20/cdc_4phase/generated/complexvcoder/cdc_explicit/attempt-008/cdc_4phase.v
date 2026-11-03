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
  reg [1:0] src_state;
  reg [1:0] dst_state;
  reg src_valid_reg;
  reg [WIDTH-1:0] src_data_reg;
  reg dst_valid_reg;
  reg [WIDTH-1:0] dst_data_reg;

  // State definitions
  localparam IDLE = 2'b00;
  localparam DATA_VALID = 2'b01;
  localparam DATA_TRANSMITTED = 2'b10;
  localparam RESET = 2'b11;

  // Source state machine
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= RESET;
    end else begin
      case (src_state)
        IDLE:
          if (src_valid_i && dst_ready_i) begin
            src_state <= DATA_VALID;
          end else if (!dst_ready_i) begin
            src_state <= DATA_VALID;
          end else begin
            src_state <= IDLE;
          end
        DATA_VALID:
          if (dst_ready_i) begin
            src_state <= DATA_TRANSMITTED;
          end else begin
            src_state <= DATA_VALID;
          end
        DATA_TRANSMITTED:
          if (!dst_ready_i) begin
            src_state <= DATA_TRANSMITTED;
          end else begin
            src_state <= IDLE;
          end
        RESET:
          src_state <= IDLE;
      endcase
    end
  end

  // Destination state machine
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= RESET;
    end else begin
      case (dst_state)
        IDLE:
          if (src_valid_reg && dst_ready_i) begin
            dst_state <= DATA_VALID;
          end else if (!dst_ready_i) begin
            dst_state <= DATA_VALID;
          end else begin
            dst_state <= IDLE;
          end
        DATA_VALID:
          if (dst_ready_i) begin
            dst_state <= DATA_TRANSMITTED;
          end else begin
            dst_state <= DATA_VALID;
          end
        DATA_TRANSMITTED:
          if (!dst_ready_i) begin
            dst_state <= DATA_TRANSMITTED;
          end else begin
            dst_state <= IDLE;
          end
        RESET:
          dst_state <= IDLE;
      endcase
    end
  end

  // Source valid signal handling
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_valid_reg <= 0;
    end else begin
      src_valid_reg <= src_valid_i;
    end
  end

  // Destination valid signal handling
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_reg <= 0;
    end else begin
      dst_valid_reg <= src_valid_reg;
    end
  end

  // Data handling
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= {WIDTH{1'b0}};
    end else begin
      src_data_reg <= src_data_i;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
    end else begin
      dst_data_reg <= src_data_reg;
    end
  end

  // Reset handling
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready_o <= 0;
    end else begin
      case (src_state)
        RESET:
          src_ready_o <= 0;
        default:
          src_ready_o <= 1;
      endcase
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_valid_o <= 0;
    end else begin
      case (dst_state)
        RESET:
          dst_valid_o <= 0;
        default:
          dst_valid_o <= 1;
      endcase
    end
  end

  // Send RESET_MSG after reset
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni && SEND_RESET_MSG) begin
      dst_data_o <= RESET_MSG;
    end
  end

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni && SEND_RESET_MSG) begin
      dst_data_o <= RESET_MSG;
    end
  end

endmodule
