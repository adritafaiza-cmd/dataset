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

  // Internal signals
  wire [ASIZE-1:0] a_wr_ptr_gray, a_wr_ptr_gray_sync, a_wr_ptr_bin, a_rd_ptr_gray, a_rd_ptr_gray_sync, a_rd_ptr_bin;
  wire [ASIZE-1:0] b_wr_ptr_gray, b_wr_ptr_gray_sync, b_wr_ptr_bin, b_rd_ptr_gray, b_rd_ptr_gray_sync, b_rd_ptr_bin;
  wire [ASIZE-1:0] a2b_wr_ptr_gray_synced, a2b_rd_ptr_gray_synced, b2a_wr_ptr_gray_synced, b2a_rd_ptr_gray_synced;

  // CDC instances
  cdc_counter #(.ASIZE(ASIZE)) a2b_wr_ptr_cdc (
    .clk_src(a_clk),
    .clk_dst(b_clk),
    .rst_n(b_rst_n),
    .counter_in(a_wr_ptr_gray),
    .counter_out(a2b_wr_ptr_gray_synced)
  );

  cdc_counter #(.ASIZE(ASIZE)) a2b_rd_ptr_cdc (
    .clk_src(a_clk),
    .clk_dst(b_clk),
    .rst_n(b_rst_n),
    .counter_in(a_rd_ptr_gray),
    .counter_out(a2b_rd_ptr_gray_synced)
  );

  cdc_counter #(.ASIZE(ASIZE)) b2a_wr_ptr_cdc (
    .clk_src(b_clk),
    .clk_dst(a_clk),
    .rst_n(a_rst_n),
    .counter_in(b_wr_ptr_gray),
    .counter_out(b2a_wr_ptr_gray_synced)
  );

  cdc_counter #(.ASIZE(ASIZE)) b2a_rd_ptr_cdc (
    .clk_src(b_clk),
    .clk_dst(a_clk),
    .rst_n(a_rst_n),
    .counter_in(b_rd_ptr_gray),
    .counter_out(b2a_rd_ptr_gray_synced)
  );

  // FIFO logic instances
  fifo_logic #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_a_logic (
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
    .wr_ptr_gray(a_wr_ptr_gray),
    .wr_ptr_gray_sync(b2a_wr_ptr_gray_synced),
    .rd_ptr_gray(a_rd_ptr_gray),
    .rd_ptr_gray_sync(b2a_rd_ptr_gray_synced),
    .ram_clk(o_ram_a_clk),
    .ram_wdata(o_ram_a_wdata),
    .ram_rdata(i_ram_a_rdata),
    .ram_addr(o_ram_a_addr),
    .ram_rinc(o_ram_a_rinc),
    .ram_winc(o_ram_a_winc)
  );

  fifo_logic #(.DSIZE(DSIZE), .ASIZE(ASIZE)) fifo_b_logic (
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
    .wr_ptr_gray(b_wr_ptr_gray),
    .wr_ptr_gray_sync(a2b_wr_ptr_gray_synced),
    .rd_ptr_gray(b_rd_ptr_gray),
    .rd_ptr_gray_sync(a2b_rd_ptr_gray_synced),
    .ram_clk(o_ram_b_clk),
    .ram_wdata(o_ram_b_wdata),
    .ram_rdata(i_ram_b_rdata),
    .ram_addr(o_ram_b_addr),
    .ram_rinc(o_ram_b_rinc),
    .ram_winc(o_ram_b_winc)
  );

endmodule

module cdc_counter
  #(
    parameter ASIZE = 4
    ) (
       input wire              clk_src,
       input wire              clk_dst,
       input wire              rst_n,
       input wire [ASIZE-1:0]  counter_in,
       output wire [ASIZE-1:0] counter_out
       );

  reg [ASIZE-1:0] counter_reg1, counter_reg2;

  always @(posedge clk_src or negedge rst_n) begin
    if (!rst_n) begin
      counter_reg1 <= {ASIZE{1'b0}};
      counter_reg2 <= {ASIZE{1'b0}};
    end else begin
      counter_reg1 <= counter_in;
      counter_reg2 <= counter_reg1;
    end
  end

  assign counter_out = counter_reg2;

endmodule

module fifo_logic
  #(
    parameter DSIZE = 8,
    parameter ASIZE = 4
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
       output wire [ASIZE-1:0] wr_ptr_gray,
       input wire [ASIZE-1:0]  wr_ptr_gray_sync,
       output wire [ASIZE-1:0] rd_ptr_gray,
       input wire [ASIZE-1:0]  rd_ptr_gray_sync,
       output wire             ram_clk,
       output wire [DSIZE-1:0] ram_wdata,
       input wire [DSIZE-1:0]  ram_rdata,
       output wire [ASIZE-1:0] ram_addr,
       output wire             ram_rinc,
       output wire             ram_winc
       );

  reg [DSIZE-1:0] ram [0:(1<<ASIZE)-1];
  reg [ASIZE-1:0] wr_ptr_bin, rd_ptr_bin;
  reg [ASIZE-1:0] wr_ptr_next, rd_ptr_next;
  reg full_flag, afull_flag, empty_flag, aempty_flag;

  // Binary to Gray conversion for write pointer
  assign wr_ptr_gray = wr_ptr_bin ^ (wr_ptr_bin >> 1);

  // Binary to Gray conversion for read pointer
  assign rd_ptr_gray = rd_ptr_bin ^ (rd_ptr_bin >> 1);

  // Full flag
  assign full_flag = (wr_ptr_bin == rd_ptr_next);

  // Almost full flag
  assign afull_flag = (wr_ptr_next == rd_ptr_bin);

  // Empty flag
  assign empty_flag = (wr_ptr_bin == rd_ptr_bin);

  // Almost empty flag
  assign aempty_flag = (wr_ptr_bin == rd_ptr_next);

  // RAM address
  assign ram_addr = rd_ptr_bin;

  // RAM write data
  assign ram_wdata = wdata;

  // RAM read increment
  assign ram_rinc = rinc;

  // RAM write increment
  assign ram_winc = winc;

  // RAM clock
  assign ram_clk = clk;

  // FIFO data output
  assign rdata = ram_rdata;

  // FIFO status outputs
  assign full = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty = aempty_flag;

  // Next write pointer calculation
  always @(*) begin
    wr_ptr_next = wr_ptr_bin + 1;
  end

  // Next read pointer calculation
  always @(*) begin
    rd_ptr_next = rd_ptr_bin + 1;
  end

  // Write pointer update
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr_bin <= {ASIZE{1'b0}};
    end else if (winc && !full_flag) begin
      wr_ptr_bin <= wr_ptr_next;
    end
  end

  // Read pointer update
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rd_ptr_bin <= {ASIZE{1'b0}};
    end else if (rinc && !empty_flag) begin
      rd_ptr_bin <= rd_ptr_next;
    end
  end

endmodule
