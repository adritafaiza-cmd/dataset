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

  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE))
  fifo_a_to_b (
       .clk     (b_clk),
       .rst_n   (b_rst_n),
       .winc    (a_winc & a_dir),
       .wdata   (a_wdata),
       .dir     (a_dir),
       .rinc    (b_rinc & ~b_dir),
       .rdata   (b_rdata),
       .full    (b_full),
       .afull   (b_afull),
       .empty   (b_empty),
       .aempty  (b_aempty)
       );

  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE))
  fifo_b_to_a (
       .clk     (a_clk),
       .rst_n   (a_rst_n),
       .winc    (b_winc & b_dir),
       .wdata   (b_wdata),
       .dir     (b_dir),
       .rinc    (a_rinc & ~a_dir),
       .rdata   (a_rdata),
       .full    (a_full),
       .afull   (a_afull),
       .empty   (a_empty),
       .aempty  (a_aempty)
       );

endmodule

module async_fifo
  #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              dir,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty
       );

  localparam DEPTH = 1 << ASIZE;

  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [ASIZE:0] wr_ptr_gray, rd_ptr_gray;
  reg [ASIZE-1:0] wr_ptr_bin, rd_ptr_bin;
  reg [ASIZE:0] wr_ptr_gray_synced, rd_ptr_gray_synced;
  reg full_flag, afull_flag, empty_flag, aempty_flag;

  // Binary to Gray code conversion
  function [ASIZE:0] bin_to_gray;
    input [ASIZE:0] bin;
    bin_to_gray = (bin >> 1) ^ bin;
  endfunction

  // Gray to Binary code conversion
  function [ASIZE:0] gray_to_bin;
    input [ASIZE:0] gray;
    integer i;
    reg [ASIZE:0] bin;
    bin = gray;
    for (i = ASIZE-1; i >= 0; i = i - 1)
      bin[i] = bin[i+1] ^ gray[i];
    return bin;
  endfunction

  // Write Pointer Logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray <= 0;
      wr_ptr_bin <= 0;
    end else if (winc & ~full_flag) begin
      wr_ptr_bin <= wr_ptr_bin + 1;
      wr_ptr_gray <= bin_to_gray(wr_ptr_bin + 1);
      mem[wr_ptr_bin] <= wdata;
    end
  end

  // Read Pointer Logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_gray <= 0;
      rd_ptr_bin <= 0;
    end else if (rinc & ~empty_flag) begin
      rd_ptr_bin <= rd_ptr_bin + 1;
      rd_ptr_gray <= bin_to_gray(rd_ptr_bin + 1);
    end
  end

  // Gray Code Synchronization
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray_synced <= 0;
      rd_ptr_gray_synced <= 0;
    end else begin
      wr_ptr_gray_synced <= wr_ptr_gray;
      rd_ptr_gray_synced <= rd_ptr_gray;
    end
  end

  // Output Data
  assign rdata = mem[rd_ptr_bin];

  // Full and Almost Full Flags
  assign full_flag = (wr_ptr_gray_synced == (rd_ptr_gray + {1'b1, {(ASIZE){1'b0}}});
  assign afull_flag = (wr_ptr_gray_synced == (rd_ptr_gray + {2'b10, {(ASIZE-1){1'b0}}});

  // Empty and Almost Empty Flags
  assign empty_flag = (wr_ptr_gray_synced == rd_ptr_gray);
  assign aempty_flag = (wr_ptr_gray_synced == (rd_ptr_gray + {1'b1, {(ASIZE){1'b0}}));

  // Output Flags
  assign full = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty = aempty_flag;

endmodule
