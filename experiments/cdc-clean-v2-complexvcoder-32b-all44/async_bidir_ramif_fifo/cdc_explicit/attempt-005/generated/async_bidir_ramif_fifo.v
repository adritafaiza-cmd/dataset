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

  // Internal signals for FIFO pointers and flags
  wire [ASIZE-1:0] a_write_ptr, a_read_ptr, a_synced_b_read_ptr;
  wire [ASIZE-1:0] b_write_ptr, b_read_ptr, b_synced_a_read_ptr;
  wire a_write_enable, a_read_enable, b_write_enable, b_read_enable;
  wire a_full_flag, a_empty_flag, b_full_flag, b_empty_flag;

  // Synchronize b_read_ptr to a_clk
  sync_fifo_ptr a_side_read_ptr_sync (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .async_ptr(b_read_ptr),
    .other_clk(b_clk),
    .other_rst_n(b_rst_n),
    .synced_ptr(a_synced_b_read_ptr)
  );

  // Synchronize a_read_ptr to b_clk
  sync_fifo_ptr b_side_read_ptr_sync (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .async_ptr(a_read_ptr),
    .other_clk(a_clk),
    .other_rst_n(a_rst_n),
    .synced_ptr(b_synced_a_read_ptr)
  );

  // FIFO side for domain A
  async_fifo_side a_side (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .rdata(a_rdata),
    .full(a_full_flag),
    .afull(a_afull),
    .empty(a_empty_flag),
    .aempty(a_aempty),
    .dir(a_dir),
    .other_clk(b_clk),
    .other_rst_n(b_rst_n),
    .ram_clk(o_ram_a_clk),
    .ram_wdata(o_ram_a_wdata),
    .ram_rdata(i_ram_a_rdata),
    .ram_addr(o_ram_a_addr),
    .ram_rinc(o_ram_a_rinc),
    .ram_winc(o_ram_a_winc),
    .write_ptr(a_write_ptr),
    .read_ptr(a_read_ptr),
    .synced_read_ptr(a_synced_b_read_ptr),
    .write_enable(a_write_enable),
    .read_enable(a_read_enable)
  );

  // FIFO side for domain B
  async_fifo_side b_side (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .rdata(b_rdata),
    .full(b_full_flag),
    .afull(b_afull),
    .empty(b_empty_flag),
    .aempty(b_aempty),
    .dir(b_dir),
    .other_clk(a_clk),
    .other_rst_n(a_rst_n),
    .ram_clk(o_ram_b_clk),
    .ram_wdata(o_ram_b_wdata),
    .ram_rdata(i_ram_b_rdata),
    .ram_addr(o_ram_b_addr),
    .ram_rinc(o_ram_b_rinc),
    .ram_winc(o_ram_b_winc),
    .write_ptr(b_write_ptr),
    .read_ptr(b_read_ptr),
    .synced_read_ptr(b_synced_a_read_ptr),
    .write_enable(b_write_enable),
    .read_enable(b_read_enable)
  );

  // Assign full and empty flags
  assign a_full = a_full_flag;
  assign a_empty = a_empty_flag;
  assign b_full = b_full_flag;
  assign b_empty = b_empty_flag;

  // Assign almost full and almost empty flags
  assign a_afull = (a_write_ptr == (a_synced_b_read_ptr + ASIZE - 2)) & a_write_enable;
  assign a_aempty = (a_read_ptr == a_synced_b_read_ptr) & a_read_enable;
  assign b_afull = (b_write_ptr == (b_synced_a_read_ptr + ASIZE - 2)) & b_write_enable;
  assign b_aempty = (b_read_ptr == b_synced_a_read_ptr) & b_read_enable;

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
       input wire              other_clk,
       input wire              other_rst_n,
       output wire             ram_clk,
       output wire [DSIZE-1:0] ram_wdata,
       input wire [DSIZE-1:0]  ram_rdata,
       output wire [ASIZE-1:0] ram_addr,
       output wire             ram_rinc,
       output wire             ram_winc,
       output reg [ASIZE-1:0]  write_ptr,
       output reg [ASIZE-1:0]  read_ptr,
       input wire [ASIZE-1:0]  synced_read_ptr,
       output wire             write_enable,
       output wire             read_enable
       );

  // Internal signals
  reg [DSIZE-1:0] data_reg;
  reg [ASIZE-1:0] next_write_ptr, next_read_ptr;

  // Write enable and read enable logic
  assign write_enable = ~full & winc & dir;
  assign read_enable = ~empty & rinc & ~dir;

  // Write pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      write_ptr <= 0;
      next_write_ptr <= 0;
    end else if (write_enable) begin
      write_ptr <= next_write_ptr;
      next_write_ptr <= (write_ptr + 1) % (1 << ASIZE);
    end
  end

  // Read pointer logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      read_ptr <= 0;
      next_read_ptr <= 0;
    end else if (read_enable) begin
      read_ptr <= next_read_ptr;
      next_read_ptr <= (read_ptr + 1) % (1 << ASIZE);
    end
  end

  // Full and empty flags logic
  assign full = (write_ptr == (synced_read_ptr + ASIZE - 1)) & write_enable;
  assign empty = (read_ptr == synced_read_ptr) & read_enable;

  // RAM control signals
  assign ram_clk = clk;
  assign ram_wdata = wdata;
  assign ram_addr = write_ptr;
  assign ram_winc = write_enable;
  assign ram_rinc = read_enable;
  assign rdata = ram_rdata;

endmodule

module sync_fifo_ptr (
       input wire              clk,
       input wire              rst_n,
       input wire [ASIZE-1:0]  async_ptr,
       input wire              other_clk,
       input wire              other_rst_n,
       output reg [ASIZE-1:0]  synced_ptr
       );

  // Internal synchronizer registers
  reg [ASIZE-1:0] sync_reg1, sync_reg2;

  // Synchronize async_ptr to clk domain
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_reg1 <= 0;
      sync_reg2 <= 0;
      synced_ptr <= 0;
    end else begin
      sync_reg1 <= async_ptr;
      sync_reg2 <= sync_reg1;
      synced_ptr <= sync_reg2;
    end
  end

endmodule
