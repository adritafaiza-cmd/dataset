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

  // Instantiate async_fifo
  async_fifo #(
    .WIDTH(WIDTH),
    .SYNC_STAGES(SYNC_STAGES)
  ) async_fifo_inst (
    .clk_wr(src_clk_i),
    .rst_wr_n(src_rst_ni),
    .wr_en(src_valid_i),
    .data_wr(src_data_i),
    .full_n(src_ready_o),
    .clk_rd(dst_clk_i),
    .rst_rd_n(dst_rst_ni),
    .rd_en(dst_ready_i),
    .data_rd(dst_data_o),
    .empty_n(dst_valid_o),
    .clear_wr(clear_logic_src_inst.clear_pending_o),
    .clear_rd(clear_logic_dst_inst.clear_pending_o)
  );

  // Instantiate clear_logic for source side
  clear_logic clear_logic_src_inst (
    .clk(src_clk_i),
    .rst_n(src_rst_ni),
    .clear_i(src_clear_i),
    .clear_pending_o(src_clear_pending_o),
    .ready_i(src_ready_o),
    .valid_i(src_valid_i)
  );

  // Instantiate clear_logic for destination side
  clear_logic clear_logic_dst_inst (
    .clk(dst_clk_i),
    .rst_n(dst_rst_ni),
    .clear_i(dst_clear_i),
    .clear_pending_o(dst_clear_pending_o),
    .ready_i(dst_ready_i),
    .valid_i(dst_valid_o)
  );

endmodule

// async_fifo module
module async_fifo #(
  parameter WIDTH = 1,
  parameter SYNC_STAGES = 3
)(
  input  clk_wr,
  input  rst_wr_n,
  input  wr_en,
  input  [WIDTH-1:0] data_wr,
  output full_n,
  input  clk_rd,
  input  rst_rd_n,
  input  rd_en,
  output [WIDTH-1:0] data_rd,
  output empty_n,
  input  clear_wr,
  input  clear_rd
);

  reg [WIDTH-1:0] mem [0:1];
  reg wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, wr_ptr_gray_synced;

  // Gray code conversion
  function [2:0] binary_to_gray;
    input [2:0] bin;
    binary_to_gray = (bin >> 1) ^ bin;
  endfunction

  // Write pointer logic
  always @(posedge clk_wr or negedge rst_wr_n) begin
    if (!rst_wr_n) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (wr_en && !full_n) begin
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= binary_to_gray(wr_ptr + 1);
    end else if (clear_wr) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end
  end

  // Read pointer logic
  always @(posedge clk_rd or negedge rst_rd_n) begin
    if (!rst_rd_n) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (rd_en && !empty_n) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= binary_to_gray(rd_ptr + 1);
    end else if (clear_rd) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end
  end

  // Synchronize write pointer gray code to read clock domain
  reg [SYNC_STAGES-1:0] wr_ptr_gray_synced_pipeline;
  always @(posedge clk_rd or negedge rst_rd_n) begin
    if (!rst_rd_n) begin
      wr_ptr_gray_synced_pipeline <= 0;
    end else begin
      wr_ptr_gray_synced_pipeline[0] <= wr_ptr_gray;
      for (int i = 1; i < SYNC_STAGES; i = i + 1) begin
        wr_ptr_gray_synced_pipeline[i] <= wr_ptr_gray_synced_pipeline[i-1];
      end
    end
  end
  assign wr_ptr_gray_synced = wr_ptr_gray_synced_pipeline[SYNC_STAGES-1];

  // Convert synchronized gray code back to binary
  function [2:0] gray_to_binary;
    input [2:0] gray;
    reg [2:0] bin;
    bin[2] = gray[2];
    bin[1] = gray[2] ^ gray[1];
    bin[0] = gray[1] ^ gray[0];
    gray_to_binary = bin;
  endfunction

  assign wr_ptr_gray_synced_bin = gray_to_binary(wr_ptr_gray_synced);

  // Full and empty flags
  assign full_n = (wr_ptr_gray_synced_bin == binary_to_gray(rd_ptr + 1));
  assign empty_n = (wr_ptr_gray == rd_ptr_gray);

  // Memory write
  always @(posedge clk_wr or negedge rst_wr_n) begin
    if (!rst_wr_n) begin
      mem[0] <= 0;
      mem[1] <= 0;
    end else if (wr_en && !full_n) begin
      mem[wr_ptr] <= data_wr;
    end
  end

  // Memory read
  always @(posedge clk_rd or negedge rst_rd_n) begin
    if (!rst_rd_n) begin
      data_rd <= 0;
    end else if (rd_en && !empty_n) begin
      data_rd <= mem[rd_ptr];
    end
  end

endmodule

// clear_logic module
module clear_logic (
  input  clk,
  input  rst_n,
  input  clear_i,
  output clear_pending_o,
  input  ready_i,
  input  valid_i
);

  reg clear_pending;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      clear_pending <= 0;
    end else if (clear_i && !clear_pending) begin
      clear_pending <= 1;
    end else if (!valid_i || !ready_i) begin
      clear_pending <= 0;
    end
  end

  assign clear_pending_o = clear_pending;

endmodule
