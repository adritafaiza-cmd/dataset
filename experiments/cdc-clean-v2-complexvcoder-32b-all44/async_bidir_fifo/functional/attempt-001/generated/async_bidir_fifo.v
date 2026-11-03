module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              a_clk,
       input wire              a_rst_n,
       input wire              a_winc,
       input wire [DSIZE-1:0]  a_wdata,
       input wire              a_rinc,
       output wire [DSIZE-1:0] a_rdata,
       output wire             a_full,
       output wire             a_afull,
       output wire             a_empty,
       output wire             a_aempty,
       input wire              a_dir,
       input wire              b_clk,
       input wire              b_rst_n,
       input wire              b_winc,
       input wire [DSIZE-1:0]  b_wdata,
       input wire              b_rinc,
       output wire [DSIZE-1:0] b_rdata,
       output wire             b_full,
       output wire             b_afull,
       output wire             b_empty,
       output wire             b_aempty,
       input wire              b_dir
       );

  wire [DSIZE-1:0] fifo_a_to_b_dout;
  wire fifo_a_to_b_full;
  wire fifo_a_to_b_afull;
  wire fifo_a_to_b_empty;
  wire fifo_a_to_b_aempty;

  wire [DSIZE-1:0] fifo_b_to_a_dout;
  wire fifo_b_to_a_full;
  wire fifo_b_to_a_afull;
  wire fifo_b_to_a_empty;
  wire fifo_b_to_a_aempty;

  assign a_rdata = fifo_b_to_a_dout;
  assign a_full = fifo_b_to_a_full;
  assign a_afull = fifo_b_to_a_afull;
  assign a_empty = fifo_b_to_a_empty;
  assign a_aempty = fifo_b_to_a_aempty;

  assign b_rdata = fifo_a_to_b_dout;
  assign b_full = fifo_a_to_b_full;
  assign b_afull = fifo_a_to_b_afull;
  assign b_empty = fifo_a_to_b_empty;
  assign b_aempty = fifo_a_to_b_aempty;

  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_a_to_b (
    .clk_wr(a_clk),
    .rst_wr_n(a_rst_n),
    .wr_en(a_dir ? a_winc : 1'b0),
    .din(a_wdata),
    .clk_rd(b_clk),
    .rst_rd_n(b_rst_n),
    .rd_en(b_dir ? 1'b0 : b_rinc),
    .dout(fifo_a_to_b_dout),
    .full(fifo_a_to_b_full),
    .afull(fifo_a_to_b_afull),
    .empty(fifo_a_to_b_empty),
    .aempty(fifo_a_to_b_aempty)
  );

  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_b_to_a (
    .clk_wr(b_clk),
    .rst_wr_n(b_rst_n),
    .wr_en(b_dir ? b_winc : 1'b0),
    .din(b_wdata),
    .clk_rd(a_clk),
    .rst_rd_n(a_rst_n),
    .rd_en(a_dir ? 1'b0 : a_rinc),
    .dout(fifo_b_to_a_dout),
    .full(fifo_b_to_a_full),
    .afull(fifo_b_to_a_afull),
    .empty(fifo_b_to_a_empty),
    .aempty(fifo_b_to_a_aempty)
  );

endmodule

module async_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk_wr,
       input wire              rst_wr_n,
       input wire              wr_en,
       input wire [DSIZE-1:0]  din,
       input wire              clk_rd,
       input wire              rst_rd_n,
       input wire              rd_en,
       output wire [DSIZE-1:0] dout,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  reg [DSIZE-1:0] mem [(1<<ASIZE)-1:0];
  reg [ASIZE:0] wr_ptr, rd_ptr, wr_ptr_gray, rd_ptr_gray, rd_ptr_gray_sync, wr_ptr_gray_sync;

  wire [ASIZE:0] wr_ptr_gray_next, rd_ptr_gray_next;
  wire wr_ptr_gray_sync_valid, rd_ptr_gray_sync_valid;

  assign wr_ptr_gray_next = wr_ptr ^ (wr_ptr >> 1);
  assign rd_ptr_gray_next = rd_ptr ^ (rd_ptr >> 1);

  always @(posedge clk_wr or negedge rst_wr_n) begin
    if (!rst_wr_n) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
    end else if (wr_en && !full) begin
      wr_ptr <= wr_ptr + 1;
      wr_ptr_gray <= wr_ptr_gray_next;
    end
  end

  always @(posedge clk_rd or negedge rst_rd_n) begin
    if (!rst_rd_n) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else if (rd_en && !empty) begin
      rd_ptr <= rd_ptr + 1;
      rd_ptr_gray <= rd_ptr_gray_next;
    end
  end

  always @(posedge clk_rd or negedge rst_wr_n) begin
    if (!rst_wr_n) begin
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  always @(posedge clk_wr or negedge rst_rd_n) begin
    if (!rst_rd_n) begin
      wr_ptr_gray_sync <= 0;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  assign wr_ptr_gray_sync_valid = (wr_ptr_gray_sync == wr_ptr_gray_next);
  assign rd_ptr_gray_sync_valid = (rd_ptr_gray_sync == rd_ptr_gray_next);

  always @(posedge clk_wr or negedge rst_wr_n) begin
    if (!rst_wr_n) begin
      mem[0] <= 0;
    end else if (wr_en && !full) begin
      mem[wr_ptr[ASIZE-1:0]] <= din;
    end
  end

  assign dout = mem[rd_ptr[ASIZE-1:0]];

  assign full = (wr_ptr_gray_next == {rd_ptr_gray_sync[ASIZE], ~rd_ptr_gray_sync[ASIZE-1:0]});
  assign afull = (wr_ptr_gray_next == {rd_ptr_gray_sync[ASIZE-1:0], rd_ptr_gray_sync[ASIZE]});
  assign empty = (wr_ptr_gray_sync == rd_ptr_gray_next);
  assign aempty = (wr_ptr_gray_sync == {rd_ptr_gray_next[ASIZE], ~rd_ptr_next[ASIZE-1:0]});

endmodule
