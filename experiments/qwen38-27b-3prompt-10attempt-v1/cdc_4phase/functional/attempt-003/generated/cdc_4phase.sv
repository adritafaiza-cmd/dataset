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
  reg [WIDTH-1:0] src_data_reg;
  reg             src_valid_reg;
  reg             src_ready_reg;
  reg             src_ack_reg;

  // Destination domain signals
  reg [WIDTH-1:0] dst_data_reg;
  reg             dst_valid_reg;
  reg             dst_ack_reg;

  // CDC synchronizers for valid signal (src -> dst)
  reg [2:0] valid_sync;
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni)
      valid_sync <= 3'b000;
    else
      valid_sync <= {valid_sync[1:0], src_valid_reg};
  end

  // CDC synchronizers for ack signal (dst -> src)
  reg [2:0] ack_sync;
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni)
      ack_sync <= 3'b000;
    else
      ack_sync <= {ack_sync[1:0], dst_ack_reg};
  end

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg  <= {WIDTH{1'b0}};
      src_valid_reg <= 1'b0;
      src_ready_reg <= 1'b1;
      src_ack_reg   <= 1'b0;
    end else begin
      // Track ack from destination
      src_ack_reg <= ack_sync[2];

      if (src_valid_i && src_ready_reg) begin
        // Accept new data
        src_data_reg  <= src_data_i;
        src_valid_reg <= 1'b1;
        src_ready_reg <= 1'b0;
      end else if (src_valid_reg && src_ack_reg) begin
        // Previous transfer completed
        src_valid_reg <= 1'b0;
        src_ready_reg <= 1'b1;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg  <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ack_reg   <= 1'b0;
    end else begin
      if (valid_sync[2] && !dst_valid_reg) begin
        // New valid from source
        dst_data_reg  <= src_data_reg;
        dst_valid_reg <= 1'b1;
        dst_ack_reg   <= 1'b0;
      end else if (dst_valid_reg && dst_ready_i) begin
        // Destination accepted
        dst_valid_reg <= 1'b0;
        dst_ack_reg   <= 1'b1;
      end
    end
  end

  // Outputs
  assign src_ready_o = src_ready_reg;
  assign dst_data_o  = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

endmodule
