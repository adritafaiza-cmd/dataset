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
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg phase0, phase1, phase2, phase3;
  reg phase0_sync, phase1_sync, phase2_sync, phase3_sync;
  reg src_reset_active;
  reg dst_reset_active;

  // Synchronization logic for phases
  reg [3:0] phase_src, phase_dst;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_reset_active <= 1'b1;
      src_data_reg <= RESET_MSG;
      src_valid_reg <= SEND_RESET_MSG;
      src_ready_reg <= 1'b0;
      phase_src <= 4'b0000;
    end else begin
      src_reset_active <= 1'b0;

      // Phase generation
      phase_src <= {phase_src[2:0], ~phase_src[3]};

      // Synchronize phases
      phase0_sync <= phase_src[0];
      phase1_sync <= phase_src[1];
      phase2_sync <= phase_src[2];
      phase3_sync <= phase_src[3];

      // Handle reset message
      if (src_reset_active && SEND_RESET_MSG) begin
        src_data_reg <= RESET_MSG;
        src_valid_reg <= 1'b1;
      end else begin
        // Handle data transfer
        if (src_valid_i && src_ready_o) begin
          src_data_reg <= src_data_i;
          src_valid_reg <= 1'b1;
        end else begin
          src_valid_reg <= 1'b0;
        end
      end

      // Ready signal
      if (DECOUPLED) begin
        src_ready_reg <= 1'b1;
      end else begin
        src_ready_reg <= !src_valid_reg;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_reset_active <= 1'b1;
      dst_data_reg <= RESET_MSG;
      dst_valid_reg <= SEND_RESET_MSG;
      phase_dst <= 4'b0000;
    end else begin
      dst_reset_active <= 1'b0;

      // Phase generation
      phase_dst <= {phase_dst[2:0], ~phase_dst[3]};

      // Synchronize phases
      phase0 <= phase0_sync;
      phase1 <= phase1_sync;
      phase2 <= phase2_sync;
      phase3 <= phase3_sync;

      // Handle reset message
      if (dst_reset_active && SEND_RESET_MSG) begin
        dst_data_reg <= RESET_MSG;
        dst_valid_reg <= 1'b1;
      end else begin
        // Handle data transfer
        if (phase0 && !phase1) begin
          dst_data_reg <= src_data_reg;
          dst_valid_reg <= src_valid_reg;
        end else if (phase1 && !phase2 && dst_ready_i) begin
          dst_valid_reg <= 1'b0;
        end
      end
    end
  end

  // Output assignments
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
