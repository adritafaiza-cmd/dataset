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

  localparam AWIDTH = ASIZE + 1;
  localparam DEPTH  = 1 << ASIZE;

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
  wire [AWIDTH-1:0] a_wr_ptr_gray  = a_wr_ptr ^ {a_wr_ptr[AWIDTH-1:AWIDTH-2], a_wr_ptr[AWIDTH-2:0]};
  wire [AWIDTH-1:0] a_rd_ptr_gray  = a_rd_ptr ^ {a_rd_ptr[AWIDTH-1:AWIDTH-2], a_rd_ptr[AWIDTH-2:0]};
  wire [AWIDTH-1:0] b_wr_ptr_gray  = b_wr_ptr ^ {b_wr_ptr[AWIDTH-1:AWIDTH-2], b_wr_ptr[AWIDTH-2:0]};
  wire [AWIDTH-1:0] b_rd_ptr_gray  = b_rd_ptr ^ {b_rd_ptr[AWIDTH-1:AWIDTH-2], b_rd_ptr[AWIDTH-2:0]};

  // Gray code of binary pointers from other side
  wire [AWIDTH-1:0] a_wr_ptr_b_gray  = a_wr_ptr_b ^ {a_wr_ptr_b[AWIDTH-1:AWIDTH-2], a_wr_ptr_b[AWIDTH-2:0]};
  wire [AWIDTH-1:0] a_rd_ptr_b_gray  = a_rd_ptr_b ^ {a_rd_ptr_b[AWIDTH-1:AWIDTH-2], a_rd_ptr_b[AWIDTH-2:0]};
  wire [AWIDTH-1:0] b_wr_ptr_a_gray  = b_wr_ptr_a ^ {b_wr_ptr_a[AWIDTH-1:AWIDTH-2], b_wr_ptr_a[AWIDTH-2:0]};
  wire [AWIDTH-1:0] b_rd_ptr_a_gray  = b_rd_ptr_a ^ {b_rd_ptr_a[AWIDTH-1:AWIDTH-2], b_rd_ptr_a[AWIDTH-2:0]};

  // Synchronizers for A side (receiving B's pointers)
  reg [AWIDTH-1:0] b_wr_ptr_a_sync1, b_wr_ptr_a_sync2;
  reg [AWIDTH-1:0] b_rd_ptr_a_sync1, b_rd_ptr_a_sync2;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      b_wr_ptr_a_sync1 <= {AWIDTH{1'b0}};
      b_wr_ptr_a_sync2 <= {AWIDTH{1'b0}};
      b_rd_ptr_a_sync1 <= {AWIDTH{1'b0}};
      b_rd_ptr_a_sync2 <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_a_sync1 <= b_wr_ptr_a_gray;
      b_wr_ptr_a_sync2 <= b_wr_ptr_a_sync1;
      b_rd_ptr_a_sync1 <= b_rd_ptr_a_gray;
      b_rd_ptr_a_sync2 <= b_rd_ptr_a_sync1;
    end
  end

  // Synchronizers for B side (receiving A's pointers)
  reg [AWIDTH-1:0] a_wr_ptr_b_sync1, a_wr_ptr_b_sync2;
  reg [AWIDTH-1:0] a_rd_ptr_b_sync1, a_rd_ptr_b_sync2;

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      a_wr_ptr_b_sync1 <= {AWIDTH{1'b0}};
      a_wr_ptr_b_sync2 <= {AWIDTH{1'b0}};
      a_rd_ptr_b_sync1 <= {AWIDTH{1'b0}};
      a_rd_ptr_b_sync2 <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_b_sync1 <= a_wr_ptr_gray;
      a_wr_ptr_b_sync2 <= a_wr_ptr_b_sync1;
      a_rd_ptr_b_sync1 <= a_rd_ptr_gray;
      a_rd_ptr_b_sync2 <= a_rd_ptr_b_sync1;
    end
  end

  // Convert synchronized gray codes back to binary
  function [AWIDTH-1:0] gray2bin;
    input [AWIDTH-1:0] gray;
    integer i;
    begin
      gray2bin[AWIDTH-1] = gray[AWIDTH-1];
      for (i = AWIDTH-2; i >= 0; i = i - 1)
        gray2bin[i] = gray2bin[i+1] ^ gray[i];
    end
  endfunction

  wire [AWIDTH-1:0] b_wr_ptr_a_bin = gray2bin(b_wr_ptr_a_sync2);
  wire [AWIDTH-1:0] b_rd_ptr_a_bin = gray2bin(b_rd_ptr_a_sync2);
  wire [AWIDTH-1:0] a_wr_ptr_b_bin = gray2bin(a_wr_ptr_b_sync2);
  wire [AWIDTH-1:0] a_rd_ptr_b_bin = gray2bin(a_rd_ptr_b_sync2);

  // Update binary pointer registers on each side
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr_b <= {AWIDTH{1'b0}};
      a_rd_ptr_b <= {AWIDTH{1'b0}};
    end else begin
      a_wr_ptr_b <= b_wr_ptr_a_bin;
      a_rd_ptr_b <= b_rd_ptr_a_bin;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr_a <= {AWIDTH{1'b0}};
      b_rd_ptr_a <= {AWIDTH{1'b0}};
    end else begin
      b_wr_ptr_a <= a_wr_ptr_b_bin;
      b_rd_ptr_a <= a_rd_ptr_b_bin;
    end
  end

  // Determine effective write/read pointers based on direction
  // When a_dir=0: A writes, B reads (A->B direction)
  // When a_dir=1: B writes, A reads (B->A direction)
  // Similarly for b_dir

  // For A side:
  // If a_dir=0 (A is writer): A's write pointer is local, A's read pointer comes from B
  // If a_dir=1 (A is reader): A's read pointer is local, A's write pointer comes from B

  wire a_is_writer = ~a_dir;
  wire a_is_reader = a_dir;

  wire b_is_writer = ~b_dir;
  wire b_is_reader = b_dir;

  // Effective pointers for A side
  wire [AWIDTH-1:0] a_eff_wr_ptr = a_is_writer ? a_wr_ptr : a_wr_ptr_b;
  wire [AWIDTH-1:0] a_eff_rd_ptr = a_is_reader ? a_rd_ptr : a_rd_ptr_b;

  // Effective pointers for B side
  wire [AWIDTH-1:0] b_eff_wr_ptr = b_is_writer ? b_wr_ptr : b_wr_ptr_a;
  wire [AWIDTH-1:0] b_eff_rd_ptr = b_is_reader ? b_rd_ptr : b_rd_ptr_a;

  // Full/Empty flags
  // Full: write pointer has lapped read pointer by DEPTH
  // Empty: write pointer equals read pointer

  wire a_full  = (a_eff_wr_ptr[AWIDTH-1:1] == a_eff_rd_ptr[AWIDTH-1:1]) &&
                 (a_eff_wr_ptr[0] != a_eff_rd_ptr[0]);
  wire a_empty = (a_eff_wr_ptr == a_eff_rd_ptr);

  wire b_full  = (b_eff_wr_ptr[AWIDTH-1:1] == b_eff_rd_ptr[AWIDTH-1:1]) &&
                 (b_eff_wr_ptr[0] != b_eff_rd_ptr[0]);
  wire b_empty = (b_eff_wr_ptr == b_eff_rd_ptr);

  // Almost full/empty (1 entry margin)
  wire a_afull  = (a_eff_wr_ptr[AWIDTH-1:1] == a_eff_rd_ptr[AWIDTH-1:1]) &&
                  (a_eff_wr_ptr[0] == a_eff_rd_ptr[0]) &&
                  (a_eff_wr_ptr[1] != a_eff_rd_ptr[1]);
  wire a_aempty = (a_eff_wr_ptr[AWIDTH-1:1] == a_eff_rd_ptr[AWIDTH-1:1]) &&
                  (a_eff_wr_ptr[0] == a_eff_rd_ptr[0]) &&
                  (a_eff_wr_ptr[1] != a_eff_rd_ptr[1]);

  wire b_afull  = (b_eff_wr_ptr[AWIDTH-1:1] == b_eff_rd_ptr[AWIDTH-1:1]) &&
                  (b_eff_wr_ptr[0] == b_eff_rd_ptr[0]) &&
                  (b_eff_wr_ptr[1] != b_eff_rd_ptr[1]);
  wire b_aempty = (b_eff_wr_ptr[AWIDTH-1:1] == b_eff_rd_ptr[AWIDTH-1:1]) &&
                  (b_eff_wr_ptr[0] == b_eff_rd_ptr[0]) &&
                  (b_eff_wr_ptr[1] != b_eff_rd_ptr[1]);

  // RAM interface
  // A side RAM: used when A is writer or reader
  // B side RAM: used when B is writer or reader

  // A side RAM clock
  assign o_ram_a_clk = a_clk;
  // B side RAM clock
  assign o_ram_b_clk = b_clk;

  // A side RAM write
  wire a_ram_wen = a_is_writer && a_winc && !a_full;
  assign o_ram_a_winc  = a_ram_wen;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_addr  = a_wr_ptr[ASIZE-1:0];

  // A side RAM read
  wire a_ram_ren = a_is_reader && a_rinc && !a_empty;
  assign o_ram_a_rinc  = a_ram_ren;

  // B side RAM write
  wire b_ram_wen = b_is_writer && b_winc && !b_full;
  assign o_ram_b_winc  = b_ram_wen;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_addr  = b_wr_ptr[ASIZE-1:0];

  // B side RAM read
  wire b_ram_ren = b_is_reader && b_rinc && !b_empty;
  assign o_ram_b_rinc  = b_ram_ren;

  // Read data output
  // With fall-through, data is available immediately after write
  // Without fall-through, data is available one cycle after read enable

  // For simplicity, we assume the RAM provides data combinationally or with one cycle latency
  // The read data from RAM is directly used

  assign a_rdata = i_ram_a_rdata;
  assign b_rdata = i_ram_b_rdata;

  // Pointer updates
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= {AWIDTH{1'b0}};
      a_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (a_is_writer && a_winc && !a_full)
        a_wr_ptr <= a_wr_ptr + 1'b1;
      if (a_is_reader && a_rinc && !a_empty)
        a_rd_ptr <= a_rd_ptr + 1'b1;
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= {AWIDTH{1'b0}};
      b_rd_ptr <= {AWIDTH{1'b0}};
    end else begin
      if (b_is_writer && b_winc && !b_full)
        b_wr_ptr <= b_wr_ptr + 1'b1;
      if (b_is_reader && b_rinc && !b_empty)
        b_rd_ptr <= b_rd_ptr + 1'b1;
    end
  end

endmodule
