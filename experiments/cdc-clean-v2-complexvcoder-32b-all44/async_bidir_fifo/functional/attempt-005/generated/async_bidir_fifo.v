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

  // Instantiate the asynchronous FIFO from A to B
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  a_to_b_fifo (
    .clk_wr   (a_clk),
    .rst_n_wr (a_rst_n),
    .winc     (a_dir & a_winc),
    .wdata    (a_wdata),
    .clk_rd   (b_clk),
    .rst_n_rd (b_rst_n),
    .rinc     (b_rinc),
    .rdata    (b_rdata),
    .full     (a_full),
    .afull    (a_afull),
    .empty    (a_empty),
    .aempty   (a_aempty)
  );

  // Instantiate the asynchronous FIFO from B to A
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  b_to_a_fifo (
    .clk_wr   (b_clk),
    .rst_n_wr (b_rst_n),
    .winc     (b_dir & b_winc),
    .wdata    (b_wdata),
    .clk_rd   (a_clk),
    .rst_n_rd (a_rst_n),
    .rinc     (a_rinc),
    .rdata    (a_rdata),
    .full     (b_full),
    .afull    (b_afull),
    .empty    (b_empty),
    .aempty   (b_aempty)
  );

endmodule

// Asynchronous FIFO module
module async_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              clk_wr,
       input wire              rst_n_wr,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              clk_rd,
       input wire              rst_n_rd,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  localparam DEPTH = 1 << ASIZE;

  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [ASIZE:0] wr_ptr, rd_ptr;
  reg [ASIZE:0] wr_ptr_gray, rd_ptr_gray;
  reg [ASIZE:0] wr_ptr_gray_sync, rd_ptr_gray_sync;

  // Write pointer logic
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr) begin
      wr_ptr <= 0;
    end else if (winc && !full) begin
      wr_ptr <= wr_ptr + 1;
    end
  end

  // Read pointer logic
  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      rd_ptr <= 0;
    end else if (rinc && !empty) begin
      rd_ptr <= rd_ptr + 1;
    end
  end

  // Gray code conversion
  always @(*) begin
    wr_ptr_gray = (wr_ptr >> 1) ^ wr_ptr;
    rd_ptr_gray = (rd_ptr >> 1) ^ rd_ptr;
  end

  // Synchronization of gray pointers
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr) begin
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd) begin
      wr_ptr_gray_sync <= 0;
    end else begin
      wr_ptr_gray_sync <= wr_ptr_gray;
    end
  end

  // Binary conversion
  wire [ASIZE:0] rd_ptr_bin_sync, wr_ptr_bin_sync;
  gray_to_bin #(ASIZE+1) rd_ptr_gray_to_bin (
    .gray_in  (rd_ptr_gray_sync),
    .bin_out  (rd_ptr_bin_sync)
  );

  gray_to_bin #(ASIZE+1) wr_ptr_gray_to_bin (
    .gray_in  (wr_ptr_gray_sync),
    .bin_out  (wr_ptr_bin_sync)
  );

  // Memory write
  always @(posedge clk_wr or negedge rst_n_wr) begin
    if (!rst_n_wr && winc && !full) begin
      mem[wr_ptr[ASIZE-1:0]] <= wdata;
    end
  end

  // Memory read
  always @(posedge clk_rd or negedge rst_n_rd) begin
    if (!rst_n_rd && rinc && !empty) begin
      rdata <= mem[rd_ptr[ASIZE-1:0]];
    end
  end

  // Flags
  assign full   = (wr_ptr_bin_sync[ASIZE-1:0] == rd_ptr_bin_sync[ASIZE-1:0]) && (wr_ptr_bin_sync[ASIZE] != rd_ptr_bin_sync[ASIZE]);
  assign afull  = (wr_ptr_bin_sync[ASIZE-1:0] == rd_ptr_bin_sync[ASIZE-1:0] - 1) && (wr_ptr_bin_sync[ASIZE] != rd_ptr_bin_sync[ASIZE]);
  assign empty  = (wr_ptr_bin_sync[ASIZE-1:0] == rd_ptr_bin_sync[ASIZE-1:0]) && (wr_ptr_bin_sync[ASIZE] == rd_ptr_bin_sync[ASIZE]);
  assign aempty = (wr_ptr_bin_sync[ASIZE-1:0] == rd_ptr_bin_sync[ASIZE-1:0] + 1) && (wr_ptr_bin_sync[ASIZE] == rd_ptr_bin_sync[ASIZE]);

endmodule

// Gray to binary conversion
module gray_to_bin
  #(
    parameter WIDTH = 4
    ) (
       input wire [WIDTH-1:0] gray_in,
       output wire [WIDTH-1:0] bin_out
       );

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: gray_to_bin_gen
      assign bin_out[i] = gray_in[i] ^ gray_in[i+1];
    end
  endgenerate

endmodule
