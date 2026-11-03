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

  wire a_wr_en, a_rd_en, b_wr_en, b_rd_en;

  // Direction control logic
  assign a_wr_en = a_dir & a_winc;
  assign a_rd_en = ~a_dir & a_rinc;
  assign b_wr_en = b_dir & b_winc;
  assign b_rd_en = ~b_dir & b_rinc;

  // FIFO from a_clk to b_clk
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_a_to_b (
    .clk_wr(a_clk),
    .rst_wr_n(a_rst_n),
    .din(a_wdata),
    .wr_en(a_wr_en),
    .clk_rd(b_clk),
    .rst_rd_n(b_rst_n),
    .rd_en(b_rd_en),
    .dout(b_rdata),
    .empty(b_empty),
    .almost_empty(b_aempty),
    .full(b_full),
    .almost_full(b_afull)
  );

  // FIFO from b_clk to a_clk
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_b_to_a (
    .clk_wr(b_clk),
    .rst_wr_n(b_rst_n),
    .din(b_wdata),
    .wr_en(b_wr_en),
    .clk_rd(a_clk),
    .rst_rd_n(a_rst_n),
    .rd_en(a_rd_en),
    .dout(a_rdata),
    .empty(a_empty),
    .almost_empty(a_aempty),
    .full(a_full),
    .almost_full(a_afull)
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
       input wire [DSIZE-1:0]  din,
       input wire              wr_en,
       input wire              clk_rd,
       input wire              rst_rd_n,
       input wire              rd_en,
       output wire [DSIZE-1:0] dout,
       output wire             empty,
       output wire             almost_empty,
       output wire             full,
       output wire             almost_full
       );

  reg [DSIZE-1:0] mem [2**ASIZE-1:0];
  reg [ASIZE-1:0] wr_ptr, rd_ptr, wr_ptr_next, rd_ptr_next;
  reg [ASIZE-1:0] wr_ptr_gray, rd_ptr_gray, wr_ptr_gray_sync, rd_ptr_gray_sync;
  reg [ASIZE-1:0] wr_gray, rd_gray, wr_gray_sync, rd_gray_sync;
  reg full_flag, almost_full_flag, empty_flag, almost_empty_flag;

  // Write pointer logic
  always @(posedge clk_wr or negedge rst_wr_n) begin
    if (!rst_wr_n) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
      wr_ptr_next <= 0;
      wr_gray <= 0;
    end else begin
      if (wr_en && !full_flag) begin
        mem[wr_ptr] <= din;
        wr_ptr_next <= wr_ptr + 1;
        wr_gray <= wr_ptr_next ^ (wr_ptr_next >> 1);
      end
      wr_ptr <= wr_ptr_next;
      wr_ptr_gray <= wr_gray;
    end
  end

  // Read pointer logic
  always @(posedge clk_rd or negedge rst_rd_n) begin
    if (!rst_rd_n) begin
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
      rd_ptr_next <= 0;
      rd_gray <= 0;
    end else begin
      if (rd_en && !empty_flag) begin
        rd_ptr_next <= rd_ptr + 1;
        rd_gray <= rd_ptr_next ^ (rd_ptr_next >> 1);
      end
      rd_ptr <= rd_ptr_next;
      rd_ptr_gray <= rd_gray;
    end
  end

  // Gray code synchronization
  always @(posedge clk_rd or negedge rst_rd_n) begin
    if (!rst_rd_n) begin
      wr_ptr_gray_sync <= 0;
      wr_gray_sync <= 0;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
      wr_gray_sync <= wr_gray;
    end
  end

  always @(posedge clk_wr or negedge rst_wr_n) begin
    if (!rst_wr_n) begin
      rd_ptr_gray_sync <= 0;
      rd_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
      rd_gray_sync <= rd_gray;
    end
  end

  // Flags
  assign full_flag = (wr_ptr_gray_sync == {~rd_ptr_gray_sync[ASIZE-1], rd_ptr_gray_sync[ASIZE-2:0]});
  assign almost_full_flag = (wr_ptr_gray_sync == {rd_ptr_gray_sync[ASIZE-1], ~rd_ptr_gray_sync[ASIZE-2:0]});
  assign empty_flag = (wr_ptr_gray == rd_ptr_gray_sync);
  assign almost_empty_flag = (wr_ptr_gray == {rd_ptr_gray_sync[ASIZE-1], ~rd_ptr_gray_sync[ASIZE-2:0]});

  // Output data
  reg [DSIZE-1:0] dout_reg;

  always @(posedge clk_rd or negedge rst_rd_n) begin
    if (!rst_rd_n) begin
      dout_reg <= 0;
    end else if (rd_en && !empty_flag) begin
      dout_reg <= mem[rd_ptr];
    end
  end

  assign dout = dout_reg;
  assign full = full_flag;
  assign almost_full = almost_full_flag;
  assign empty = empty_flag;
  assign almost_empty = almost_empty_flag;

endmodule
