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

  wire [ASIZE-1:0] fifo_a_to_b_wr_addr;
  wire [ASIZE-1:0] fifo_a_to_b_rd_addr;
  wire [ASIZE-1:0] fifo_a_to_b_wr_addr_sync;
  wire [ASIZE-1:0] fifo_a_to_b_rd_addr_sync;
  wire [ASIZE-1:0] fifo_b_to_a_wr_addr;
  wire [ASIZE-1:0] fifo_b_to_a_rd_addr;
  wire [ASIZE-1:0] fifo_b_to_a_wr_addr_sync;
  wire [ASIZE-1:0] fifo_b_to_a_rd_addr_sync;

  fifo_controller fifo_a_to_b (
    .clk(clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .rinc(a_rinc),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty),
    .wr_addr(fifo_a_to_b_wr_addr),
    .rd_addr(fifo_a_to_b_rd_addr)
  );

  fifo_controller fifo_b_to_a (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .rinc(b_rinc),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty),
    .wr_addr(fifo_b_to_a_wr_addr),
    .rd_addr(fifo_b_to_a_rd_addr)
  );

  cdc a_to_b_wr_addr_cdc (
    .src_clk(a_clk),
    .src_data(fifo_a_to_b_wr_addr),
    .dst_clk(b_clk),
    .dst_data(fifo_a_to_b_wr_addr_sync)
  );

  cdc a_to_b_rd_addr_cdc (
    .src_clk(a_clk),
    .src_data(fifo_a_to_b_rd_addr),
    .dst_clk(b_clk),
    .dst_data(fifo_a_to_b_rd_addr_sync)
  );

  cdc b_to_a_wr_addr_cdc (
    .src_clk(b_clk),
    .src_data(fifo_b_to_a_wr_addr),
    .dst_clk(a_clk),
    .dst_data(fifo_b_to_a_wr_addr_sync)
  );

  cdc b_to_a_rd_addr_cdc (
    .src_clk(b_clk),
    .src_data(fifo_b_to_a_rd_addr),
    .dst_clk(a_clk),
    .dst_data(fifo_b_to_a_rd_addr_sync)
  );

  assign a_rdata = i_ram_a_rdata;
  assign b_rdata = i_ram_b_rdata;

  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr = fifo_a_to_b_wr_addr;
  assign o_ram_a_rinc = (fifo_a_to_b_rd_addr != fifo_a_to_b_rd_addr_sync) & ~a_empty;
  assign o_ram_a_winc = a_winc;

  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr = fifo_b_to_a_wr_addr;
  assign o_ram_b_rinc = (fifo_b_to_a_rd_addr != fifo_b_to_a_rd_addr_sync) & ~b_empty;
  assign o_ram_b_winc = b_winc;

endmodule

module fifo_controller (
  input wire              clk,
  input wire              rst_n,
  input wire              winc,
  input wire              rinc,
  output wire             full,
  output wire             afull,
  output wire             empty,
  output wire             aempty,
  output wire [ASIZE-1:0] wr_addr,
  output wire [ASIZE-1:0] rd_addr
);

  reg [ASIZE-1:0] wr_ptr;
  reg [ASIZE-1:0] rd_ptr;
  reg [ASIZE-1:0] wr_ptr_gray;
  reg [ASIZE-1:0] rd_ptr_gray;
  reg [ASIZE-1:0] rd_ptr_gray_sync;

  wire [ASIZE-1:0] wr_ptr_gray_next;
  wire [ASIZE-1:0] rd_ptr_gray_next;
  wire             full_flag;
  wire             afull_flag;
  wire             empty_flag;
  wire             aempty_flag;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
    end else begin
      if (winc & ~full_flag) wr_ptr <= wr_ptr + 1;
      if (rinc & ~empty_flag) rd_ptr <= rd_ptr + 1;
    end
  end

  always @(*) begin
    wr_ptr_gray_next = wr_ptr ^ (wr_ptr >> 1);
    rd_ptr_gray_next = rd_ptr ^ (rd_ptr >> 1);
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_gray <= 0;
      rd_ptr_gray <= 0;
      rd_ptr_gray_sync <= 0;
    end else begin
      wr_ptr_gray <= wr_ptr_gray_next;
      rd_ptr_gray <= rd_ptr_gray_next;
      rd_ptr_gray_sync <= rd_ptr_gray;
    end
  end

  assign full_flag = (wr_ptr_gray_next == rd_ptr_gray_sync);
  assign afull_flag = (wr_ptr_gray_next == (rd_ptr_gray_sync ^ (1 << (ASIZE-1))));
  assign empty_flag = (wr_ptr_gray == rd_ptr_gray);
  assign aempty_flag = (wr_ptr_gray == (rd_ptr_gray ^ (1 << (ASIZE-1))));

  assign full = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty = aempty_flag;
  assign wr_addr = wr_ptr;
  assign rd_addr = rd_ptr;

endmodule

module cdc (
  input wire              src_clk,
  input wire [ASIZE-1:0]  src_data,
  input wire              dst_clk,
  output reg [ASIZE-1:0]  dst_data
);

  reg [ASIZE-1:0] data_reg;
  reg [ASIZE-1:0] data_meta;

  always @(posedge src_clk) begin
    data_reg <= src_data;
  end

  always @(posedge dst_clk) begin
    data_meta <= data_reg;
    dst_data <= data_meta;
  end

endmodule
