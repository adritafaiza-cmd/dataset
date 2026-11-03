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
  logic [WIDTH-1:0] src_data_reg [3:0];
  logic src_valid_reg [3:0];
  logic dst_ready_reg [3:0];

  // Source side logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_phase <= 2'b00;
      src_data_reg <= '{default: RESET_MSG};
      src_valid_reg <= '{default: 1'b0};
    end else begin
      // Update phase
      if (src_valid_i && src_ready_sync) begin
        src_phase <= src_phase + 1;
      end

      // Update data and valid
      if (src_valid_i && src_ready_sync) begin
        src_data_reg[src_phase] <= src_data_i;
        src_valid_reg[src_phase] <= 1'b1;
      end
    end
  end

  // Synchronize dst_ready_i to src_clk_i
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_reg <= '{default: 1'b0};
    end else begin
      dst_ready_reg[0] <= dst_ready_i;
      dst_ready_reg[1] <= dst_ready_reg[0];
      dst_ready_reg[2] <= dst_ready_reg[1];
      dst_ready_reg[3] <= dst_ready_reg[2];
    end
  end

  // Determine src_ready_o
  assign src_ready_o = ~src_valid_reg[src_phase] || dst_ready_reg[src_phase];

  // Destination side logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_phase <= 2'b00;
      dst_data_reg <= '{default: RESET_MSG};
      dst_valid_reg <= '{default: 1'b0};
    end else begin
      // Update phase
      if (dst_valid_sync && dst_ready_i) begin
        dst_phase <= dst_phase + 1;
      end

      // Update data and valid
      if (dst_valid_sync && dst_ready_i) begin
        dst_data_reg[dst_phase] <= dst_data_sync;
        dst_valid_reg[dst_phase] <= 1'b1;
      end
    end
  end

  // Synchronize src_valid_reg and src_data_reg to dst_clk_i
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 1'b0;
      src_data_sync <= RESET_MSG;
    end else begin
      src_valid_sync <= src_valid_reg[dst_phase];
      src_data_sync <= src_data_reg[dst_phase];
    end
  end

  // Determine dst_valid_o and dst_data_o
  assign dst_valid_o = src_valid_sync;
  assign dst_data_o = src_data_sync;

endmodule
