module cdc_2phase #(
  parameter WIDTH = 1
) (
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

  // Source domain signals
  reg [WIDTH-1:0] src_data_reg;
  reg src_phase;
  reg dst_phase_sync1, dst_phase_sync2;

  // Destination domain signals
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_phase;
  reg phase_sync1, phase_sync2;
  reg phase_prev;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= '0;
      src_phase <= 0;
    end else begin
      if (src_valid_i && src_ready_o) begin
        src_data_reg <= src_data_i;
        src_phase <= ~src_phase;
      end
    end
  end

  // Synchronize dst_phase to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_phase_sync1 <= 0;
      dst_phase_sync2 <= 0;
    end else begin
      dst_phase_sync1 <= dst_phase;
      dst_phase_sync2 <= dst_phase_sync1;
    end
  end

  // Source ready is when the ack phase (after sync) equals src_phase
  assign src_ready_o = (dst_phase_sync2 == src_phase);

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      phase_sync1 <= 0;
      phase_sync2 <= 0;
      phase_prev <= 0;
      dst_data_reg <= 0;
      dst_phase <= 0;
    end else begin
      // Synchronize src_phase
      phase_sync1 <= src_phase;
      phase_sync2 <= phase_sync1;
      phase_prev <= phase_sync2;

      // Capture data when phase changes
      if (phase_sync2 != phase_prev) begin
        dst_data_reg <= src_data_reg;
      end

      // Toggle phase when data is accepted
      if (dst_valid_o && dst_ready_i) begin
        dst_phase <= ~dst_phase;
      end
    end
  end

  // Assign valid
  assign dst_valid_o = (phase_sync2 != phase_prev);

  // Assign outputs
  assign dst_data_o = dst_data_reg;

endmodule
