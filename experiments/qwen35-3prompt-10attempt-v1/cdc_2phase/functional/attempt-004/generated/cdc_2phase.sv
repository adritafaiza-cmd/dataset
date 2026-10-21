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
  localparam IDLE = 1'b0;
  localparam WAIT_DST_READY = 1'b1;

  reg src_state;
  reg [WIDTH-1:0] src_data_reg;

  // Destination domain state machine
  // States: IDLE, WAIT_SRC_VALID
  localparam DST_IDLE = 1'b0;
  localparam DST_WAIT_SRC_VALID = 1'b1;

  reg dst_state;
  reg [WIDTH-1:0] dst_data_reg;

  // Synchronize src_valid_i to destination domain
  reg [1:0] src_valid_sync;
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      src_valid_sync <= 2'b00;
    else
      src_valid_sync <= {src_valid_sync[0], src_valid_i};
  end

  // Synchronize dst_ready_i to source domain
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
      src_state <= IDLE;
      src_data_reg <= 0;
      src_ready_o <= 1'b1;
    end else begin
      case (src_state)
        IDLE: begin
          if (src_valid_i && dst_ready_sync[1]) begin
            src_state <= WAIT_DST_READY;
            src_data_reg <= src_data_i;
          end
          src_ready_o <= 1'b1;
        end
        WAIT_DST_READY: begin
          if (dst_ready_sync[1]) begin
            src_state <= IDLE;
            src_ready_o <= 1'b1;
          end else begin
            src_state <= IDLE;
            src_ready_o <= 1'b0;
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
      dst_valid_o <= 1'b0;
    end else begin
      case (dst_state)
        DST_IDLE: begin
          if (src_valid_sync[1]) begin
            dst_state <= DST_WAIT_SRC_VALID;
            dst_data_reg <= src_data_reg;
            dst_valid_o <= 1'b1;
          end
        end
        DST_WAIT_SRC_VALID: begin
          if (dst_ready_i) begin
            dst_state <= DST_IDLE;
            dst_valid_o <= 1'b0;
          end else begin
            dst_state <= DST_IDLE;
            dst_valid_o <= 1'b1;
          end
        end
      endcase
    end
  end

endmodule<|im_end|>
