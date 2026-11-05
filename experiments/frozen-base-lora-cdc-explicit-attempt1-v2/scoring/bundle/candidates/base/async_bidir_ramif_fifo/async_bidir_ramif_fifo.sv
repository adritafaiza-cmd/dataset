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

  localparam DEPTH = 1 << ASIZE;
  localparam AWIDTH = ASIZE + 1;
  localparam AFULL_THRESH = DEPTH - 1;
  localparam AEMPTY_THRESH = 1;

  // Side A registers
  reg [AWIDTH-1:0] a_wr_ptr;
  reg [AWIDTH-1:0] a_rd_ptr;
  reg [AWIDTH-1:0] a_wr_ptr_b;
  reg [AWIDTH-1:0] a_rd_ptr_b;

  // Side B registers
  reg [AWIDTH-1:0] b_wr_ptr;
  reg [AWIDTH-1:0] b_rd_ptr;
  reg [AWIDTH-1:0] b_wr_ptr_a;
  reg [AWIDTH-1:0] b_rd_ptr_a;

  // Gray code pointers
  wire [AWIDTH-1:0] a_wr_ptr_gray;
  wire [AWIDTH-1:0] a_rd_ptr_gray;
  wire [AWIDTH-1:0] b_wr_ptr_gray;
  wire [AWIDTH-1:0] b_rd_ptr_gray;

  assign a_wr_ptr_gray = a_wr_ptr ^ (a_wr_ptr >> 1);
  assign a_rd_ptr_gray = a_rd_ptr ^ (a_rd_ptr >> 1);
  assign b_wr_ptr_gray = b_wr_ptr ^ (b_rd_ptr >> 1);
  assign b_rd_ptr_gray = b_rd_ptr ^ (b_rd_ptr >> 1);

  // Synchronizers for A side (receiving B's pointers)
  reg [AWIDTH-1:0] b_wr_ptr_gray_sync1;
  reg [AWIDTH-1:0] b_wr_ptr_gray_sync2;
  reg [AWIDTH-1:0] b_rd_ptr_gray_sync1;
  reg [AWIDTH-1:0] b_rd_ptr_gray_sync2;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      b_wr_ptr_gray_sync2 <= {AWIDTH{1'b0}};
      b_rd_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      b_rd_ptr_gray_sync2 <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_gray_sync1 <= b_wr_ptr_gray;
      b_wr_ptr_gray_sync2 <= b_wr_ptr_gray_sync1;
      b_rd_ptr_gray_sync1 <= b_rd_ptr_gray;
      b_rd_ptr_gray_sync2 <= b_rd_ptr_gray_sync1;
    end
  end

  // Synchronizers for B side (receiving A's pointers)
  reg [AWIDTH-1:0] a_wr_ptr_gray_sync1;
  reg [AWIDTH-1:0] a_wr_ptr_gray_sync2;
  reg [AWIDTH-1:0] a_rd_ptr_gray_sync1;
  reg [AWIDTH-1:0] a_rd_ptr_gray_sync2;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      a_wr_ptr_gray_sync2 <= {AWIDTH{1'b0}};
      a_rd_ptr_gray_sync1 <= {AWIDTH{1'b0}};
      a_rd_ptr_gray_sync2 <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_gray_sync1 <= a_wr_ptr_gray;
      a_wr_ptr_gray_sync2 <= a_wr_ptr_gray_sync1;
      a_rd_ptr_gray_sync1 <= a_rd_ptr_gray;
      a_rd_ptr_gray_sync2 <= a_rd_ptr_gray_sync1;
    end
  end

  // Convert synchronized gray codes back to binary
  function [AWIDTH-1:0] gray_to_bin;
    input [AWIDTH-1:0] gray;
    integer i;
    begin
      gray_to_bin[AWIDTH-1] = gray[AWIDTH-1];
      for (i = AWIDTH-2; i >= 0; i = i - 1)
        gray_to_bin[i] = gray_to_bin[i+1] ^ gray[i];
    end
  endfunction

  wire [AWIDTH-1:0] b_wr_ptr_a_sync = gray_to_bin(b_wr_ptr_gray_sync2);
  wire [AWIDTH-1:0] b_rd_ptr_a_sync = gray_to_bin(b_rd_ptr_gray_sync2);
  wire [AWIDTH-1:0] a_wr_ptr_b_sync = gray_to_bin(a_wr_ptr_gray_sync2);
  wire [AWIDTH-1:0] a_rd_ptr_b_sync = gray_to_bin(a_rd_ptr_gray_sync2);

  // Update local copies of remote pointers
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_a <= {AWIDTH{1'b0}};
      b_rd_ptr_a <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_a <= b_wr_ptr_a_sync;
      b_rd_ptr_a <= b_rd_ptr_a_sync;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_b <= {AWIDTH{1'b0}};
      a_rd_ptr_b <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_b <= a_wr_ptr_b_sync;
      a_rd_ptr_b <= a_rd_ptr_b_sync;
    end
  end

  // Write and read enables
  wire a_write_en = a_winc & ~a_full;
  wire a_read_en  = a_rinc & ~a_empty;
  wire b_write_en = b_winc & ~b_full;
  wire b_read_en  = b_rinc & ~b_empty;

  // Pointer updates
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {AWIDTH{1'b0}};
      a_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (a_write_en)
        a_wr_ptr <= a_wr_ptr + 1'b1;
      if (a_read_en)
        a_rd_ptr <= a_rd_ptr + 1'b1;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {AWIDTH{1'b0}};
      b_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (b_write_en)
        b_wr_ptr <= b_wr_ptr + 1'b1;
      if (b_read_en)
        b_rd_ptr <= b_rd_ptr + 1'b1;
    end
  end

  // Full and empty flags
  wire a_full  = (a_wr_ptr[AWIDTH-1] == a_rd_ptr_b_sync[AWIDTH-1]) &&
                 (a_wr_ptr[AWIDTH-2:0] == a_rd_ptr_b_sync[AWIDTH-2:0]) &&
                 (a_wr_ptr[AWIDTH-1] != a_rd_ptr_b_sync[AWIDTH-1]);
  // Correct full check: MSB differs, lower bits same
  wire a_full_correct = (a_wr_ptr[AWIDTH-1] != a_rd_ptr_b_sync[AWIDTH-1]) &&
                        (a_wr_ptr[AWIDTH-2:0] == a_rd_ptr_b_sync[AWIDTH-2:0]);
  wire a_empty = (a_wr_ptr == a_rd_ptr);

  wire b_full_correct = (b_wr_ptr[AWIDTH-1] != a_rd_ptr_a_sync[AWIDTH-1]) &&
                        (b_wr_ptr[AWIDTH-2:0] == a_rd_ptr_a_sync[AWIDTH-2:0]);
  wire b_empty = (b_wr_ptr == b_rd_ptr);

  assign a_full  = a_full_correct;
  assign a_empty = a_empty;
  assign b_full  = b_full_correct;
  assign b_empty = b_empty;

  // Almost full/empty
  wire [AWIDTH:0] a_count = a_wr_ptr - a_rd_ptr_b_sync;
  wire [AWIDTH:0] b_count = b_wr_ptr - a_rd_ptr_a_sync;

  assign a_afull  = (a_count >= AFULL_THRESH);
  assign a_aempty = (a_count <= AEMPTY_THRESH);
  assign b_afull  = (b_count >= AFULL_THRESH);
  assign b_aempty = (b_count <= AEMPTY_THRESH);

  // RAM interface
  assign o_ram_a_clk   = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr  = a_wr_ptr[ASIZE-1:0];
  assign o_ram_a_winc  = a_write_en;
  assign o_ram_a_rinc  = a_read_en;

  assign o_ram_b_clk   = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr  = b_wr_ptr[ASIZE-1:0];
  assign o_ram_b_winc  = b_write_en;
  assign o_ram_b_rinc  = b_read_en;

  // Read data output
  // For fall-through mode, we need to handle the first word specially.
  // In non-fall-through mode, read data is simply the RAM read data.
  // Since the RAM is external and we don't have internal storage, 
  // the read data comes directly from i_ram_*_rdata.
  // The address for reading is the read pointer.
  
  // We need to drive the read address to the RAM as well.
  // But the port list only has o_ram_a_addr which we're using for write.
  // Looking at the ports again: o_ram_a_addr is a single address output.
  // This suggests the RAM uses the same address for read and write, 
  // or we need to multiplex. Given the constraints, let's assume 
  // the address is driven based on the operation.
  
  // Actually, re-reading the problem: "Drive o_ram_* clocks, addresses, write data, and enables."
  // The address should be the read address when reading, write address when writing.
  // But we can only drive one address. Let's use the write address for writes 
  // and read address for reads. Since we have separate rinc and winc, 
  // we can multiplex the address.
  
  // However, the port is a single o_ram_a_addr. Let's drive it with 
  // the appropriate address based on whether we're reading or writing.
  // If both happen simultaneously (which shouldn't in a simple FIFO), 
  // we prioritize write.
  
  // Actually, for a dual-port RAM, typically there are separate read and write addresses.
  // But here we only have one address port per side. This is unusual.
  // Let me re-examine: the problem says "external dual-port RAM interface".
  // Perhaps the RAM has separate read and write ports, but the module only 
  // exposes one address per side? That doesn't make sense.
  
  // Let me assume that o_ram_a_addr is used for both read and write, 
  // and the RAM uses the enable signals to determine which operation.
  // This is a common simplification in some interfaces.
  
  // For now, let's drive the address with the write address when writing,
  // and the read address when reading.
  
  wire [ASIZE-1:0] a_rd_addr = a_rd_ptr[ASIZE-1:0];
  wire [ASIZE-1:0] b_rd_addr = b_rd_ptr[ASIZE-1:0];
  
  assign o_ram_a_addr = a_write_en ? a_wr_ptr[ASIZE-1:0] : a_rd_addr;
  assign o_ram_b_addr = b_write_en ? b_wr_ptr[ASIZE-1:0] : b_rd_addr;

  assign a_rdata = i_ram_a_rdata;
  assign b_rdata = i_ram_b_rdata;

endmodule
