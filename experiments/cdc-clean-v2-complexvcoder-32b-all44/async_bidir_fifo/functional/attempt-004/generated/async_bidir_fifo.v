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

  // FIFO from a_clk to b_clk
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_ab (
    .winc   (a_dir ? a_winc : 1'b0),
    .wdata  (a_wdata),
    .rinc   (b_dir ? 1'b0 : b_rinc),
    .rdata  (b_rdata),
    .full   (a_full),
    .afull  (a_afull),
    .empty  (b_empty),
    .aempty (b_aempty),
    .wclk   (a_clk),
    .rclk   (b_clk),
    .wrst_n (a_rst_n),
    .rrst_n (b_rst_n)
  );

  // FIFO from b_clk to a_clk
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_ba (
    .winc   (b_dir ? b_winc : 1'b0),
    .wdata  (b_wdata),
    .rinc   (a_dir ? 1'b0 : a_rinc),
    .rdata  (a_rdata),
    .full   (b_full),
    .afull  (b_afull),
    .empty  (a_empty),
    .aempty (a_aempty),
    .wclk   (b_clk),
    .rclk   (a_clk),
    .wrst_n (b_rst_n),
    .rrst_n (a_rst_n)
  );

endmodule

module async_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
    ) (
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty,
       input wire              wclk,
       input wire              rclk,
       input wire              wrst_n,
       input wire              rrst_n
       );

  localparam DEPTH = 1 << ASIZE;

  reg [DSIZE-1:0] mem [DEPTH-1:0];
  reg [ASIZE:0] wptr, rptr, wptr_gray, rptr_gray, rptr_gray_sync, wptr_gray_sync;

  // Gray code conversion
  function [ASIZE:0] binary_to_gray;
    input [ASIZE:0] bin;
    binary_to_gray = bin ^ (bin >> 1);
  endfunction

  // Gray code to binary conversion
  function [ASIZE:0] gray_to_binary;
    input [ASIZE:0] gray;
    integer i;
    reg [ASIZE:0] bin;
    bin = gray;
    for (i = ASIZE-1; i > 0; i = i - 1)
      bin[i-1] = bin[i] ^ bin[i-1];
    gray_to_binary = bin;
  endfunction

  // Write pointer logic
  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wptr <= 0;
    end else if (winc && !full) begin
      wptr <= wptr + 1;
    end
  end

  // Read pointer logic
  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rptr <= 0;
    end else if (rinc && !empty) begin
      rptr <= rptr + 1;
    end
  end

  // Write pointer Gray code conversion
  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      wptr_gray <= 0;
    end else begin
      wptr_gray <= binary_to_gray(wptr);
    end
  end

  // Read pointer Gray code conversion
  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      rptr_gray <= 0;
    end else begin
      rptr_gray <= binary_to_gray(rptr);
    end
  end

  // Synchronize write pointer Gray code to read clock domain
  always @(posedge rclk or negedge rrst_n) begin
    if (!rrst_n) begin
      wptr_gray_sync <= 0;
    end else begin
      wptr_gray_sync <= wptr_gray;
    end
  end

  // Synchronize read pointer Gray code to write clock domain
  always @(posedge wclk or negedge wrst_n) begin
    if (!wrst_n) begin
      rptr_gray_sync <= 0;
    end else begin
      rptr_gray_sync <= rptr_gray;
    end
  end

  // Write data to memory
  always @(posedge wclk) begin
    if (winc && !full) begin
      mem[wptr[ASIZE-1:0]] <= wdata;
    end
  end

  // Read data from memory
  always @(posedge rclk) begin
    if (rinc && !empty) begin
      rdata <= mem[rptr[ASIZE-1:0]];
    end
  end

  // Full flag logic
  assign full = (wptr_gray_sync[ASIZE] != rptr_gray[ASIZE]) && (wptr_gray_sync[ASIZE-1:0] == rptr_gray[ASIZE-1:0]);

  // Almost full flag logic
  assign afull = (wptr_gray_sync[ASIZE] != rptr_gray[ASIZE]) && (wptr_gray_sync[ASIZE-1:1] == rptr_gray[ASIZE-1:1]) && (wptr_gray_sync[0] != rptr_gray[0]);

  // Empty flag logic
  assign empty = (wptr_gray == rptr_gray);

  // Almost empty flag logic
  assign aempty = (wptr_gray[ASIZE] == rptr_gray[ASIZE]) && (wptr_gray[ASIZE-1:0] == rptr_gray[ASIZE-1:0]);

endmodule
