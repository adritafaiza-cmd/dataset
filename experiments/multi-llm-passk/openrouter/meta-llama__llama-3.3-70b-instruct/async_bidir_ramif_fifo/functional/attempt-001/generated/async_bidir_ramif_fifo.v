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

   reg [ASIZE-1:0] a_ptr;
   reg [ASIZE-1:0] b_ptr;
   reg [ASIZE-1:0] a_cnt;
   reg [ASIZE-1:0] b_cnt;
   reg [DSIZE-1:0] a_rdata_reg;
   reg [DSIZE-1:0] b_rdata_reg;
   reg a_empty_reg;
   reg a_aempty_reg;
   reg a_full_reg;
   reg a_afull_reg;
   reg b_empty_reg;
   reg b_aempty_reg;
   reg b_full_reg;
   reg b_afull_reg;

   assign o_ram_a_clk = a_clk;
   assign o_ram_b_clk = b_clk;

   always @(posedge a_clk or negedge a_rst_n)
     begin
        if (!a_rst_n)
          begin
             a_ptr <= 0;
             a_cnt <= 0;
             a_rdata_reg <= 0;
             a_empty_reg <= 1;
             a_aempty_reg <= 1;
             a_full_reg <= 0;
             a_afull_reg <= 0;
          end
        else
          begin
             if (a_winc &&!a_full_reg)
               begin
                  a_cnt <= a_cnt + 1;
                  if (a_cnt == (1 << ASIZE) - 1)
                    a_full_reg <= 1;
               end
             if (a_rinc &&!a_empty_reg)
               begin
                  a_cnt <= a_cnt - 1;
                  if (a_cnt == 0)
                    a_empty_reg <= 1;
               end
             if (a_rinc &&!a_empty_reg)
               a_rdata_reg <= i_ram_a_rdata;
             if (a_empty_reg && a_rinc)
               a_aempty_reg <= 1;
             else if (a_rdata_reg!= 0 &&!a_empty_reg)
               a_aempty_reg <= 0;
             if (a_cnt > (1 << (ASIZE - 1)) - 1)
               a_afull_reg <= 1;
             else
               a_afull_reg <= 0;
          end
     end

   always @(posedge b_clk or negedge b_rst_n)
     begin
        if (!b_rst_n)
          begin
             b_ptr <= 0;
             b_cnt <= 0;
             b_rdata_reg <= 0;
             b_empty_reg <= 1;
             b_aempty_reg <= 1;
             b_full_reg <= 0;
             b_afull_reg <= 0;
          end
        else
          begin
             if (b_winc &&!b_full_reg)
               begin
                  b_cnt <= b_cnt + 1;
                  if (b_cnt == (1 << ASIZE) - 1)
                    b_full_reg <= 1;
               end
             if (b_rinc &&!b_empty_reg)
               begin
                  b_cnt <= b_cnt - 1;
                  if (b_cnt == 0)
                    b_empty_reg <= 1;
               end
             if (b_rinc &&!b_empty_reg)
               b_rdata_reg <= i_ram_b_rdata;
             if (b_empty_reg && b_rinc)
               b_aempty_reg <= 1;
             else if (b_rdata_reg!= 0 &&!b_empty_reg)
               b_aempty_reg <= 0;
             if (b_cnt > (1 << (ASIZE - 1)) - 1)
               b_afull_reg <= 1;
             else
               b_afull_reg <= 0;
          end
     end

   assign a_rdata = a_rdata_reg;
   assign b_rdata = b_rdata_reg;
   assign a_empty = a_empty_reg;
   assign a_aempty = a_aempty_reg;
   assign a_full = a_full_reg;
   assign a_afull = a_afull_reg;
   assign b_empty = b_empty_reg;
   assign b_aempty = b_aempty_reg;
   assign b_full = b_full_reg;
   assign b_afull = b_afull_reg;

   assign o_ram_a_addr = a_ptr;
   assign o_ram_b_addr = b_ptr;

   always @(posedge a_clk)
     begin
        if (a_winc &&!a_full_reg)
          begin
             o_ram_a_wdata <= a_wdata;
             o_ram_a_winc <= 1;
          end
        else
          o_ram_a_winc <= 0;
     end

   always @(posedge b_clk)
     begin
        if (b_winc &&!b_full_reg)
          begin
             o_ram_b_wdata <= b_wdata;
             o_ram_b_winc <= 1;
          end
        else
          o_ram_b_winc <= 0;
     end

   always @(posedge a_clk)
     begin
        if (a_rinc &&!a_empty_reg)
          o_ram_a_rinc <= 1;
        else
          o_ram_a_rinc <= 0;
     end

   always @(posedge b_clk)
     begin
        if (b_rinc &&!b_empty_reg)
          o_ram_b_rinc <= 1;
        else
          o_ram_b_rinc <= 0;
     end

   always @(posedge a_clk)
     begin
        if (a_winc &&!a_full_reg)
          a_ptr <= a_ptr + 1;
        if (a_rinc &&!a_empty_reg)
          a_ptr <= a_ptr - 1;
     end

   always @(posedge b_clk)
     begin
        if (b_winc &&!b_full_reg)
          b_ptr <= b_ptr + 1;
        if (b_rinc &&!b_empty_reg)
          b_ptr <= b_ptr - 1;
     end

endmodule
