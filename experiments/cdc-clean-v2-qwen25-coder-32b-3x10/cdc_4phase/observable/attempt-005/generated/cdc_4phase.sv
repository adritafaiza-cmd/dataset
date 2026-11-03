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

  // Source side signals
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready_sync;

  // Destination side signals
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_valid_sync;
  logic dst_ready_sync;

  // Four-phase handshake signals
  logic [1:0] src_phase;
  logic [1:0] dst_phase;

  // Synchronization registers
  logic [WIDTH-1:0] sync_data [3:0];
  logic sync_valid [3:0];
  logic sync_ready [3:0];

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_phase <= 2'b00;
      src_data_sync <= RESET_MSG;
      src_valid_sync <= SEND_RESET_MSG;
    end else begin
      // Update phase
      if (src_valid_i && src_ready_o) begin
        src_phase <= src_phase + 1;
      end

      // Update data and valid
      if (src_valid_i && src_ready_o) begin
        src_data_sync <= src_data_i;
        src_valid_sync <= 1'b1;
      end else if (sync_ready[src_phase]) begin
        src_valid_sync <= 1'b0;
      end
    end
  end

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_phase <= 2'b00;
      dst_data_sync <= RESET_MSG;
      dst_valid_sync <= SEND_RESET_MSG;
    end else begin
      // Update phase
      if (dst_valid_sync && dst_ready_i) begin
        dst_phase <= dst_phase + 1;
      end

      // Update data and valid
      if (sync_valid[dst_phase]) begin
        dst_data_sync <= sync_data[dst_phase];
        dst_valid_sync <= 1'b1;
      end else if (dst_ready_i) begin
        dst_valid_sync <= 1'b0;
      end
    end
  end

  // Synchronization logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      sync_data <= '{default: RESET_MSG};
      sync_valid <= '{default: 1'b0};
    end else begin
      sync_data[src_phase] <= src_data_sync;
      sync_valid[src_phase] <= src_valid_sync;
    end
  end

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      sync_ready <= '{default: 1'b0};
    end else begin
      sync_ready[dst_phase] <= dst_ready_i;
    end
  end

  // Ready signals
  assign src_ready_o = DECOUPLED ? ~sync_valid[src_phase] : ~src_valid_sync;
  assign dst_ready_sync = DECOUPLED ? ~sync_ready[dst_phase] : ~dst_ready_i;

  // Output assignments
  assign dst_data_o = dst_data_sync;
  assign dst_valid_o = dst_valid_sync;

endmodule
