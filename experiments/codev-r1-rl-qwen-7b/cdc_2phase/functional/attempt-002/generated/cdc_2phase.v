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

  // Source domain signals
  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg phase;
  reg phase_sync1, phase_sync2;

  // Destination domain signals
  reg [WIDTH-1:0] data_sync1, data_sync2;
  reg phase_sync3, phase_sync4;
  reg phase_dst;
  reg [WIDTH-1:0] data_dst;
  reg valid_dst;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      data_reg <= '0;
      valid_reg <= 1'b0;
      phase <= 1'b0;
      phase_sync1 <= 1'b0;
      phase_sync2 <= 1'b0;
    end else begin
      // Synchronize phase to destination
      phase_sync1 <= phase;
      phase_sync2 <= phase_sync1;

      // Capture data and toggle phase when valid and ready
      if (src_valid_i && src_ready_o) begin
        data_reg <= src_data_i;
        valid_reg <= 1'b1;
        phase <= ~phase;
      end else if (valid_reg && (phase == phase_sync2)) begin
        // Data accepted, clear valid
        valid_reg <= 1'b0;
      end
    end
  end

  assign src_ready_o = (phase == phase_sync2);

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      data_sync1 <= '0;
      data_sync2 <= '0;
      phase_sync3 <= 1'b0;
      phase_sync4 <= 1'b0;
      phase_dst <= 1'b0;
      data_dst <= '0;
      valid_dst <= 1'b0;
    end else begin
      // Synchronize data and phase
      data_sync1 <= data_reg;
      data_sync2 <= data_sync1;

      phase_sync3 <= phase;
      phase_sync4 <= phase_sync3;

      // Check phase change and update data
      if (phase_sync4 != phase_dst) begin
        data_dst <= data_sync2;
        valid_dst <= 1'b1;
        phase_dst <= ~phase_dst;
      end else begin
        valid_dst <= 1'b0;
      end

      // Clear valid when transfer occurs
      if (valid_dst && dst_ready_i) begin
        valid_dst <= 1'b0;
      end
    end
  end

  assign dst_data_o = data_dst;
  assign dst_valid_o = valid_dst;

endmodule
