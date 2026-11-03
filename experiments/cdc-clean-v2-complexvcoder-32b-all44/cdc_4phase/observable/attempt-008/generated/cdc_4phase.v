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

  // Internal signals for synchronization
  logic [WIDTH-1:0] synced_data;
  logic synced_valid;

  // Instantiate the source side of the four-phase handshake
  cdc_4phase_src #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) src_inst (
    .src_rst_ni(src_rst_ni),
    .src_clk_i(src_clk_i),
    .src_data_i(src_data_i),
    .src_valid_i(src_valid_i),
    .src_ready_o(src_ready_o),
    .synced_data(synced_data),
    .synced_valid(synced_valid)
  );

  // Instantiate the destination side of the four-phase handshake
  cdc_4phase_dst #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) dst_inst (
    .dst_rst_ni(dst_rst_ni),
    .dst_clk_i(dst_clk_i),
    .synced_data(synced_data),
    .synced_valid(synced_valid),
    .dst_data_o(dst_data_o),
    .dst_valid_o(dst_valid_o),
    .dst_ready_i(dst_ready_i)
  );

endmodule

module cdc_4phase_src #(
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
  output [WIDTH-1:0] synced_data,
  output synced_valid
);

  logic [1:0] phase;
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_int;

  always_ff @(posedge src_clk_i or negedge src_rst_ni) begin
    if (!src_rst_ni) begin
      phase <= 2'b00;
      data_reg <= RESET_MSG;
      valid_reg <= 1'b0;
      ready_int <= 1'b0;
    end else begin
      // State machine for the source side
      case (phase)
        2'b00: begin
          if (src_valid_i && ready_int) begin
            data_reg <= src_data_i;
            valid_reg <= 1'b1;
            phase <= 2'b01;
          end
        end
        2'b01: begin
          if (dst_ready_i) begin
            phase <= 2'b10;
          end
        end
        2'b10: begin
          phase <= 2'b11;
        end
        2'b11: begin
          valid_reg <= 1'b0;
          phase <= 2'b00;
          ready_int <= 1'b1;
        end
        default: begin
          phase <= 2'b00;
        end
      endcase
    end
  end

  // Output assignments
  assign src_ready_o = ready_int;
  assign synced_data = data_reg;
  assign synced_valid = valid_reg;

endmodule

module cdc_4phase_dst #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  dst_rst_ni,
  input  dst_clk_i,
  input  [WIDTH-1:0] synced_data,
  input  synced_valid,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  logic [1:0] phase;
  logic [WIDTH-1:0] data_reg;
  logic valid_reg;
  logic ready_int;

  always_ff @(posedge dst_clk_i or negedge dst_rst_ni) begin
    if (!dst_rst_ni) begin
      phase <= 2'b00;
      data_reg <= RESET_MSG;
      valid_reg <= 1'b0;
      ready_int <= 1'b0;
    end else begin
      // State machine for the destination side
      case (phase)
        2'b00: begin
          if (synced_valid && ready_int) begin
            data_reg <= synced_data;
            valid_reg <= 1'b1;
            phase <= 2'b01;
          end
        end
        2'b01: begin
          if (dst_ready_i) begin
            phase <= 2'b10;
          end
        end
        2'b10: begin
          phase <= 2'b11;
        end
        2'b11: begin
          valid_reg <= 1'b0;
          phase <= 2'b00;
          ready_int <= 1'b1;
        end
        default: begin
          phase <= 2'b00;
        end
      endcase
    end
  end

  // Output assignments
  assign dst_data_o = data_reg;
  assign dst_valid_o = valid_reg;
  assign ready_int = 1'b1; // Always ready to accept new data in this simple implementation

endmodule
