module async_fifo_formal;
  (* gclk *) reg gclk;
  reg [5:0] tick = 0;
  always @(posedge gclk) tick <= tick + 1'b1;
  wire wclk = tick[0], rclk = tick[1];
  wire wrst_n = tick >= 2, rrst_n = tick >= 2;
  (* anyseq *) reg winc, rinc;
  reg [7:0] wseq = 0, rseq = 0;
  wire [7:0] wdata = wseq;
  wire [7:0] rdata;
  wire wfull, rempty;
  wire awfull, arempty;
  async_fifo #(.DSIZE(8),.ASIZE(2),.FALLTHROUGH("TRUE")) dut(.*);
  always @* begin
    if (wrst_n) assume(!winc || !wfull);
    if (rrst_n) assume(!rinc || !rempty);
  end
  always @(posedge wclk) begin
    if (!wrst_n) begin wseq <= 0; assert(!wfull); end
    else if (winc && !wfull) wseq <= wseq + 1'b1;
  end
  always @(posedge rclk) begin
    if (!rrst_n) begin rseq <= 0; assert(rempty); end
    else begin
      if (!rempty) assert(rdata == rseq);
      if (rinc && !rempty) rseq <= rseq + 1'b1;
    end
  end
  always @(posedge gclk) begin
    cover(wseq >= 3 && rseq >= 2);
    cover(wfull);
    cover(rempty && rseq >= 2);
  end
  always @* begin
    if (tick < 16) begin assume(!winc); assume(!rinc); end
  end
endmodule
