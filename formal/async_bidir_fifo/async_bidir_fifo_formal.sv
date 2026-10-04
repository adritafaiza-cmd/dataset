module async_bidir_fifo_formal;
 (* gclk *)reg gclk;reg[6:0]tick=0;always@(posedge gclk)tick<=tick+1;
 wire a_clk=tick[0],b_clk=tick[1];wire a_rst_n=tick>=2,b_rst_n=tick>=2;
 (* anyconst *)reg dir; wire a_dir=dir,b_dir=!dir;
 (* anyseq *)reg push,pop;reg[7:0]a_seq=0,b_seq=0;
 wire a_winc=dir?push:1'b0,b_winc=dir?1'b0:push,a_rinc=dir?1'b0:pop,b_rinc=dir?pop:1'b0;
 wire[7:0]a_wdata=a_seq,b_wdata=b_seq;wire[7:0]a_rdata,b_rdata;wire a_full,a_empty,b_full,b_empty,a_afull,a_aempty,b_afull,b_aempty;
 
 async_bidir_fifo #(.DSIZE(8),.ASIZE(2),.FALLTHROUGH("TRUE")) dut(.*);
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
