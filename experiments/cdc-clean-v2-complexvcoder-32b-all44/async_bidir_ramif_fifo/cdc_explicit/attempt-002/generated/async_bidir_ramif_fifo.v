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

   wire a_full_sync_b;
   wire a_empty_sync_b;
   wire b_full_sync_a;
   wire b_empty_sync_a;

   async_fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
   fifo_a_side (
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
      .peer_clk(b_clk),
      .peer_rst_n(b_rst_n),
      .peer_full(b_full_sync_a),
      .peer_empty(b_empty_sync_a),
      .ram_clk(o_ram_a_clk),
      .ram_wdata(o_ram_a_wdata),
      .ram_rdata(i_ram_a_rdata),
      .ram_addr(o_ram_a_addr),
      .ram_rinc(o_ram_a_rinc),
      .ram_winc(o_ram_a_winc)
   );

   async_fifo_side #(.DSIZE(DSIZE), .ASIZE(ASIZE), .FALLTHROUGH(FALLTHROUGH))
   fifo_b_side (
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
      .peer_clk(a_clk),
      .peer_rst_n(a_rst_n),
      .peer_full(a_full_sync_b),
      .peer_empty(a_empty_sync_b),
      .ram_clk(o_ram_b_clk),
      .ram_wdata(o_ram_b_wdata),
      .ram_rdata(i_ram_b_rdata),
      .ram_addr(o_ram_b_addr),
      .ram_rinc(o_ram_b_rinc),
      .ram_winc(o_ram_b_winc)
   );

   sync_cell sync_a_full_b (
      .clk(b_clk),
      .rst_n(b_rst_n),
      .din(a_full),
      .dout(a_full_sync_b)
   );

   sync_cell sync_a_empty_b (
      .clk(b_clk),
      .rst_n(b_rst_n),
      .din(a_empty),
      .dout(a_empty_sync_b)
   );

   sync_cell sync_b_full_a (
      .clk(a_clk),
      .rst_n(a_rst_n),
      .din(b_full),
      .dout(b_full_sync_a)
   );

   sync_cell sync_b_empty_a (
      .clk(a_clk),
      .rst_n(a_rst_n),
      .din(b_empty),
      .dout(b_empty_sync_a)
   );

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
       input wire              peer_clk,
       input wire              peer_rst_n,
       input wire              peer_full,
       input wire              peer_empty,
       output wire             ram_clk,
       output wire [DSIZE-1:0] ram_wdata,
       input wire [DSIZE-1:0]  ram_rdata,
       output wire [ASIZE-1:0] ram_addr,
       output wire             ram_rinc,
       output wire             ram_winc
       );

   reg [ASIZE-1:0] read_ptr;
   reg [ASIZE-1:0] write_ptr;
   reg [ASIZE-1:0] read_ptr_gray;
   reg [ASIZE-1:0] write_ptr_gray;
   wire [ASIZE-1:0] synced_read_ptr_gray;
   wire [ASIZE-1:0] synced_write_ptr_gray;
   wire [ASIZE-1:0] synced_read_ptr;
   wire [ASIZE-1:0] synced_write_ptr;
   reg [DSIZE-1:0] rdata_reg;

   wire [ASIZE-1:0] read_ptr_gray_next;
   wire [ASIZE-1:0] write_ptr_gray_next;

   wire full_flag;
   wire afull_flag;
   wire empty_flag;
   wire aempty_flag;

   sync_cell sync_read_ptr_gray (
      .clk(peer_clk),
      .rst_n(peer_rst_n),
      .din(read_ptr_gray),
      .dout(synced_read_ptr_gray)
   );

   sync_cell sync_write_ptr_gray (
      .clk(peer_clk),
      .rst_n(peer_rst_n),
      .din(write_ptr_gray),
      .dout(synced_write_ptr_gray)
   );

   assign read_ptr_gray_next  = (rinc) ? (read_ptr + 1) : read_ptr;
   assign write_ptr_gray_next = (winc) ? (write_ptr + 1) : write_ptr;

   assign read_ptr_gray = (rinc) ? (read_ptr_gray_next ^ read_ptr_gray_next >> 1) : read_ptr_gray;
   assign write_ptr_gray = (winc) ? (write_ptr_gray_next ^ write_ptr_gray_next >> 1) : write_ptr_gray;

   assign synced_read_ptr = synced_read_ptr_gray ^ (synced_read_ptr_gray >> 1);
   assign synced_write_ptr = synced_write_ptr_gray ^ (synced_write_ptr_gray >> 1);

   assign full_flag = (synced_read_ptr == (synced_write_ptr + 1)) | (synced_read_ptr == {ASIZE{1'b0}} & synced_write_ptr == {ASIZE{1'b1}});
   assign afull_flag = (synced_read_ptr == synced_write_ptr_gray_next) | (synced_read_ptr == {ASIZE{1'b0}} & synced_write_ptr_gray_next == {ASIZE{1'b1}});
   assign empty_flag = (read_ptr == write_ptr_gray);
   assign aempty_flag = (read_ptr_gray == write_ptr_gray);

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         read_ptr <= {ASIZE{1'b0}};
         write_ptr <= {ASIZE{1'b0}};
      end else begin
         if (rinc) read_ptr <= read_ptr_next;
         if (winc) write_ptr <= write_ptr_next;
      end
   end

   assign ram_clk = clk;
   assign ram_wdata = wdata;
   assign ram_addr = write_ptr;
   assign ram_winc = winc;
   assign ram_rinc = rinc;

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         rdata_reg <= {DSIZE{1'b0}};
      end else if (rinc) begin
         rdata_reg <= ram_rdata;
      end
   end

   assign rdata = rdata_reg;
   assign full = full_flag;
   assign afull = afull_flag;
   assign empty = empty_flag;
   assign aempty = aempty_flag;

endmodule

module sync_cell (
       input wire clk,
       input wire rst_n,
       input wire din,
       output wire dout
       );

   reg reg1;
   reg reg2;

   always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
         reg1 <= 1'b0;
         reg2 <= 1'b0;
      end else begin
         reg1 <= din;
         reg2 <= reg1;
      end
   end

   assign dout = reg2;

endmodule
