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

  wire [ASIZE-1:0] a_side_wr_addr_synced;
  wire [ASIZE-1:0] b_side_wr_addr_synced;

  async_fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  a_side (
    .clk(a_clk),
    .rst_n(a_rst_n),
    .winc(a_winc),
    .wdata(a_wdata),
    .rinc(a_rinc),
    .dir(a_dir),
    .rd_addr(b_side_wr_addr_synced),
    .wr_addr(o_ram_a_addr),
    .wr_addr_synced(a_side_wr_addr_synced),
    .rdata(a_rdata),
    .rdata_from_ram(i_ram_a_rdata),
    .full(a_full),
    .afull(a_afull),
    .empty(a_empty),
    .aempty(a_aempty),
    .other_clk(b_clk),
    .other_wr_addr(o_ram_b_addr)
  );

  async_fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
  b_side (
    .clk(b_clk),
    .rst_n(b_rst_n),
    .winc(b_winc),
    .wdata(b_wdata),
    .rinc(b_rinc),
    .dir(b_dir),
    .rd_addr(a_side_wr_addr_synced),
    .wr_addr(o_ram_b_addr),
    .wr_addr_synced(b_side_wr_addr_synced),
    .rdata(b_rdata),
    .rdata_from_ram(i_ram_b_rdata),
    .full(b_full),
    .afull(b_afull),
    .empty(b_empty),
    .aempty(b_aempty),
    .other_clk(a_clk),
    .other_wr_addr(o_ram_a_addr)
  );

  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign o_ram_a_rinc = a_rinc;
  assign o_ram_a_winc = a_winc;

  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign o_ram_b_rinc = b_rinc;
  assign o_ram_b_winc = b_winc;

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
       input wire              dir,
       input wire [ASIZE-1:0]  rd_addr,
       output wire [ASIZE-1:0] wr_addr,
       output wire [ASIZE-1:0] wr_addr_synced,
       output wire [DSIZE-1:0] rdata,
       input wire [DSIZE-1:0]  rdata_from_ram,
       output wire             full,
       output wire             afull,
       output wire             empty,
       output wire             aempty,
       input wire              other_clk,
       input wire [ASIZE-1:0]  other_wr_addr
       );

  reg [ASIZE-1:0] wr_ptr;
  reg [ASIZE-1:0] rd_ptr;
  reg [ASIZE-1:0] rd_ptr_synced;
  reg full_flag;
  reg afull_flag;
  reg empty_flag;
  reg aempty_flag;

  binary_sync #(.ASIZE(ASIZE))
  wr_addr_sync (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(wr_ptr),
    .data_out(wr_addr_synced),
    .other_clk(other_clk)
  );

  binary_sync #(.ASIZE(ASIZE))
  rd_addr_sync (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(other_wr_addr),
    .data_out(rd_ptr_synced),
    .other_clk(other_clk)
  );

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= 0;
      rd_ptr <= 0;
      full_flag <= 0;
      afull_flag <= 0;
      empty_flag <= 1;
      aempty_flag <= 1;
    end else begin
      if (winc && !full_flag) begin
        wr_ptr <= wr_ptr + 1;
        if (wr_ptr + 1 == rd_ptr_synced)
          full_flag <= 1;
        else
          full_flag <= 0;

        if (wr_ptr + 1 == rd_ptr_synced + 1)
          afull_flag <= 1;
        else
          afull_flag <= 0;
      end

      if (rinc && !empty_flag) begin
        rd_ptr <= rd_ptr + 1;
        if (wr_ptr == rd_ptr + 1)
          empty_flag <= 1;
        else
          empty_flag <= 0;

        if (wr_ptr == rd_ptr)
          aempty_flag <= 1;
        else
          aempty_flag <= 0;
      end
    end
  end

  assign wr_addr = wr_ptr;
  assign rdata = rdata_from_ram;
  assign full = full_flag;
  assign afull = afull_flag;
  assign empty = empty_flag;
  assign aempty = aempty_flag;

endmodule

module binary_sync
  #(
    parameter ASIZE = 4
    ) (
       input wire              clk,
       input wire              rst_n,
       input wire [ASIZE-1:0]  data_in,
       output wire [ASIZE-1:0] data_out,
       input wire              other_clk
       );

  reg [ASIZE-1:0] sync_reg1;
  reg [ASIZE-1:0] sync_reg2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_reg1 <= 0;
      sync_reg2 <= 0;
    end else begin
      sync_reg1 <= data_in;
      sync_reg2 <= sync_reg1;
    end
  end

  always @(posedge other_clk or negedge rst_n) begin
    if (!rst_n) begin
      data_out <= 0;
    end else begin
      data_out <= sync_reg2;
    end
  end

endmodule
