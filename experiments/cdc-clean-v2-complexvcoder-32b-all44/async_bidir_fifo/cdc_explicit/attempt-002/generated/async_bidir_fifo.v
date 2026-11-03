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

  // Asynchronous FIFO from A to B
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE))
  fifo_a_to_b (
       .clk_wr    (a_clk),
       .rst_n_wr  (a_rst_n),
       .wr_en     (a_winc & a_dir),
       .wr_data   (a_wdata),
       .clk_rd    (b_clk),
       .rst_n_rd  (b_rst_n),
       .rd_en     (b_rinc & ~b_dir),
       .rd_data   (b_rdata),
       .full      (b_full),
       .afull     (b_afull),
       .empty     (b_empty),
       .aempty    (b_aempty)
  );

  // Asynchronous FIFO from B to A
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE))
  fifo_b_to_a (
       .clk_wr    (b_clk),
       .rst_n_wr  (b_rst_n),
       .wr_en     (b_winc & b_dir),
       .wr_data   (b_wdata),
       .clk_rd    (a_clk),
       .rst_n_rd  (a_rst_n),
       .rd_en     (a_rinc & ~a_dir),
       .rd_data   (a_rdata),
       .full      (a_full),
       .afull     (a_afull),
       .empty     (a_empty),
       .aempty    (a_aempty)
  );

endmodule

module async_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4
    ) (
       input wire              clk_wr,
       input wire              rst_n_wr,
       input wire              wr_en,
       input wire [DSIZE-1:0]  wr_data,
       input wire              clk_rd,
       input wire              rst_n_rd,
       input wire              rd_en,
       output wire [DSIZE-1:0] rd_data,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  localparam DEPTH = 1 << ASIZE;
  localparam AWIDTH = ASIZE;

  reg [AWIDTH:0] wr_ptr_gray, wr_ptr_gray_nxt, wr_ptr_gray_ff;
  reg [AWIDTH:0] rd_ptr_gray, rd_ptr_gray_nxt, rd_ptr_gray_ff;
  reg [AWIDTH:0] wr_ptr_bin, rd_ptr_bin;
  reg [DSIZE-1:0] mem [0:DEPTH-1];

  // Write pointer logic
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr) begin
      wr_ptr_gray <= 0;
    end else begin
      wr_ptr_gray <= wr_ptr_gray_nxt;
    end
  end

  always @(*) begin
    wr_ptr_gray_nxt = wr_ptr_gray + wr_en;
  end

  // Read pointer logic
  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      rd_ptr_gray <= 0;
    end else begin
      rd_ptr_gray <= rd_ptr_gray_nxt;
    end
  end

  always @(*) begin
    rd_ptr_gray_nxt = rd_ptr_gray + rd_en;
  end

  // Gray to binary conversion
  assign wr_ptr_bin = (wr_ptr_gray >> 1) ^ wr_ptr_gray;
  assign rd_ptr_bin = (rd_ptr_gray >> 1) ^ rd_ptr_gray;

  // Memory write
  always @(posedge clk_wr) begin
    if (wr_en) begin
      mem[wr_ptr_bin[AWIDTH-1:0]] <= wr_data;
    end
  end

  // Memory read
  always @(posedge clk_rd) begin
    rd_data <= mem[rd_ptr_bin[AWIDTH-1:0]];
  end

  // Full and almost full flags
  reg [AWIDTH:0] wr_ptr_gray_ff1;

  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr) begin
      wr_ptr_gray_ff <= 0;
      wr_ptr_gray_ff1 <= 0;
    end else begin
      wr_ptr_gray_ff <= wr_ptr_gray;
      wr_ptr_gray_ff1 <= wr_ptr_gray_ff;
    end
  end

  assign full = (wr_ptr_gray[AWIDTH:0] == {rd_ptr_gray_ff1[AWIDTH], ~rd_ptr_gray_ff1[AWIDTH-1:0]});
  assign afull = (wr_ptr_gray[AWIDTH:0] == {rd_ptr_gray_ff[AWIDTH], rd_ptr_gray_ff[AWIDTH-1:0]});

  // Empty and almost empty flags
  reg [AWIDTH:0] rd_ptr_gray_ff1;

  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      rd_ptr_gray_ff <= 0;
      rd_ptr_gray_ff1 <= 0;
    end else begin
      rd_ptr_gray_ff <= rd_ptr_gray;
      rd_ptr_gray_ff1 <= rd_ptr_gray_ff;
    end
  end

  assign empty = (rd_ptr_gray[AWIDTH:0] == wr_ptr_gray_ff1[AWIDTH:0]);
  assign aempty = (rd_ptr_gray[AWIDTH:0] == {wr_ptr_gray_ff1[AWIDTH], ~wr_ptr_gray_ff1[AWIDTH-1:0]});

endmodule
