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
  wire [WIDTH-1:0] src_data_reg;
  wire src_valid_reg;
  wire src_ready_int;
  wire dst_valid_int;
  wire [WIDTH-1:0] dst_data_int;
  wire dst_ready_int;

  // Source domain: register data and valid
  reg [WIDTH-1:0] src_data_r;
  reg src_valid_r;
  reg src_ready_r;

  // Destination domain: register data and valid
  reg [WIDTH-1:0] dst_data_r;
  reg dst_valid_r;
  reg dst_ready_r;

  // CDC synchronizers for valid signal (src -> dst)
  reg [1:0] valid_sync;
  // CDC synchronizers for ready signal (dst -> src)
  reg [1:0] ready_sync;

  // Source domain logic
  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      src_data_r  <= {WIDTH{1'b0}};
      src_valid_r <= 1'b0;
      src_ready_r <= 1'b1;
    end else begin
      // If source is ready and valid, accept data
      if (src_ready_r && src_valid_i) begin
        src_data_r  <= src_data_i;
        src_valid_r <= 1'b1;
        src_ready_r <= 1'b0;
      end else if (!src_valid_r && ready_sync[1]) begin
        // Previous transfer completed, ready for next
        src_ready_r <= 1'b1;
      end else if (src_valid_r && ready_sync[1]) begin
        // Valid was high, now ready came back, clear valid
        src_valid_r <= 1'b0;
        src_ready_r <= 1'b1;
      end
    end
  end

  // Destination domain logic
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      dst_data_r  <= {WIDTH{1'b0}};
      dst_valid_r <= 1'b0;
      dst_ready_r <= 1'b1;
    end else begin
      // If destination is ready and valid from source, accept data
      if (dst_ready_r && valid_sync[1]) begin
        dst_data_r  <= src_data_r;
        dst_valid_r <= 1'b1;
        dst_ready_r <= 1'b0;
      end else if (!dst_valid_r && dst_ready_i) begin
        // Previous transfer completed, ready for next
        dst_ready_r <= 1'b1;
      end else if (dst_valid_r && dst_ready_i) begin
        // Valid was high, now ready came back, clear valid
        dst_valid_r <= 1'b0;
        dst_ready_r <= 1'b1;
      end
    end
  end

  // Synchronizers
  always @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      valid_sync <= 2'b00;
    end else begin
      valid_sync <= {valid_sync[0], src_valid_r};
    end
  end

  always @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      ready_sync <= 2'b00;
    end else begin
      ready_sync <= {ready_sync[0], dst_ready_r};
    end
  end

  // Outputs
  assign src_ready_o = src_ready_r;
  assign dst_data_o  = dst_data_r;
  assign dst_valid_o = dst_valid_r;

endmodule
