module cdc_2phase_clearable #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3,
  parameter CLEAR_ON_ASYNC_RESET = 1
)(
  input  src_rst_ni,
  input  src_clk_i,
  input  src_clear_i,
  output src_clear_pending_o,
  input  [WIDTH-1:0] src_data_i,
  input  src_valid_i,
  output src_ready_o,
  input  dst_rst_ni,
  input  dst_clk_i,
  input  dst_clear_i,
  output dst_clear_pending_o,
  output [WIDTH-1:0] dst_data_o,
  output dst_valid_o,
  input  dst_ready_i
);

  // Internal signals for reset synchronization
  wire dst_src_rst_ni;
  wire src_dst_rst_ni;

  // Internal signals for clear control
  wire fifo_src_clear;
  wire fifo_dst_clear;

  // Instantiate the reset synchronizers
  async_reset_synchronizer src_reset_sync (
    .async_in(src_rst_ni),
    .clk(dst_clk_i),
    .sync_out(dst_src_rst_ni)
  );

  async_reset_synchronizer dst_reset_sync (
    .async_in(dst_rst_ni),
    .clk(src_clk_i),
    .sync_out(src_dst_rst_ni)
  );

  // Instantiate the FIFO
  cdc_fifo #(.WIDTH(WIDTH)) fifo (
    .wr_clk(src_clk_i),
    .wr_rst_ni(src_rst_ni),
    .din(src_data_i),
    .wr_en(src_valid_i),
    .wr_full_n(src_ready_o),
    .rd_clk(dst_clk_i),
    .rd_rst_ni(dst_rst_ni),
    .dout(dst_data_o),
    .rd_en(dst_valid_o),
    .rd_empty_n(dst_ready_i),
    .clear_i(fifo_src_clear | fifo_dst_clear)
  );

  // Instantiate the clear control modules
  clear_control src_clear_control (
    .clk(src_clk_i),
    .rst_ni(src_rst_ni),
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_pending_o),
    .clear_o(fifo_src_clear)
  );

  clear_control dst_clear_control (
    .clk(dst_clk_i),
    .rst_ni(dst_rst_ni),
    .clear_i(dst_clear_i),
    .clear_pending_o(dst_clear_pending_o),
    .clear_o(fifo_dst_clear)
  );

endmodule

module async_reset_synchronizer (
  input  async_in,
  input  clk,
  output sync_out
);

  reg sync_stage_1;
  reg sync_stage_2;
  reg sync_stage_3;

  always @(posedge clk) begin
    sync_stage_1 <= async_in;
    sync_stage_2 <= sync_stage_1;
    sync_stage_3 <= sync_stage_2;
  end

  assign sync_out = sync_stage_3;

endmodule

module cdc_fifo #(
  parameter WIDTH = 1
)(
  input  wr_clk,
  input  wr_rst_ni,
  input  [WIDTH-1:0] din,
  input  wr_en,
  output wr_full_n,
  input  rd_clk,
  input  rd_rst_ni,
  output [WIDTH-1:0] dout,
  input  rd_en,
  output rd_empty_n,
  input  clear_i
);

  reg [WIDTH-1:0] mem [0:(2**SYNC_STAGES)-1];
  reg [SYNC_STAGES-1:0] wr_ptr;
  reg [SYNC_STAGES-1:0] rd_ptr;
  reg [SYNC_STAGES-1:0] wr_ptr_gray;
  reg [SYNC_STAGES-1:0] rd_ptr_gray;
  reg [SYNC_STAGES-1:0] wr_ptr_gray_sync;
  reg [SYNC_STAGES-1:0] rd_ptr_gray_sync;
  reg wr_full;
  reg rd_empty;

  // Binary to Gray conversion
  function [SYNC_STAGES-1:0] bin_to_gray;
    input [SYNC_STAGES-1:0] bin;
    bin_to_gray = bin ^ (bin >> 1);
  endfunction

  // Gray to Binary conversion
  function [SYNC_STAGES-1:0] gray_to_bin;
    input [SYNC_STAGES-1:0] gray;
    integer i;
    reg [SYNC_STAGES-1:0] bin;
    bin = gray;
    for (i = SYNC_STAGES-2; i >= 0; i = i - 1) begin
      bin[i] = bin[i+1] ^ gray[i];
    end
    gray_to_bin = bin;
  endfunction

  // Write pointer logic
  always @(posedge wr_clk or negedge wr_rst_ni) begin
    if (!wr_rst_ni) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (wr_en && !wr_full) begin
      mem[wr_ptr] <= din;
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= bin_to_gray(wr_ptr + 1);
    end else if (clear_i) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end
  end

  // Read pointer logic
  always @(posedge rd_clk or negedge rd_rst_ni) begin
    if (!rd_rst_ni) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (rd_en && !rd_empty) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= bin_to_gray(rd_ptr + 1);
    end else if (clear_i) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end
  end

  // Synchronize write pointer Gray code to read clock domain
  always @(posedge rd_clk or negedge rd_rst_ni) begin
    if (!rd_rst_ni) begin
      wr_ptr_gray_sync <= 0;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  // Synchronize read pointer Gray code to write clock domain
  always @(posedge wr_clk or negedge wr_rst_ni) begin
    if (!wr_rst_ni) begin
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  // Calculate full and empty flags
  always @(*) begin
    wr_full = (bin_to_gray(wr_ptr + 1) == rd_ptr_gray_sync);
    rd_empty = (wr_ptr_gray_sync == bin_to_gray(rd_ptr));
  end

  // Output the data
  assign dout = mem[rd_ptr];

  // Output the full and empty signals
  assign wr_full_n = ~wr_full;
  assign rd_empty_n = ~rd_empty;

endmodule

module clear_control (
  input  clk,
  input  rst_ni,
  input  clear_i,
  output clear_pending_o,
  output clear_o
);

  reg clear_req;
  reg clear_ack;
  reg [1:0] clear_state;

  // State machine states
  localparam IDLE = 2'b00;
  localparam CLEARING = 2'b01;
  localparam ACKNOWLEDGED = 2'b10;

  // Clear request detection
  always @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_req <= 0;
    end else begin
      clear_req <= clear_i;
    end
  end

  // Clear state machine
  always @(posedge clk or negedge rst_ni) begin
    if (!rst_ni) begin
      clear_state <= IDLE;
      clear_ack <= 0;
    end else begin
      case (clear_state)
        IDLE: begin
          if (clear_req) begin
            clear_state <= CLEARING;
          end
        end
        CLEARING: begin
          clear_ack <= 1;
          clear_state <= ACKNOWLEDGED;
        end
        ACKNOWLEDGED: begin
          if (!clear_req) begin
            clear_ack <= 0;
            clear_state <= IDLE;
          end
        end
      endcase
    end
  end

  // Outputs
  assign clear_o = clear_ack;
  assign clear_pending_o = clear_req;

endmodule
