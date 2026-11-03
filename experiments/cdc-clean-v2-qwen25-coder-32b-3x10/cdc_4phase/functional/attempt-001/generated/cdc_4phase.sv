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

  // Source domain signals
  logic [WIDTH-1:0] src_data_sync;
  logic src_valid_sync;
  logic src_ready;

  // Destination domain signals
  logic [WIDTH-1:0] dst_data_sync;
  logic dst_valid_sync;
  logic dst_ready;

  // Synchronizers
  logic [WIDTH-1:0] src_data_sync_reg [3:0];
  logic src_valid_sync_reg [3:0];

  // Source domain
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_sync_reg <= '{default: {WIDTH{1'b0}}};
      src_valid_sync_reg <= '{default: 1'b0};
    end else begin
      src_data_sync_reg[0] <= src_data_i;
      src_valid_sync_reg[0] <= src_valid_i;
      src_data_sync_reg[1] <= src_data_sync_reg[0];
      src_valid_sync_reg[1] <= src_valid_sync_reg[0];
      src_data_sync_reg[2] <= src_data_sync_reg[1];
      src_valid_sync_reg[2] <= src_valid_sync_reg[1];
      src_data_sync_reg[3] <= src_data_sync_reg[2];
      src_valid_sync_reg[3] <= src_valid_sync_reg[2];
    end
  end

  assign src_data_sync = src_data_sync_reg[3];
  assign src_valid_sync = src_valid_sync_reg[3];

  // Source ready logic
  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_ready <= 1'b0;
    end else begin
      if (DECOUPLED) begin
        src_ready <= ~src_valid_sync | (src_valid_sync & dst_ready);
      end else begin
        src_ready <= ~src_valid_sync | (src_valid_sync & dst_ready & ~dst_valid_sync);
      end
    end
  end

  assign src_ready_o = src_ready;

  // Destination domain
  logic [WIDTH-1:0] dst_data_sync_reg [3:0];
  logic dst_valid_sync_reg [3:0];

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_sync_reg <= '{default: {WIDTH{1'b0}}};
      dst_valid_sync_reg <= '{default: 1'b0};
    end else begin
      dst_data_sync_reg[0] <= src_data_sync;
      dst_valid_sync_reg[0] <= src_valid_sync;
      dst_data_sync_reg[1] <= dst_data_sync_reg[0];
      dst_valid_sync_reg[1] <= dst_valid_sync_reg[0];
      dst_data_sync_reg[2] <= dst_data_sync_reg[1];
      dst_valid_sync_reg[2] <= dst_valid_sync_reg[1];
      dst_data_sync_reg[3] <= dst_data_sync_reg[2];
      dst_valid_sync_reg[3] <= dst_valid_sync_reg[2];
    end
  end

  assign dst_data_sync = dst_data_sync_reg[3];
  assign dst_valid_sync = dst_valid_sync_reg[3];

  // Destination valid and data logic
  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_o <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      dst_valid_o <= SEND_RESET_MSG;
    end else begin
      if (dst_valid_sync & dst_ready) begin
        dst_data_o <= dst_data_sync;
        dst_valid_o <= 1'b1;
      end else if (dst_ready) begin
        dst_valid_o <= 1'b0;
      end
    end
  end

endmodule
