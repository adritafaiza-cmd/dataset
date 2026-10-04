module cdc_fifo_gray_clearable_formal;
  (* gclk *) reg gclk; reg [7:0] tick=0; always @(posedge gclk) tick<=tick+1'b1;
  wire src_clk_i=tick[0], dst_clk_i=tick[1]; wire src_rst_ni=tick>=2, dst_rst_ni=tick>=2;
  (* anyseq *) reg src_valid_i,dst_ready_i; wire src_clear_i=(tick==30), dst_clear_i=1'b0;
  reg [7:0] wr_seq=0,rd_seq=0; wire [7:0] src_data_i=wr_seq,dst_data_o;
  wire src_ready_o,dst_valid_o,src_clear_pending_o,dst_clear_pending_o;
  cdc_fifo_gray_clearable #(.WIDTH(8),.LOG_DEPTH(2),.SYNC_STAGES(2)) dut(.*);
  reg clear_epoch=0;
  always @(posedge src_clk_i) begin
    if(!src_rst_ni || src_clear_i) wr_seq<=0; else if(src_valid_i&&src_ready_o) wr_seq<=wr_seq+1;
    if(!src_rst_ni) assert(!src_clear_pending_o);
    if(src_clear_pending_o) assert(!src_ready_o);
  end
  reg stalled; reg [7:0] held;
  always @(posedge dst_clk_i) begin
    if(!dst_rst_ni || dst_clear_pending_o) begin rd_seq<=0; stalled<=0; end else begin
      if(dst_valid_o) assert(dst_data_o==rd_seq);
      if(stalled) begin assert(dst_valid_o); assert(dst_data_o==held); end
      stalled<=dst_valid_o&&!dst_ready_i; held<=dst_data_o;
      if(dst_valid_o&&dst_ready_i) rd_seq<=rd_seq+1;
    end
    if(dst_clear_pending_o) assert(!dst_valid_o);
  end
  always @(posedge gclk) begin
    cover(src_clear_pending_o && dst_clear_pending_o);
    cover(tick>80 && wr_seq>=2 && rd_seq>=1);
  end
  always @* begin
    if (tick < 16 || (tick >= 25 && tick < 80)) begin assume(!src_valid_i); assume(!dst_ready_i); end
  end
endmodule
