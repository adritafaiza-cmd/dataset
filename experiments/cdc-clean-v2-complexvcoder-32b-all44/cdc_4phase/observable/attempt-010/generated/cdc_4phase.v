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

  wire [1:0] phase;

  phase_detector phase_det_inst (
    .clk_i    (src_clk_i),
    .ref_clk_i(dst_clk_i),
    .phase    (phase)
  );

  fifo fifo_inst (
    .clk_i         (src_clk_i),
    .rst_ni        (src_rst_ni),
    .data_i        (src_data_i),
    .valid_i       (src_valid_i),
    .ready_o       (src_ready_o),
    .ref_clk_i     (dst_clk_i),
    .ref_rst_ni    (dst_rst_ni),
    .data_o        (dst_data_o),
    .valid_o       (dst_valid_o),
    .ready_i       (dst_ready_i),
    .phase         (phase),
    .decoupled     (DECOUPLED),
    .send_reset_msg(SEND_RESET_MSG),
    .reset_msg     (RESET_MSG)
  );

endmodule

module phase_detector (
  input  clk_i,
  input  ref_clk_i,
  output reg [1:0] phase
);

  reg [1:0] ref_cnt;
  reg [1:0] phase_reg;

  always @(posedge clk_i) begin
    // Count reference clock edges within each source clock cycle
    if (ref_clk_i) begin
      ref_cnt <= ref_cnt + 1;
    end else begin
      ref_cnt <= 0;
    end

    // Determine phase difference based on ref_cnt
    case (ref_cnt)
      0: phase_reg <= 0;
      1: phase_reg <= 1;
      2: phase_reg <= 2;
      3: phase_reg <= 3;
      default: phase_reg <= 0;
    endcase
  end

  assign phase = phase_reg;

endmodule

module fifo #(
  parameter WIDTH = 1,
  parameter DECOUPLED = 1,
  parameter SEND_RESET_MSG = 0,
  parameter [WIDTH-1:0] RESET_MSG = {WIDTH{1'b0}}
)(
  input  clk_i,
  input  rst_ni,
  input  [WIDTH-1:0] data_i,
  input  valid_i,
  output reg ready_o,
  input  ref_clk_i,
  input  ref_rst_ni,
  output reg [WIDTH-1:0] data_o,
  output reg valid_o,
  input  ready_i,
  input  [1:0] phase,
  input  decoupled,
  input  send_reset_msg,
  input  [WIDTH-1:0] reset_msg
);

  reg [WIDTH-1:0] mem [3:0];
  reg [1:0] wr_ptr;
  reg [1:0] rd_ptr;
  reg full;
  reg empty;
  reg [3:0] valid_reg;
  reg [3:0] ready_reg;

  // Write side logic
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      wr_ptr <= 0;
      full <= 0;
      valid_reg <= 0;
    end else begin
      if (valid_i && ready_o) begin
        mem[wr_ptr] <= data_i;
        valid_reg[wr_ptr] <= 1;
        wr_ptr <= wr_ptr + 1;
        if (wr_ptr == rd_ptr) begin
          full <= 1;
        end else begin
          full <= 0;
        end
      end
    end
  end

  // Read side logic
  always @(posedge ref_clk_i or negedge ref_rst_ni) begin
    if (!ref_rst_ni) begin
      rd_ptr <= 0;
      empty <= 1;
      ready_reg <= 0;
      valid_o <= 0;
      data_o <= reset_msg;
    end else begin
      if (valid_reg[rd_ptr] && ready_i) begin
        data_o <= mem[rd_ptr];
        valid_o <= 1;
        valid_reg[rd_ptr] <= 0;
        rd_ptr <= rd_ptr + 1;
        if (wr_ptr == rd_ptr) begin
          empty <= 1;
        end else begin
          empty <= 0;
        end
      end else begin
        valid_o <= 0;
      end
    end
  end

  // Four-phase handshake logic
  always @(*) begin
    case (phase)
      2'b00: ready_o = !full;
      2'b01: ready_o = !full;
      2'b10: ready_o = !full;
      2'b11: ready_o = !full;
      default: ready_o = 0;
    endcase
  end

endmodule
