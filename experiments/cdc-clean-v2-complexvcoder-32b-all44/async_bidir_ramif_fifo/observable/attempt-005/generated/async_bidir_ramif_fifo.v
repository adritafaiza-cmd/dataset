module async_bidir_ramif_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
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
       input wire              b_dir,
       output wire             o_ram_a_clk,
       output wire [DSIZE-1:0] o_ram_a_wdata,
       input wire [DSIZE-1:0]  i_ram_a_rdata,
       output wire [ASIZE-1:0] o_ram_a_addr,
       output wire             o_ram_a_rinc,
       output wire             o_ram_a_winc,
       output wire             o_ram_b_clk,
       output wire [DSIZE-1:0] o_ram_b_wdata,
       input wire [DSIZE-1:0]  i_ram_b_rdata,
       output wire [ASIZE-1:0] o_ram_b_addr,
       output wire             o_ram_b_rinc,
       output wire             o_ram_b_winc
       );

  // FIFO cores for data transfer
  async_fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  a_to_b_fifo (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rd_clk(b_clk),
    .rinc(b_rinc),
    .rdata(b_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(b_empty),
    .aempty(b_aempty),
    .wr_addr(o_ram_a_addr),
    .wr_en(o_ram_a_winc)
  );

  async_fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  b_to_a_fifo (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rd_clk(a_clk),
    .rinc(a_rinc),
    .rdata(a_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(a_empty),
    .aempty(a_aempty),
    .wr_addr(o_ram_b_addr),
    .wr_en(o_ram_b_winc)
  );

  // Cross-domain crossing for direction signals
  async_cdc a_dir_cdc (
    .src_clk(a_clk),
    .src_data(a_dir),
    .dst_clk(b_clk),
    .dst_data(b_dir)
  );

  async_cdc b_dir_cdc (
    .src_clk(b_clk),
    .src_data(b_dir),
    .dst_clk(a_clk),
    .dst_data(a_dir)
  );

  // Assignments for RAM interface
  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_rinc = a_to_b_fifo.wr_en;

  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_rinc = b_to_a_fifo.wr_en;

  // Connect read data from RAM to FIFO
  assign a_to_b_fifo.rdata = i_ram_a_rdata;
  assign b_to_a_fifo.rdata = i_ram_b_rdata;

endmodule

module async_fifo_core
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              rd_clk,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty,
       output wire [ASIZE-1:0] wr_addr,
       output wire             wr_en
       );

  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg [ASIZE:0] wr_ptr, rd_ptr;
  reg [ASIZE:0] wr_ptr_gray, rd_ptr_gray, rd_ptr_gray_sync;

  // Gray code conversion
  function [ASIZE:0] bin_to_gray;
    input [ASIZE:0] bin;
    bin_to_gray = (bin >> 1) ^ bin;
  endfunction

  // Gray code to binary conversion
  function [ASIZE:0] gray_to_bin;
    input [ASIZE:0] gray;
    integer i;
    reg [ASIZE:0] bin;
    bin = gray;
    for (i = ASIZE-1; i >= 0; i = i - 1)
      bin[i] = bin[i+1] ^ gray[i];
    gray_to_bin = bin;
  endfunction

  // Write pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      wr_ptr <= 0;
    else if (winc && !full)
      wr_ptr <= wr_ptr + 1;
  end

  assign wr_ptr_gray = bin_to_gray(wr_ptr);
  assign wr_addr = wr_ptr[ASIZE-1:0];
  assign wr_en = winc && !full;

  // Read pointer logic
  always @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n)
      rd_ptr <= 0;
    else if (rinc && !empty)
      rd_ptr <= rd_ptr + 1;
  end

  // Synchronize read pointer gray code to write domain
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= bin_to_gray(rd_ptr);
    end
  end

  // Read data output
  always @(posedge rd_clk or negedge rst_n) begin
    if (!rst_n)
      rdata <= 0;
    else if (rinc && !empty)
      rdata <= mem[rd_ptr[ASIZE-1:0]];
  end

  // Full and almost full flags
  assign full = (wr_ptr_gray[ASIZE] != rd_ptr_gray_sync[ASIZE]) && (wr_ptr_gray[ASIZE-1:0] == rd_ptr_gray_sync[ASIZE-1:0]);
  assign afull = (wr_ptr_gray[ASIZE] == rd_ptr_gray_sync[ASIZE]) && (wr_ptr_gray[ASIZE-1:0] == rd_ptr_gray_sync[ASIZE-1:0] - 1);

  // Empty and almost empty flags
  assign empty = (wr_ptr_gray == rd_ptr_gray_sync);
  assign aempty = (wr_ptr_gray == rd_ptr_gray_sync) || (wr_ptr_gray[ASIZE] != rd_ptr_gray_sync[ASIZE]) && (wr_ptr_gray[ASIZE-1:0] == rd_ptr_gray_sync[ASIZE-1:0] + 1);

endmodule

module async_cdc (
       input wire src_clk,
       input wire src_data,
       input wire dst_clk,
       output wire dst_data
       );

  reg dst_data_ff1, dst_data_ff2;

  // Double flip-flop synchronizer
  always @(posedge src_clk) begin
    dst_data_ff1 <= src_data;
  end

  always @(posedge dst_clk) begin
    dst_data_ff2 <= dst_data_ff1;
  end

  assign dst_data = dst_data_ff2;

endmodule
