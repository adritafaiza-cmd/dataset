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
  reg [WIDTH-1:0] sync_data;
  reg sync_valid;
  reg sync_ready;

  // Source side of the CDC
  cdc_4phase_src #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) src_inst (
    .rst_ni(src_rst_ni),
    .clk_i(src_clk_i),
    .data_i(src_data_i),
    .valid_i(src_valid_i),
    .ready_o(src_ready_o),
    .sync_data_o(sync_data),
    .sync_valid_o(sync_valid),
    .sync_ready_i(sync_ready)
  );

  // Destination side of the CDC
  cdc_4phase_dst #(
    .WIDTH(WIDTH),
    .DECOUPLED(DECOUPLED),
    .SEND_RESET_MSG(SEND_RESET_MSG),
    .RESET_MSG(RESET_MSG)
  ) dst_inst (
    .rst_ni(dst_rst_ni),
    .clk_i(dst_clk_i),
    .data_o(dst_data_o),
    .valid_o(dst_valid_o),
    .ready_i(dst_ready_i),
    .sync_data_i(sync_data),
    .sync_valid_i(sync_valid),
    .sync_ready_o(sync_ready)
  );

endmodule

// Source side of the CDC 4-phase handshake
module cdc_4phase_src #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  rst_ni,
  input  clk_i,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output ready_o,
  output [WIDTH-1:0] sync_data_o,
  output sync_valid_o,
  input  sync_ready_i
);

  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg [1:0] phase;

  // Reset and phase transition logic
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      phase <= 2'b00;
      valid_reg <= 1'b0;
      data_reg <= RESET_MSG;
    end else begin
      case (phase)
        2'b00: begin
          if (valid_i) begin
            phase <= 2'b01;
            valid_reg <= 1'b1;
            data_reg <= data_i;
          end
        end
        2'b01: begin
          if (sync_ready_i) begin
            phase <= 2'b10;
          end
        end
        2'b10: begin
          phase <= 2'b11;
        end
        2'b11: begin
          phase <= 2'b00;
        end
      endcase
    end
  end

  // Output the data and valid signals for synchronization
  always @(*) begin
    sync_data_o = data_reg;
    sync_valid_o = valid_reg & (phase == 2'b01);
  end

  // Ready signal output
  assign ready_o = (phase == 2'b00);

endmodule

// Destination side of the CDC 4-phase handshake
module cdc_4phase_dst #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  rst_ni,
  input  clk_i,
  output [WIDTH-1:0] data_o,
  output data_valid_o,
  input  data_ready_i,
  input  [WIDTH-1:0] sync_data_i,
  input  sync_valid_i,
  output sync_ready_o
);

  reg [WIDTH-1:0] data_reg;
  reg valid_reg;
  reg [1:0] phase;

  // Reset and phase transition logic
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      phase <= 2'b00;
      valid_reg <= 1'b0;
      data_reg <= RESET_MSG;
    end else begin
      case (phase)
        2'b00: begin
          if (sync_valid_i) begin
            phase <= 2'b01;
            valid_reg <= 1'b1;
            data_reg <= sync_data_i;
          end
        end
        2'b01: begin
          if (data_ready_i) begin
            phase <= 2'b10;
          end
        end
        2'b10: begin
          phase <= 2'b11;
        end
        2'b11: begin
          phase <= 2'b00;
        end
      endcase
    end
  end

  // Output the data and valid signals
  always @(*) begin
    data_o = data_reg;
    data_valid_o = valid_reg & (phase == 2'b01);
  end

  // Ready signal output for synchronization
  assign sync_ready_o = (phase == 2'b00);

endmodule
