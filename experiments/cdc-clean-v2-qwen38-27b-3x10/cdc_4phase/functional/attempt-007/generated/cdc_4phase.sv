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

  // Source domain state
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_ready_reg;
  reg             src_pending;

  // Destination domain state
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_ready_reg;
  reg             dst_pending;

  // CDC synchronizers
  // Source to destination: valid and data
  reg [WIDTH+1:0] src_to_dst_sync1;
  reg [WIDTH+1:0] src_to_dst_sync2;
  reg [WIDTH+1:0] src_to_dst_sync3;

  // Destination to source: ready
  reg             dst_to_src_sync1;
  reg             dst_to_src_sync2;
  reg             dst_to_src_sync3;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_pending   <= 1'b0;
    end else begin
      if (src_valid_i && src_ready_reg) begin
        // Accept new data
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
        src_ready_reg <= 1'b0;
        src_pending   <= 1'b1;
      end else if (src_pending && dst_to_src_sync3) begin
        // Destination has acknowledged, can accept next
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b1;
        src_pending   <= 1'b0;
      end
    end
  end

  assign src_ready_o = src_ready_reg;

  // Synchronize source valid+data to destination domain
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_to_dst_sync1 <= {(WIDTH+1){1'b0}};
      src_to_dst_sync2 <= {(WIDTH+1){1'b0}};
      src_to_dst_sync3 <= {(WIDTH+1){1'b0}};
    end else begin
      src_to_dst_sync1 <= {src_valid_reg, src_data_reg};
      src_to_dst_sync2 <= src_to_dst_sync1;
      src_to_dst_sync3 <= src_to_dst_sync2;
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg  <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      dst_valid_reg <= SEND_RESET_MSG ? 1'b1 : 1'b0;
      dst_ready_reg <= 1'b1;
      dst_pending   <= 1'b0;
    end else begin
      // Check if new data arrived from source
      if (src_to_dst_sync3[WIDTH] && !dst_valid_reg) begin
        // New data available, accept it
        dst_data_reg  <= src_to_dst_sync3[WIDTH-1:0];
        dst_valid_reg <= 1'b1;
        dst_ready_reg <= 1'b0;
        dst_pending   <= 1'b1;
      end else if (dst_valid_reg && dst_ready_i) begin
        // Destination consumed the data
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b1;
        dst_pending   <= 1'b0;
      end
    end
  end

  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Synchronize destination ready to source domain
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_to_src_sync1 <= 1'b1;
      dst_to_src_sync2 <= 1'b1;
      dst_to_src_sync3 <= 1'b1;
    end else begin
      dst_to_src_sync1 <= dst_ready_reg;
      dst_to_src_sync2 <= dst_to_src_sync1;
      dst_to_src_sync3 <= dst_to_src_sync2;
    end
  end

endmodule
