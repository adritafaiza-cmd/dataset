module async_bidir_ramif_fifo_formal;
 (* gclk *)reg gclk;reg[6:0]tick=0;always@(posedge gclk)tick<=tick+1;
 wire a_clk=tick[0],b_clk=tick[1];wire a_rst_n=tick>=2,b_rst_n=tick>=2;
 (* anyconst *)reg dir; wire a_dir=dir,b_dir=!dir;
 (* anyseq *)reg push,pop;reg[7:0]a_seq=0,b_seq=0;
 wire a_winc=dir?push:1'b0,b_winc=dir?1'b0:push,a_rinc=dir?1'b0:pop,b_rinc=dir?pop:1'b0;
 wire[7:0]a_wdata=a_seq,b_wdata=b_seq;wire[7:0]a_rdata,b_rdata;wire a_full,a_empty,b_full,b_empty,a_afull,a_aempty,b_afull,b_aempty;
 wire o_ram_a_clk,o_ram_b_clk,o_ram_a_rinc,o_ram_a_winc,o_ram_b_rinc,o_ram_b_winc;wire[7:0]o_ram_a_wdata,o_ram_b_wdata;wire[1:0]o_ram_a_addr,o_ram_b_addr;reg[7:0]mem[0:3];wire[7:0]i_ram_a_rdata=mem[o_ram_a_addr],i_ram_b_rdata=mem[o_ram_b_addr];always@(posedge o_ram_a_clk)if(o_ram_a_winc)mem[o_ram_a_addr]<=o_ram_a_wdata;always@(posedge o_ram_b_clk)if(o_ram_b_winc)mem[o_ram_b_addr]<=o_ram_b_wdata;
 async_bidir_ramif_fifo #(.DSIZE(8),.ASIZE(2),.FALLTHROUGH("FALSE")) dut(.*);
 always@*begin if(a_rst_n&&b_rst_n)begin assume(!push||(dir?!a_full:!b_full));assume(!pop||(dir?!b_empty:!a_empty));end end
 always@(posedge a_clk)begin
  if(!a_rst_n)begin a_seq<=0;assert(!a_full);assert(a_empty);end else if(dir)begin if(push&&!a_full)a_seq<=a_seq+1;end else begin if(!a_empty)assert(a_rdata==a_seq);if(pop&&!a_empty)a_seq<=a_seq+1;end end
 always@(posedge b_clk)begin
  if(!b_rst_n)begin b_seq<=0;assert(!b_full);assert(b_empty);end else if(!dir)begin if(push&&!b_full)b_seq<=b_seq+1;end else begin if(!b_empty)assert(b_rdata==b_seq);if(pop&&!b_empty)b_seq<=b_seq+1;end end
 always@(posedge gclk)begin cover(dir&&a_seq>=3&&b_seq>=2);cover(!dir&&b_seq>=3&&a_seq>=2);cover(dir&&b_empty&&b_seq>=2);cover(!dir&&a_empty&&a_seq>=2);end
  always @* begin
    if (tick < 16) begin assume(!push); assume(!pop); end
  end
endmodule
