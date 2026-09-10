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

  reg [ASIZE-1:0] a_wr_ptr;
  reg [ASIZE-1:0] a_rd_ptr;
  reg [ASIZE-1:0] b_wr_ptr;
  reg [ASIZE-1:0] b_rd_ptr;
  reg [ASIZE:0] a_count;
  reg [ASIZE:0] b_count;
  reg a_empty_int;
  reg a_full_int;
  reg b_empty_int;
  reg b_full_int;

  assign o_ram_a_clk = a_clk;
  assign o_ram_b_clk = b_clk;

  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_count <= 0;
      a_empty_int <= 1'b1;
      a_full_int <= 1'b0;
    end else begin
      if (a_winc &&!a_full_int) begin
        a_wr_ptr <= a_wr_ptr + 1;
        a_count <= a_count + 1;
        a_empty_int <= 1'b0;
        if (a_count == (1 << ASIZE) - 1) begin
          a_full_int <= 1'b1;
        end
      end
      if (a_rinc &&!a_empty_int) begin
        a_rd_ptr <= a_rd_ptr + 1;
        a_count <= a_count - 1;
        a_full_int <= 1'b0;
        if (a_count == 0) begin
          a_empty_int <= 1'b1;
        end
      end
    end
  end

  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_count <= 0;
      b_empty_int <= 1'b1;
      b_full_int <= 1'b0;
    end else begin
      if (b_winc &&!b_full_int) begin
        b_wr_ptr <= b_wr_ptr + 1;
        b_count <= b_count + 1;
        b_empty_int <= 1'b0;
        if (b_count == (1 << ASIZE) - 1) begin
          b_full_int <= 1'b1;
        end
      end
      if (b_rinc &&!b_empty_int) begin
        b_rd_ptr <= b_rd_ptr + 1;
        b_count <= b_count - 1;
        b_full_int <= 1'b0;
        if (b_count == 0) begin
          b_empty_int <= 1'b1;
        end
      end
    end
  end

  assign a_empty = a_empty_int;
  assign a_full = a_full_int;
  assign b_empty = b_empty_int;
  assign b_full = b_full_int;

  assign a_afull = (a_count >= (1 << ASIZE) - 2);
  assign b_afull = (b_count >= (1 << ASIZE) - 2);
  assign a_aempty = (a_count <= 2);
  assign b_aempty = (b_count <= 2);

  assign o_ram_a_addr = a_wr_ptr;
  assign o_ram_b_addr = b_wr_ptr;

  assign o_ram_a_wdata = a_wdata;
  assign o_ram_b_wdata = b_wdata;

  assign o_ram_a_winc = a_winc &&!a_full_int;
  assign o_ram_b_winc = b_winc &&!b_full_int;

  assign o_ram_a_rinc = a_rinc &&!a_empty_int;
  assign o_ram_b_rinc = b_rinc &&!b_empty_int;

  assign a_rdata = i_ram_a_rdata;
  assign b_rdata = i_ram_b_rdata;

endmodule
