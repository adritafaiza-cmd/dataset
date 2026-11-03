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

  // Internal signals for pointer synchronization
  wire [ASIZE-1:0] a_side_ptr_sync_a_side_ptr;
  wire [ASIZE-1:0] b_side_ptr_sync_b_side_ptr;

  // a_side circular buffer
  circular_buffer #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) a_side_buffer (
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
    .ram_clk(o_ram_a_clk),
    .ram_wdata(o_ram_a_wdata),
    .ram_rdata(i_ram_a_rdata),
    .ram_addr(o_ram_a_addr),
    .ram_rinc(o_ram_a_rinc),
    .ram_winc(o_ram_a_winc),
    .remote_ptr(b_side_ptr_sync_b_side_ptr)
  );

  // b_side circular buffer
  circular_buffer #(
    .DSIZE(DSIZE),
    .ASIZE(ASIZE),
    .FALLTHROUGH(FALLTHROUGH)
  ) b_side_buffer (
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
    .ram_clk(o_ram_b_clk),
    .ram_wdata(o_ram_b_wdata),
    .ram_rdata(i_ram_b_rdata),
    .ram_addr(o_ram_b_addr),
    .ram_rinc(o_ram_b_rinc),
    .ram_winc(o_ram_b_winc),
    .remote_ptr(a_side_ptr_sync_a_side_ptr)
  );

  // Synchronization of b_side pointer to a_clk domain
  ptr_sync #(
    .ASIZE(ASIZE)
  ) a_side_ptr_sync (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .async_ptr(b_side_buffer.ptr),
    .sync_ptr(a_side_ptr_sync_a_side_ptr)
  );

  // Synchronization of a_side pointer to b_clk domain
  ptr_sync #(
    .ASIZE(ASIZE)
  ) b_side_ptr_sync (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .async_ptr(a_side_buffer.ptr),
    .sync_ptr(b_side_ptr_sync_b_side_ptr)
  );

endmodule

module circular_buffer
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
       output wire             ram_clk,
       output wire [DSIZE-1:0] ram_wdata,
       input wire [DSIZE-1:0]  ram_rdata,
       output wire [ASIZE-1:0] ram_addr,
       output wire             ram_rinc,
       output wire             ram_winc,
       input wire [ASIZE-1:0]  remote_ptr
       );

  reg [DSIZE-1:0] mem [(1<<ASIZE)-1:0];
  reg [ASIZE-1:0] ptr;
  reg [ASIZE-1:0] next_ptr;
  reg [ASIZE-1:0] read_ptr;
  reg [ASIZE-1:0] read_next_ptr;
  reg full_flag;
  reg afull_flag;
  reg empty_flag;
  reg aempty_flag;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ptr <= 0;
      next_ptr <= 0;
      read_ptr <= 0;
      read_next_ptr <= 0;
      full_flag <= 0;
      afull_flag <= 0;
      empty_flag <= 1;
      aempty_flag <= 1;
    end else begin
      if (winc && !full_flag) begin
        mem[ptr] <= wdata;
        ptr <= next_ptr;
        next_ptr <= next_ptr + 1;
      end
      if (rinc && !empty_flag) begin
        read_ptr <= read_next_ptr;
        read_next_ptr <= read_next_ptr + 1;
      end
      full_flag <= (next_ptr == remote_ptr);
      afull_flag <= (next_ptr == (remote_ptr + 1) % (1<<ASIZE));
      empty_flag <= (read_ptr == ptr);
      aempty_flag <= (read_ptr == (ptr + 1) % (1<<ASIZE));
    end
  end

  assign rdata = ram_rdata;
  assign full = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty = aempty_flag;
  assign ram_clk = clk;
  assign ram_wdata = wdata;
  assign ram_addr = ptr;
  assign ram_winc = winc;
  assign ram_rinc = rinc;

endmodule

module ptr_sync
  #(
    parameter ASIZE = 4
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire [ASIZE-1:0]  async_ptr,
       output wire [ASIZE-1:0] sync_ptr
       );

  reg [ASIZE-1:0] sync_reg1;
  reg [ASIZE-1:0] sync_reg2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_reg1 <= 0;
      sync_reg2 <= 0;
    end else begin
      sync_reg1 <= async_ptr;
      sync_reg2 <= sync_reg1;
    end
  end

  assign sync_ptr = sync_reg2;

endmodule
