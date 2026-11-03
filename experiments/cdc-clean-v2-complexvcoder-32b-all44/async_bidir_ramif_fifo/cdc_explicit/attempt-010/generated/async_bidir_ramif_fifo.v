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

  wire [DSIZE-1:0] a_side_rdata;
  wire             a_side_full;
  wire             a_side_afull;
  wire             a_side_empty;
  wire             a_side_aempty;
  wire [DSIZE-1:0] b_side_rdata;
  wire             b_side_full;
  wire             b_side_afull;
  wire             b_side_empty;
  wire             b_side_aempty;

  async_fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  a_side (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_side_rdata),
    .full(a_side_full),
    .afull(a_side_afull),
    .empty(a_side_empty),
    .aempty(a_side_aempty),
    .dir(a_dir),
    .op_clk(b_clk),
    .op_rst_n(b_rst_n),
    .ram_clk(o_ram_a_clk),
    .ram_wdata(o_ram_a_wdata),
    .ram_rdata(i_ram_a_rdata),
    .ram_addr(o_ram_a_addr),
    .ram_rinc(o_ram_a_rinc),
    .ram_winc(o_ram_a_winc)
  );

  async_fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  b_side (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_side_rdata),
    .full(b_side_full),
    .afull(b_side_afull),
    .empty(b_side_empty),
    .aempty(b_side_aempty),
    .dir(b_dir),
    .op_clk(a_clk),
    .op_rst_n(a_rst_n),
    .ram_clk(o_ram_b_clk),
    .ram_wdata(o_ram_b_wdata),
    .ram_rdata(i_ram_b_rdata),
    .ram_addr(o_ram_b_addr),
    .ram_rinc(o_ram_b_rinc),
    .ram_winc(o_ram_b_winc)
  );

  assign a_rdata = a_side_rdata;
  assign a_full = a_side_full;
  assign a_afull = a_side_afull;
  assign a_empty = a_side_empty;
  assign a_aempty = a_side_aempty;

  assign b_rdata = b_side_rdata;
  assign b_full = b_side_full;
  assign b_afull = b_side_afull;
  assign b_empty = b_side_empty;
  assign b_aempty = b_side_aempty;

endmodule

module async_fifo_side
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire              winc,
       input wire [DSIZE-1:0]  wdata,
       input wire              rinc,
       output wire [DSIZE-1:0] rdata,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty,
       input wire              dir,
       input wire              op_clk,
       input wire              op_rst_n,
       output wire             ram_clk,
       output wire [DSIZE-1:0] ram_wdata,
       input wire [DSIZE-1:0]  ram_rdata,
       output wire [ASIZE-1:0] ram_addr,
       output wire             ram_rinc,
       output wire             ram_winc
       );

  reg [ASIZE:0] wr_ptr, rd_ptr;
  reg [ASIZE:0] op_wr_ptr, op_rd_ptr;
  reg [ASIZE:0] rd_ptr_gray, op_wr_ptr_gray;
  reg [ASIZE:0] rd_ptr_gray_sync, op_wr_ptr_gray_sync;
  reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];
  reg full_flag, afull_flag, empty_flag, aempty_flag;

  // Gray code conversion
  function [ASIZE:0] bin2gray;
    input [ASIZE:0] bin;
    bin2gray = bin ^ (bin >> 1);
  endfunction

  // Binary conversion
  function [ASIZE:0] gray2bin;
    input [ASIZE:0] gray;
    integer i;
    reg [ASIZE:0] bin;
    bin = gray;
    for (i = ASIZE-1; i >= 0; i = i - 1) begin
      bin[i] = bin[i+1] ^ gray[i];
    end
    return bin;
  endfunction

  // Write pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
    end else if (winc && !full_flag) begin
      wr_ptr <= wr_ptr + 1;
    end
  end

  // Read pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr <= 0;
    end else if (rinc && !empty_flag) begin
      rd_ptr <= rd_ptr + 1;
    end
  end

  // Cross-domain write pointer logic
  always @(posedge op_clk or negedge op_rst_n) begin
    if (!op_rst_n) begin
      op_wr_ptr <= 0;
    end else begin
      op_wr_ptr <= gray2bin(op_wr_ptr_gray_sync);
    end
  end

  // Cross-domain read pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_gray <= bin2gray(0);
    end else begin
      rd_ptr_gray <= bin2gray(rd_ptr);
    end
  end

  // Cross-domain read pointer synchronization
  always @(posedge op_clk or negedge op_rst_n) begin
    if (!op_rst_n) begin
      rd_ptr_gray_sync <= 0;
    end else begin
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  // Cross-domain write pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      op_wr_ptr_gray <= 0;
    end else begin
      op_wr_ptr_gray <= bin2gray(op_wr_ptr);
    end
  end

  // Cross-domain write pointer synchronization
  always @(posedge op_clk or negedge op_rst_n) begin
    if (!op_rst_n) begin
      op_wr_ptr_gray_sync <= 0;
    end else begin
      op_wr_ptr_gray_sync <= op_wr_ptr_gray;
    end
  end

  // RAM interface
  assign ram_clk = clk;
  assign ram_wdata = wdata;
  assign ram_addr = wr_ptr[ASIZE-1:0];
  assign ram_winc = winc && !full_flag;
  assign ram_rinc = rinc && !empty_flag;

  // Output data
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata <= 0;
    end else if (rinc && !empty_flag) begin
      rdata <= mem[rd_ptr[ASIZE-1:0]];
    end
  end

  // Full flag
  assign full_flag = (wr_ptr[ASIZE:ASIZE-1] == op_rd_ptr[ASIZE:ASIZE-1]) && (wr_ptr[ASIZE-1:0] == op_rd_ptr[ASIZE-1:0] + 1);
  assign afull_flag = (wr_ptr[ASIZE:ASIZE-1] == op_rd_ptr[ASIZE:ASIZE-1]) && (wr_ptr[ASIZE-1:0] == op_rd_ptr[ASIZE-1:0] + 1);

  // Empty flag
  assign empty_flag = (wr_ptr[ASIZE:ASIZE-1] == rd_ptr[ASIZE:ASIZE-1]) && (wr_ptr[ASIZE-1:0] == rd_ptr[ASIZE-1:0]);
  assign aempty_flag = (wr_ptr[ASIZE:ASIZE-1] == rd_ptr[ASIZE:ASIZE-1]) && (wr_ptr[ASIZE-1:0] == rd_ptr[ASIZE-1:0] + 1);

  // Memory write
  always @(posedge clk) begin
    if (winc && !full_flag) begin
      mem[wr_ptr[ASIZE-1:0]] <= wdata;
    end
  end

  // Output flags
  assign full = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty = aempty_flag;

endmodule
