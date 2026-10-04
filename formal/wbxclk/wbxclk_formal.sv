module wbxclk_formal;
  localparam AW=6,DW=8;

  (* gclk *) reg gclk;
  (* anyconst *) reg [3:0] s_step, m_step;
  reg [3:0] s_phase = 0, m_phase = 0;
  reg [4:0] boot = 0;
  always @(posedge gclk) begin
    assume(s_step >= 2 && s_step <= 7);
    assume(m_step >= 2 && m_step <= 7);
    assume(s_step != m_step);
    s_phase <= s_phase + s_step;
    m_phase <= m_phase + m_step;
    if (!boot[4]) boot <= boot + 1;
  end

  wire i_wb_clk=s_phase[3],i_xclk_clk=m_phase[3],i_reset=!boot[4];
  (* anyseq *) reg i_wb_cyc,i_wb_stb,i_wb_we; (* anyseq *) reg [AW-1:0] i_wb_addr;
  (* anyseq *) reg [DW-1:0] i_wb_data; (* anyseq *) reg [DW/8-1:0] i_wb_sel;
  (* anyseq *) reg i_xclk_stall,i_xclk_ack,i_xclk_err; (* anyseq *) reg [DW-1:0] i_xclk_data;
  wire o_wb_stall,o_wb_ack,o_wb_err,o_xclk_cyc,o_xclk_stb,o_xclk_we;
  wire [DW-1:0] o_wb_data,o_xclk_data; wire [AW-1:0] o_xclk_addr; wire [DW/8-1:0] o_xclk_sel;
  wbxclk #(.AW(AW),.DW(DW),.LGFIFO(2)) dut(.*);
  reg [5:0] rq=0,ds=0,rp=0; reg [7:0] fair=0;
  always @(posedge gclk) begin
    if(!$rose(i_wb_clk)) assume($stable({i_wb_cyc,i_wb_stb,i_wb_we,i_wb_addr,i_wb_data,i_wb_sel}));
    if(!$rose(i_xclk_clk)) assume($stable({i_xclk_stall,i_xclk_ack,i_xclk_err,i_xclk_data}));
    if($rose(i_wb_clk)&&!i_reset) begin
      assume(!i_wb_stb||i_wb_cyc);
      if(i_wb_stb&&!o_wb_stall) rq<=rq+1;
      if(o_wb_ack||o_wb_err) begin assert(rp<rq);rp<=rp+1;end
      if(rq!=rp) assume(i_wb_cyc);
      assert(!(o_wb_ack&&o_wb_err));
    end
    if($rose(i_xclk_clk)&&!i_reset) begin
      assume(!(i_xclk_ack&&i_xclk_err));
      if (i_xclk_ack || i_xclk_err) assume(o_xclk_cyc);
      if($past(o_xclk_stb&&i_xclk_stall)) assert(o_xclk_stb&&$stable({o_xclk_we,o_xclk_addr,o_xclk_data,o_xclk_sel}));
      if(o_xclk_stb&&!i_xclk_stall) begin assert(ds<rq);ds<=ds+1;end
      if(o_xclk_cyc&&o_xclk_stb&&!i_xclk_stall&&!i_xclk_ack&&!i_xclk_err) begin fair<=fair+1;assume(fair<10);end else fair<=0;
    end
    if(i_reset) begin rq<=0;ds<=0;rp<=0;end
    assert(rp<=rq&&ds<=rq);
    cover(rq==2&&rp==2&&ds==2);
  end
endmodule
