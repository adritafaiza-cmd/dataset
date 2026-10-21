module cdc_2phase #(
  parameter WIDTH = 1
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

  // Source domain state machine
  // States: IDLE, WAIT_DST_READY
  localparam [1:0] STATE_IDLE = 2'b00;
  localparam [1:0] STATE_WAIT = 2'b01;

  reg [1:0] src_state;
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;

  // Destination domain state machine
  // States: IDLE, WAIT_SRC_VALID
  localparam [1:0] DST_IDLE = 2'b00;
  localparam [1:0] DST_WAIT = 2'b01;

  reg [1:0] dst_state;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_ready_reg;

  // Synchronize src_valid_i to destination clock domain
  reg [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_valid_sync <= 2'b00;
    else
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
  end

  // Synchronize dst_ready_i to source clock domain
  reg [1:0] dst_ready_sync;
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      dst_ready_sync <= 2'b00;
    else
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_i};
  end

  // Source Domain Logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_state <= STATE_IDLE;
      src_data_reg <= 0;
      src_valid_reg <= 0;
      src_ready_reg <= 1;
    end else begin
      case (src_state)
        STATE_IDLE: begin
          if (src_valid_i && dst_ready_sync[1]) begin
            src_state <= STATE_WAIT;
            src_data_reg <= src_data_i;
            src_valid_reg <= 1;
          end
          src_ready_reg <= 1;
        end
        STATE_WAIT: begin
          if (dst_ready_sync[1]) begin
            src_state <= STATE_IDLE;
            src_valid_reg <= 0;
            src_ready_reg <= 1;
          end else begin
            src_ready_reg <= 0;
          end
        end
      endcase
    end
  end

  // Destination Domain Logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_state <= DST_IDLE;
      dst_data_reg <= 0;
      dst_valid_reg <= 0;
      dst_ready_reg <= 1;
    end else begin
      case (dst_state)
        DST_IDLE: begin
          if (src_valid_sync[1]) begin
            dst_state <= DST_WAIT;
            dst_data_reg <= src_data_reg;
            dst_valid_reg <= 1;
          end
          dst_ready_reg <= 1;
        end
        DST_WAIT: begin
          if (dst_ready_i) begin
            dst_state <= DST_IDLE;
            dst_valid_reg <= 0;
            dst_ready_reg <= 1;
          end else begin
            dst_ready_reg <= 0;
          end
        end
      endcase
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule<|im_end|>
