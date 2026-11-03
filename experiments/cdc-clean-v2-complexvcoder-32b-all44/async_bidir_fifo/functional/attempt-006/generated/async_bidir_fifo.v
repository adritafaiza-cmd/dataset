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

  wire a_winc_actual, a_rinc_actual, b_winc_actual, b_rinc_actual;

  // Direction control logic for a_side
  assign a_winc_actual = a_dir & a_winc;
  assign a_rinc_actual = ~a_dir & a_rinc;

  // Direction control logic for b_side
  assign b_winc_actual = b_dir & b_winc;
  assign b_rinc_actual = ~b_dir & b_rinc;

  // Instantiate async FIFO for a_to_b
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_a_to_b (
    .winc   (a_winc_actual),
    .wdata  (a_wdata),
    .rinc   (b_rinc_actual),
    .rdata  (b_rdata),
    .full   (a_full),
    .afull  (a_afull),
    .empty  (b_empty),
    .aempty (b_aempty),
    .wclk   (a_clk),
    .rclk   (b_clk),
    .rst_n  (a_rst_n & b_rst_n)
  );

  // Instantiate async FIFO for b_to_a
  async_fifo #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_b_to_a (
    .winc   (b_winc_actual),
    .wdata  (b_wdata),
    .rinc   (a_rinc_actual),
    .rdata  (a_rdata),
    .full   (b_full),
    .afull  (b_afull),
    .empty  (a_empty),
    .aempty (a_aempty),
    .wclk   (b_clk),
    .rclk   (a_clk),
    .rst_n  (a_rst_n & b_rst_n)
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
       input wire              rst_n
       );

  localparam DEPTH = 1 << ASIZE;

  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [ASIZE:0] wptr, rptr, wptr_gray, rptr_gray, rptr_gray_sync, wptr_gray_sync;
  wire [ASIZE:0] wptr_bin, rptr_bin;

  // Gray code conversion for pointers
  assign wptr_gray = (wptr >> 1) ^ wptr;
  assign rptr_gray = (rptr >> 1) ^ rptr;

  // Synchronize gray pointers across clock domains
  sync_gray_counter sync_wptr (
    .clk (rclk),
    .rst_n (rst_n),
    .gray_in (wptr_gray),
    .gray_out (wptr_gray_sync)
  );

  sync_gray_counter sync_rptr (
    .clk (wclk),
    .rst_n (rst_n),
    .gray_in (rptr_gray),
    .gray_out (rptr_gray_sync)
  );

  // Binary conversion for synchronized gray pointers
  gray_to_bin #(.WIDTH(ASIZE+1)) wptr_gray_to_bin (
    .gray (wptr_gray_sync),
    .bin (wptr_bin)
  );

  gray_to_bin #(.WIDTH(ASIZE+1)) rptr_gray_to_bin (
    .gray (rptr_gray_sync),
    .bin (rptr_bin)
  );

  // Write logic
  always @(posedge wclk or negedge rst_n) begin
    if (!rst_n)
      wptr <= 0;
    else if (winc && !full)
      wptr <= wptr + 1;
  end

  // Read logic
  always @(posedge rclk or negedge rst_n) begin
    if (!rst_n)
      rptr <= 0;
    else if (rinc && !empty)
      rptr <= rptr + 1;
  end

  // Memory write
  always @(posedge wclk) begin
    if (winc && !full)
      mem[wptr_bin[ASIZE-1:0]] <= wdata;
  end

  // Memory read
  always @(posedge rclk) begin
    if (rinc && !empty)
      rdata <= mem[rptr_bin[ASIZE-1:0]];
  end

  // Full flag
  assign full = (wptr_bin[ASIZE] != rptr_bin[ASIZE]) && (wptr_bin[ASIZE-1:0] == rptr_bin[ASIZE-1:0]);

  // Almost full flag
  assign afull = (wptr_bin[ASIZE] != rptr_bin[ASIZE]) && (wptr_bin[ASIZE-1:0] == rptr_bin[ASIZE-1:0] + 1);

  // Empty flag
  assign empty = (wptr_bin == rptr_bin);

  // Almost empty flag
  assign aempty = (wptr_bin == rptr_bin + 1);

endmodule

module sync_gray_counter (
    input wire clk,
    input wire rst_n,
    input wire [ASIZE:0] gray_in,
    output reg [ASIZE:0] gray_out
);

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      gray_out <= 0;
    else
      gray_out <= gray_in;
  end

endmodule

module gray_to_bin
  #(
    parameter WIDTH = 5
    ) (
       input wire [WIDTH-1:0] gray,
       output reg [WIDTH-1:0] bin
       );

  integer i;

  always @(*) begin
    bin[WIDTH-1] = gray[WIDTH-1];
    for (i = WIDTH-2; i >= 0; i = i - 1)
      bin[i] = bin[i+1] ^ gray[i];
  end

endmodule
