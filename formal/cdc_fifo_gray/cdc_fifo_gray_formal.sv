module cdc_fifo_gray_formal;
  (* gclk *) reg gclk;
  reg [6:0] tick = 0;
  always @(posedge gclk) tick <= tick + 1'b1;
  wire src_clk_i=tick[0], dst_clk_i=tick[1];
  wire src_rst_ni=tick>=2, dst_rst_ni=tick>=2;
  (* anyseq *) reg src_valid_i, dst_ready_i;
  reg [7:0] wr_seq=0, rd_seq=0;
  wire [7:0] src_data_i=wr_seq, dst_data_o;
  wire src_ready_o, dst_valid_o;
  cdc_fifo_gray #(.WIDTH(8),.LOG_DEPTH(2),.SYNC_STAGES(2)) dut(.*);
  always @(posedge src_clk_i) begin
    if (!src_rst_ni) wr_seq<=0;
    else if (src_valid_i && src_ready_o) wr_seq<=wr_seq+1'b1;
  end
  reg stalled;
  reg [7:0] stalled_data;
  always @(posedge dst_clk_i) begin
    if (!dst_rst_ni) begin rd_seq<=0; stalled<=0; assert(!dst_valid_o); end
    else begin
      if (dst_valid_o) assert(dst_data_o==rd_seq);
      if (stalled) begin assert(dst_valid_o); assert(dst_data_o==stalled_data); end
      stalled <= dst_valid_o && !dst_ready_i;
      stalled_data <= dst_data_o;
      if (dst_valid_o && dst_ready_i) rd_seq<=rd_seq+1'b1;
    end
  end
  
  always @(posedge gclk) begin
    cover(wr_seq>=4 && rd_seq>=3);
    cover(dst_valid_o && !dst_ready_i);
    cover(!src_ready_o);
  end
  always @* begin
    if (tick < 16) begin assume(!src_valid_i); assume(!dst_ready_i); end
  end
endmodule
