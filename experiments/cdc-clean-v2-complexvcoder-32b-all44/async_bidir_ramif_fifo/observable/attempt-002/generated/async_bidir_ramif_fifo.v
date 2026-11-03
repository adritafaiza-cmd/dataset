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

  // Internal signals for pointers and flags
  reg [ASIZE-1:0] a_wr_ptr, a_rd_ptr;
  reg [ASIZE-1:0] b_wr_ptr, b_rd_ptr;
  wire [ASIZE-1:0] a_wr_ptr_sync, a_rd_ptr_sync;
  wire [ASIZE-1:0] b_wr_ptr_sync, b_rd_ptr_sync;
  reg a_full_flag, a_empty_flag, a_afull_flag, a_aempty_flag;
  reg b_full_flag, b_empty_flag, b_afull_flag, b_aempty_flag;

  // Cross-domain synchronization for pointers
  cdc_sync #(.ASIZE(ASIZE)) a2b_wr_ptr_sync (
    .local(a_wr_ptr),
    .remote(a_wr_ptr_sync),
    .local_clk(a_clk),
    .local_rst_n(a_rst_n),
    .remote_clk(b_clk),
    .remote_rst_n(b_rst_n)
  );

  cdc_sync #(.ASIZE(ASIZE)) a2b_rd_ptr_sync (
    .local(a_rd_ptr),
    .remote(a_rd_ptr_sync),
    .local_clk(a_clk),
    .local_rst_n(a_rst_n),
    .remote_clk(b_clk),
    .remote_rst_n(b_rst_n)
  );

  cdc_sync #(.ASIZE(ASIZE)) b2a_wr_ptr_sync (
    .local(b_wr_ptr),
    .remote(b_wr_ptr_sync),
    .local_clk(b_clk),
    .local_rst_n(b_rst_n),
    .remote_clk(a_clk),
    .remote_rst_n(a_rst_n)
  );

  cdc_sync #(.ASIZE(ASIZE)) b2a_rd_ptr_sync (
    .local(b_rd_ptr),
    .remote(b_rd_ptr_sync),
    .local_clk(b_clk),
    .local_rst_n(b_rst_n),
    .remote_clk(a_clk),
    .remote_rst_n(a_rst_n)
  );

  // FIFO control logic for side A
  always @(posedge a_clk or negedge a_rst_n) begin
    if (!a_rst_n) begin
      a_wr_ptr <= 0;
      a_rd_ptr <= 0;
      a_full_flag <= 0;
      a_empty_flag <= 1;
      a_afull_flag <= 0;
      a_aempty_flag <= 0;
    end else begin
      // Update write pointer
      if (a_winc && !a_full_flag) begin
        a_wr_ptr <= a_wr_ptr + 1;
      end

      // Update read pointer
      if (a_rinc && !a_empty_flag) begin
        a_rd_ptr <= a_rd_ptr + 1;
      end

      // Update flags
      a_full_flag <= (a_wr_ptr_sync == (a_rd_ptr + 1));
      a_empty_flag <= (a_wr_ptr == a_rd_ptr);
      a_afull_flag <= (a_wr_ptr_sync == (a_rd_ptr + 2));
      a_aempty_flag <= (a_wr_ptr == (a_rd_ptr + 1));
    end
  end

  // FIFO control logic for side B
  always @(posedge b_clk or negedge b_rst_n) begin
    if (!b_rst_n) begin
      b_wr_ptr <= 0;
      b_rd_ptr <= 0;
      b_full_flag <= 0;
      b_empty_flag <= 1;
      b_afull_flag <= 0;
      b_aempty_flag <= 0;
    end else begin
      // Update write pointer
      if (b_winc && !b_full_flag) begin
        b_wr_ptr <= b_wr_ptr + 1;
      end

      // Update read pointer
      if (b_rinc && !b_empty_flag) begin
        b_rd_ptr <= b_rd_ptr + 1;
      end

      // Update flags
      b_full_flag <= (b_wr_ptr_sync == (b_rd_ptr + 1));
      b_empty_flag <= (b_wr_ptr == b_rd_ptr);
      b_afull_flag <= (b_wr_ptr_sync == (b_rd_ptr + 2));
      b_aempty_flag <= (b_wr_ptr == (b_rd_ptr + 1));
    end
  end

  // Output assignments for side A
  assign o_ram_a_clk = a_clk;
  assign o_ram_a_wdata = a_wdata;
  assign a_rdata = i_ram_a_rdata;
  assign o_ram_a_addr = a_wr_ptr_sync;
  assign o_ram_a_rinc = a_rinc && !a_empty_flag;
  assign o_ram_a_winc = a_winc && !a_full_flag;
  assign a_full = a_full_flag;
  assign a_afull = a_afull_flag;
  assign a_empty = a_empty_flag;
  assign a_aempty = a_aempty_flag;

  // Output assignments for side B
  assign o_ram_b_clk = b_clk;
  assign o_ram_b_wdata = b_wdata;
  assign b_rdata = i_ram_b_rdata;
  assign o_ram_b_addr = b_wr_ptr_sync;
  assign o_ram_b_rinc = b_rinc && !b_empty_flag;
  assign o_ram_b_winc = b_winc && !b_full_flag;
  assign b_full = b_full_flag;
  assign b_afull = b_afull_flag;
  assign b_empty = b_empty_flag;
  assign b_aempty = b_aempty_flag;

endmodule

module cdc_sync
  #(
    parameter ASIZE = 4
    ) (
       input wire [ASIZE-1:0]  local,
       output wire [ASIZE-1:0] remote,
       input wire              local_clk,
       input wire              local_rst_n,
       input wire              remote_clk,
       input wire              remote_rst_n
       );

  reg [ASIZE-1:0] sync_reg1, sync_reg2;

  always @(posedge local_clk or negedge local_rst_n) begin
    if (!local_rst_n) begin
      sync_reg1 <= 0;
    end else begin
      sync_reg1 <= local;
    end
  end

  always @(posedge remote_clk or negedge remote_rst_n) begin
    if (!remote_rst_n) begin
      sync_reg2 <= 0;
    end else begin
      sync_reg2 <= sync_reg1;
    end
  end

  assign remote = sync_reg2;

endmodule
