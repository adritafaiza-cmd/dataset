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
  wire src_valid_int;
  wire [WIDTH-1:0] src_data_int;
  wire src_ready_int;
  wire dst_valid_int;
  wire [WIDTH-1:0] dst_data_int;
  wire dst_ready_int;

  // Source domain: handle reset message
  reg [WIDTH-1:0] src_data_reg;
  reg src_valid_reg;
  reg src_ready_reg;

  // Destination domain: handle reset message
  reg [WIDTH-1:0] dst_data_reg;
  reg dst_valid_reg;
  reg dst_ready_reg;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_reg <= SEND_RESET_MSG ? RESET_MSG : {WIDTH{1'b0}};
      src_valid_reg <= SEND_RESET_MSG;
      src_ready_reg <= 1'b1;
    end else begin
      if (src_valid_int && src_ready_int) begin
        // Accept new data
        src_data_reg <= src_data_i;
        src_valid_reg <= 1'b1;
        src_ready_reg <= 1'b0;
      end else if (src_ready_int && !src_valid_int) begin
        // Ready and no valid, stay ready
        src_ready_reg <= 1'b1;
      end else if (!src_valid_int && src_ready_int) begin
        // No valid, ready
        src_ready_reg <= 1'b1;
      end else begin
        // Wait for destination to accept
        if (dst_ready_int) begin
          src_ready_reg <= 1'b1;
          src_valid_reg <= 1'b0;
        end
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
      dst_valid_reg <= 1'b0;
      dst_ready_reg <= 1'b1;
    end else begin
      if (dst_valid_int && dst_ready_int) begin
        // Destination accepts
        dst_valid_reg <= 1'b0;
        dst_ready_reg <= 1'b1;
      end else if (!dst_valid_int) begin
        // No valid, ready
        dst_ready_reg <= 1'b1;
      end else begin
        // Valid but not ready, wait
        dst_ready_reg <= 1'b0;
      end
    end
  end

  // CDC: source valid/data to destination
  // Use 2-flop synchronizers for control signals
  // Data must be stable when valid is asserted

  // Source to destination: valid and data
  reg [1:0] src_valid_sync;
  reg [WIDTH-1:0] src_data_sync;

  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      src_valid_sync <= 2'b00;
      src_data_sync <= {WIDTH{1'b0}};
    end else begin
      src_valid_sync <= {src_valid_sync[0], src_valid_reg};
      // Data is only sampled when valid is stable
      if (src_valid_sync[1] != src_valid_sync[0]) begin
        // Transition detected, sample data
        src_data_sync <= src_data_reg;
      end
    end
  end

  // Destination to source: ready
  reg [1:0] dst_ready_sync;

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      dst_ready_sync <= 2'b00;
    end else begin
      dst_ready_sync <= {dst_ready_sync[0], dst_ready_reg};
    end
  end

  // Assign outputs
  assign src_ready_o = src_ready_reg;
  assign dst_data_o = dst_data_reg;
  assign dst_valid_o = dst_valid_reg;

  // Internal signals for CDC
  assign src_valid_int = src_valid_sync[1];
  assign src_data_int = src_data_sync;
  assign dst_ready_int = dst_ready_sync[1];

  // Update destination data when valid arrives
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_reg <= {WIDTH{1'b0}};
    end else begin
      if (src_valid_sync[1] && !dst_valid_reg) begin
        dst_data_reg <= src_data_sync;
        dst_valid_reg <= 1'b1;
      end
    end
  end

endmodule
