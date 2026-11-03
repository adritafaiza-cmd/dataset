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

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
    a_fifo_core (
       .clk(a_clk),
       .rst_n(a_rst_n),
       .winc(a_winc),
       .wdata(a_wdata),
       .rinc(a_rinc),
       .rdata(a_rdata),
       .full(a_full),
       .afull(a_afull),
       .empty(a_empty),
       .aempty(a_aempty),
       .dir(a_dir),
       .other_dir(b_dir)
    );

  fifo_core #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
    b_fifo_core (
       .clk(b_clk),
       .rst_n(b_rst_n),
       .winc(b_winc),
       .wdata(b_wdata),
       .rinc(b_rinc),
       .rdata(b_rdata),
       .full(b_full),
       .afull(b_afull),
       .empty(b_empty),
       .aempty(b_aempty),
       .dir(b_dir),
       .other_dir(a_dir)
    );

endmodule

module fifo_core
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
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
       input wire              other_dir
       );

  localparam DEPTH = 1 << ASIZE;
  localparam AWIDTH = ASIZE;
  localparam AFULL_THRESHOLD = DEPTH - 2;

  reg [DSIZE-1:0] mem [0:DEPTH-1];
  reg [AWIDTH:0] wr_ptr, rd_ptr;
  reg [AWIDTH:0] wr_ptr_gray, rd_ptr_gray;
  reg [AWIDTH:0] rd_ptr_gray_sync1, rd_ptr_gray_sync2;
  reg [AWIDTH:0] wr_ptr_gray_sync1, wr_ptr_gray_sync2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      wr_ptr_gray <= 0;
      rd_ptr <= 0;
      rd_ptr_gray <= 0;
    end else begin
      if (dir && !full) begin
        mem[wr_ptr[AWIDTH-1:0]] <= wdata;
        wr_ptr <= wr_ptr + 1;
      end
      if (other_dir && !empty) begin
        rd_ptr <= rd_ptr + 1;
      end
      wr_ptr_gray <= (wr_ptr >> 1) ^ wr_ptr;
      rd_ptr_gray <= (rd_ptr >> 1) ^ rd_ptr;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_gray_sync1 <= 0;
      rd_ptr_gray_sync2 <= 0;
    end else begin
      rd_ptr_gray_sync1 <= rd_ptr_gray;
      rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray_sync1 <= 0;
      wr_ptr_gray_sync2 <= 0;
    end else begin
      wr_ptr_gray_sync1 <= wr_ptr_gray;
      wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;
    end
  end

  wire [AWIDTH:0] wr_ptr_gray_sync2_synced;
  wire [AWIDTH:0] rd_ptr_gray_sync2_synced;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray_sync2_synced <= 0;
      rd_ptr_gray_sync2_synced <= 0;
    end else begin
      wr_ptr_gray_sync2_synced <= wr_ptr_gray_sync2;
      rd_ptr_gray_sync2_synced <= rd_ptr_gray_sync2;
    end
  end

  wire [AWIDTH:0] wr_ptr_synced, rd_ptr_synced;

  assign wr_ptr_synced = {wr_ptr_gray_sync2_synced[AWIDTH], wr_ptr_gray_sync2_synced[AWIDTH-1:0] ^ wr_ptr_gray_sync2_synced[AWIDTH]};
  assign rd_ptr_synced = {rd_ptr_gray_sync2_synced[AWIDTH], rd_ptr_gray_sync2_synced[AWIDTH-1:0] ^ rd_ptr_gray_sync2_synced[AWIDTH]};

  assign full = (wr_ptr_synced == {rd_ptr_synced[AWIDTH], ~rd_ptr_synced[AWIDTH-1:0]});
  assign afull = (wr_ptr_synced == {rd_ptr_synced[AWIDTH], ~rd_ptr_synced[AWIDTH-1:0] + 1'b1});
  assign empty = (wr_ptr_gray_sync2_synced == rd_ptr_gray_sync2_synced);
  assign aempty = (wr_ptr_gray_sync2_synced == {rd_ptr_gray_sync2_synced[AWIDTH], rd_ptr_gray_sync2_synced[AWIDTH-1:0] + 1'b1});

  wire [DSIZE-1:0] rdata_raw;

  assign rdata_raw = mem[rd_ptr_synced[AWIDTH-1:0]];

  reg [DSIZE-1:0] rdata_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rdata_reg <= 0;
    end else if (other_dir && !empty) begin
      rdata_reg <= rdata_raw;
    end
  end

  assign rdata = rdata_reg;

endmodule
