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

  wire [ASIZE+1:0] fifo_side_a_wptr_gray_sync;
  wire [ASIZE+1:0] fifo_side_a_wptr_gray;
  wire [ASIZE-1:0] fifo_side_a_wptr_bin;
  wire [ASIZE-1:0] fifo_side_a_rptr_bin;
  wire [DSIZE-1:0] fifo_side_a_data;

  wire [ASIZE+1:0] fifo_side_b_wptr_gray_sync;
  wire [ASIZE+1:0] fifo_side_b_wptr_gray;
  wire [ASIZE-1:0] fifo_side_b_wptr_bin;
  wire [ASIZE-1:0] fifo_side_b_rptr_bin;
  wire [DSIZE-1:0] fifo_side_b_data;

  fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_side_a (
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
       .other_clk(b_clk),
       .other_rst_n(b_rst_n),
       .other_dir(b_dir),
       .rptr_gray(fifo_side_b_wptr_gray_sync),
       .wptr_gray_sync(fifo_side_a_wptr_gray_sync),
       .wptr_gray(fifo_side_a_wptr_gray),
       .wptr_bin(fifo_side_a_wptr_bin),
       .rptr_bin(fifo_side_a_rptr_bin),
       .other_data(fifo_side_b_data),
       .data(fifo_side_a_data)
       );

  fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  fifo_side_b (
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
       .other_clk(a_clk),
       .other_rst_n(a_rst_n),
       .other_dir(a_dir),
       .rptr_gray(fifo_side_a_wptr_gray_sync),
       .wptr_gray_sync(fifo_side_b_wptr_gray_sync),
       .wptr_gray(fifo_side_b_wptr_gray),
       .wptr_bin(fifo_side_b_wptr_bin),
       .rptr_bin(fifo_side_b_rptr_bin),
       .other_data(fifo_side_a_data),
       .data(fifo_side_b_data)
       );

endmodule

module fifo_side
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
       input wire              other_clk,
       input wire              other_rst_n,
       input wire              other_dir,
       input wire [ASIZE+1:0]  rptr_gray,
       output wire [ASIZE+1:0] wptr_gray_sync,
       output wire [ASIZE+1:0] wptr_gray,
       output wire [ASIZE-1:0] wptr_bin,
       output wire [ASIZE-1:0] rptr_bin,
       input wire [DSIZE-1:0]  other_data,
       output wire [DSIZE-1:0] data
       );

  reg [DSIZE-1:0] mem [(1<<ASIZE)-1:0];
  reg [ASIZE-1:0] wptr_bin_reg;
  reg [ASIZE-1:0] rptr_bin_reg;
  reg [ASIZE+1:0] wptr_gray_reg;
  reg [ASIZE+1:0] wptr_gray_sync_reg;
  reg [ASIZE+1:0] rptr_gray_reg;
  reg [DSIZE-1:0] data_reg;

  wire [ASIZE-1:0] next_wptr_bin;
  wire [ASIZE-1:0] next_rptr_bin;
  wire [ASIZE+1:0] wptr_gray_next;
  wire [ASIZE+1:0] rptr_gray_next;
  wire [ASIZE+1:0] rptr_gray_sync_reg_next;

  wire full_flag;
  wire empty_flag;
  wire afull_flag;
  wire aempty_flag;

  // Binary to Gray conversion
  assign wptr_gray_next = {wptr_bin_reg ^ {wptr_bin_reg[ASIZE-1:0],1'b0}};
  assign rptr_gray_next = {rptr_bin_reg ^ {rptr_bin_reg[ASIZE-1:0],1'b0}};

  // Gray to Binary conversion
  assign wptr_bin = wptr_gray_reg[ASIZE-1:0] ^ wptr_gray_reg[ASIZE:1];
  assign rptr_bin = rptr_gray_sync_reg[ASIZE-1:0] ^ rptr_gray_sync_reg[ASIZE:1];

  // Next pointers calculation
  assign next_wptr_bin = wptr_bin_reg + winc & dir;
  assign next_rptr_bin = rptr_bin_reg + rinc & ~dir;

  // Flags
  assign full_flag = (wptr_gray_next == {1'b1, rptr_gray_sync_reg[ASIZE:0]});
  assign empty_flag = (wptr_gray_sync_reg == rptr_gray_next);
  assign afull_flag = (wptr_gray_next == {rptr_gray_sync_reg[ASIZE], rptr_gray_sync_reg[ASIZE-1:0] ^ wptr_gray_sync_reg[ASIZE-1:0]});
  assign aempty_flag = (wptr_gray_sync_reg == {rptr_gray_next[ASIZE], rptr_gray_next[ASIZE-1:0] ^ rptr_gray_next[ASIZE-1:0]});

  // Synchronize write pointer gray code to other clock domain
  always @(posedge other_clk or negedge other_rst_n) begin
    if (!other_rst_n) begin
      rptr_gray_sync_reg <= {ASIZE+2{1'b0}};
    end else begin
      rptr_gray_sync_reg <= rptr_gray;
    end
  end

  // Register outputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wptr_bin_reg <= {ASIZE{1'b0}};
      rptr_bin_reg <= {ASIZE{1'b0}};
      wptr_gray_reg <= {ASIZE+2{1'b0}};
      wptr_gray_sync_reg <= {ASIZE+2{1'b0}};
      rptr_gray_reg <= {ASIZE+2{1'b0}};
      data_reg <= {DSIZE{1'b0}};
    end else begin
      if (winc & dir & ~full_flag) begin
        mem[wptr_bin_reg] <= wdata;
        wptr_bin_reg <= next_wptr_bin;
        wptr_gray_reg <= wptr_gray_next;
      end
      if (rinc & ~dir & ~empty_flag) begin
        rptr_bin_reg <= next_rptr_bin;
        rptr_gray_reg <= rptr_gray_next;
      end
      if (rinc & ~dir & ~empty_flag) begin
        data_reg <= mem[rptr_bin_reg];
      end
      wptr_gray_sync_reg <= wptr_gray_reg;
    end
  end

  assign full = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty = aempty_flag;
  assign data = data_reg;

endmodule
