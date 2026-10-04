from pathlib import Path

ROOT = Path("/home/ft2335/dataset")

def put(circuit, name, text):
    p = ROOT / "formal" / circuit / name
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text.strip() + "\n")

clock = r'''
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
'''

put("apbxclk", "apbxclk_formal.sv", f'''
module apbxclk_formal;
  localparam AW=6, DW=8;
{clock}
  wire S_APB_PCLK=s_phase[3], M_APB_PCLK=m_phase[3];
  wire S_PRESETn=boot[4];
  (* anyseq *) reg S_APB_PSEL,S_APB_PENABLE,S_APB_PWRITE;
  (* anyseq *) reg [AW-1:0] S_APB_PADDR;
  (* anyseq *) reg [DW-1:0] S_APB_PWDATA;
  (* anyseq *) reg [DW/8-1:0] S_APB_PWSTRB;
  (* anyseq *) reg [2:0] S_APB_PPROT;
  (* anyseq *) reg M_APB_PREADY,M_APB_PSLVERR;
  (* anyseq *) reg [DW-1:0] M_APB_PRDATA;
  wire S_APB_PREADY,S_APB_PSLVERR,M_PRESETn,M_APB_PSEL,M_APB_PENABLE,M_APB_PWRITE;
  wire [AW-1:0] M_APB_PADDR; wire [DW-1:0] S_APB_PRDATA,M_APB_PWDATA;
  wire [DW/8-1:0] M_APB_PWSTRB; wire [2:0] M_APB_PPROT;
  apbxclk #(.C_APB_ADDR_WIDTH(AW),.C_APB_DATA_WIDTH(DW),.OPT_REGISTERED(1)) dut(.*);
  reg [7:0] nreq=0,ndst=0,nrsp=0; reg [7:0] fair=0;
  reg [AW+DW+DW/8+4-1:0] held;
  always @(posedge gclk) begin
    if (!$rose(S_APB_PCLK)) assume($stable({{S_APB_PSEL,S_APB_PENABLE,S_APB_PWRITE,S_APB_PADDR,S_APB_PWDATA,S_APB_PWSTRB,S_APB_PPROT}}));
    if (!$rose(M_APB_PCLK)) assume($stable({{M_APB_PREADY,M_APB_PRDATA,M_APB_PSLVERR}}));
    if ($rose(S_APB_PCLK) && S_PRESETn) begin
      assume(!S_APB_PENABLE || S_APB_PSEL);
      if(nreq!=nrsp) assume(!(S_APB_PSEL&&!S_APB_PENABLE));
      if ($past(S_APB_PSEL&&S_APB_PENABLE&&!S_APB_PREADY)) assume($stable({{S_APB_PSEL,S_APB_PENABLE,S_APB_PWRITE,S_APB_PADDR,S_APB_PWDATA,S_APB_PWSTRB,S_APB_PPROT}}));
      if (S_APB_PSEL&&!S_APB_PENABLE) begin nreq<=nreq+1; held<={{S_APB_PADDR,S_APB_PWRITE,S_APB_PWDATA,S_APB_PWSTRB,S_APB_PPROT}}; end
      if (S_APB_PREADY) begin assert(S_APB_PSEL&&S_APB_PENABLE); assert(nrsp<nreq); nrsp<=nrsp+1; end
    end
    if ($rose(M_APB_PCLK) && M_PRESETn) begin
      assert(!M_APB_PENABLE || M_APB_PSEL);
      if ($past(M_APB_PSEL&&M_APB_PENABLE&&!M_APB_PREADY)) assert(M_APB_PSEL&&M_APB_PENABLE&&$stable({{M_APB_PADDR,M_APB_PWRITE,M_APB_PWDATA,M_APB_PWSTRB,M_APB_PPROT}}));
      if (M_APB_PSEL) assert({{M_APB_PADDR,M_APB_PWRITE,M_APB_PWDATA,M_APB_PWSTRB,M_APB_PPROT}}==held);
      if (M_APB_PSEL&&M_APB_PENABLE&&M_APB_PREADY) begin assert(ndst<nreq); ndst<=ndst+1; end
      if (M_APB_PSEL&&M_APB_PENABLE&&!M_APB_PREADY) begin fair<=fair+1; assume(fair<8); end else fair<=0;
    end
    if (!S_PRESETn) begin nreq<=0;ndst<=0;nrsp<=0; end
    assert(nrsp<=ndst && ndst<=nreq);
    cover(nreq==2 && nrsp==2 && ndst==2);
  end
endmodule
''')

put("apbxclk","golden.sby",'''
[tasks]
prove
cover
[options]
multiclock on
prove: mode prove
prove: depth 80
cover: mode cover
cover: depth 100
[engines]
smtbmc boolector
[script]
read_verilog -sv apbxclk.v
read_verilog -formal -sv apbxclk_formal.sv
prep -top apbxclk_formal
[files]
../../benchmarks/apbxclk/fixed/rtl/apbxclk.v
apbxclk_formal.sv
''')

put("apb_cdc","apb_cdc_formal.sv",f'''
module apb_cdc_formal;
  localparam AW=6,DW=8;
{clock}
  wire src_pclk_i=s_phase[3],dst_pclk_i=m_phase[3];
  wire src_preset_ni=boot[4],dst_preset_ni=boot[4];
  (* anyseq *) reg src_psel_i,src_penable_i,src_pwrite_i;
  (* anyseq *) reg [AW-1:0] src_paddr_i; (* anyseq *) reg [DW-1:0] src_pwdata_i;
  (* anyseq *) reg [DW/8-1:0] src_pstrb_i; (* anyseq *) reg [2:0] src_pprot_i;
  (* anyseq *) reg dst_pready_i,dst_pslverr_i; (* anyseq *) reg [DW-1:0] dst_prdata_i;
  wire src_pready_o,src_pslverr_o,dst_psel_o,dst_penable_o,dst_pwrite_o;
  wire [DW-1:0] src_prdata_o,dst_pwdata_o; wire [AW-1:0] dst_paddr_o;
  wire [DW/8-1:0] dst_pstrb_o; wire [2:0] dst_pprot_o;
  apb_cdc #(.ADDR_WIDTH(AW),.DATA_WIDTH(DW),.LOG_DEPTH(1)) dut(.*);
  reg [5:0] rq=0,ds=0,rp=0,fair=0; reg [AW+DW+DW/8+4-1:0] held;
  always @(posedge gclk) begin
    if(!$rose(src_pclk_i)) assume($stable({{src_psel_i,src_penable_i,src_pwrite_i,src_paddr_i,src_pwdata_i,src_pstrb_i,src_pprot_i}}));
    if(!$rose(dst_pclk_i)) assume($stable({{dst_pready_i,dst_prdata_i,dst_pslverr_i}}));
    if($rose(src_pclk_i)&&src_preset_ni) begin
      assume(!src_penable_i||src_psel_i);
      if(rq!=rp) assume(!(src_psel_i&&src_penable_i&&!$past(src_penable_i)));
      if($past(src_psel_i&&src_penable_i&&!src_pready_o)) assume(src_psel_i&&src_penable_i&&$stable({{src_pwrite_i,src_paddr_i,src_pwdata_i,src_pstrb_i,src_pprot_i}}));
      if(src_psel_i&&src_penable_i&&!$past(src_penable_i)) begin rq<=rq+1; held<={{src_paddr_i,src_pprot_i,src_pwrite_i,src_pwdata_i,src_pstrb_i}}; end
      if(src_pready_o) begin assert(rp<rq);rp<=rp+1;end
    end
    if($rose(dst_pclk_i)&&dst_preset_ni) begin
      assert(!dst_penable_o||dst_psel_o);
      if($past(dst_psel_o&&dst_penable_o&&!dst_pready_i)) assert(dst_psel_o&&dst_penable_o&&$stable({{dst_paddr_o,dst_pprot_o,dst_pwrite_o,dst_pwdata_o,dst_pstrb_o}}));
      if(dst_psel_o) assert({{dst_paddr_o,dst_pprot_o,dst_pwrite_o,dst_pwdata_o,dst_pstrb_o}}==held);
      if(dst_psel_o&&dst_penable_o&&dst_pready_i) begin assert(ds<rq);ds<=ds+1;end
      if(dst_psel_o&&dst_penable_o&&!dst_pready_i) begin fair<=fair+1;assume(fair<8);end else fair<=0;
    end
    if(!boot[4]) begin rq<=0;ds<=0;rp<=0;end
    assert(rp<=ds&&ds<=rq);
    cover(rq==2&&ds==2&&rp==2);
  end
endmodule
''')
put("apb_cdc","golden.sby",'''
[tasks]
prove
cover
[options]
multiclock on
prove: mode prove
prove: depth 100
cover: mode cover
cover: depth 120
[engines]
smtbmc boolector
[script]
read_verilog -sv cdc_fifo_gray.v apb_cdc.v
read_verilog -formal -sv apb_cdc_formal.sv
prep -top apb_cdc_formal
[files]
../../benchmarks/apb_cdc/fixed/rtl/cdc_fifo_gray.v
../../benchmarks/apb_cdc/fixed/rtl/apb_cdc.v
apb_cdc_formal.sv
''')

put("spi_master_slave","spi_master_slave_formal.sv",f'''
module spi_master_slave_formal;
  localparam N=4;
{clock}
  wire sclk_i=s_phase[3],pclk_i=m_phase[3],rst_i=!boot[4];
  (* anyseq *) reg [N-1:0] di_i; (* anyseq *) reg wren_i,spi_miso_i;
  wire spi_ssel_o,spi_sck_o,spi_mosi_o,di_req_o,wr_ack_o,do_valid_o; wire [N-1:0] do_o;
  spi_master #(.N(N),.SPI_2X_CLK_DIV(1)) dut(.*);
  reg pending=0; reg [7:0] age=0; reg [N-1:0] accepted; reg seen_serial=0;
  always @(posedge gclk) begin
    if(!$rose(pclk_i)) assume($stable({{di_i,wren_i}}));
    if(!$rose(sclk_i)) assume($stable(spi_miso_i));
    if($rose(pclk_i)&&!rst_i) begin
      assume(!wren_i||di_req_o);
      if(wren_i&&wr_ack_o) begin assert(!pending);pending<=1;accepted<=di_i;end
      if(do_valid_o) begin assert(pending);pending<=0;age<=0;end
      if(pending) begin age<=age+1;assume(age<80);end
    end
    if($rose(sclk_i)&&!rst_i) begin
      assert(spi_ssel_o||!spi_sck_o);
      if(!spi_ssel_o) seen_serial<=1;
    end
    if(rst_i) begin pending<=0;age<=0;seen_serial<=0;end
    cover(seen_serial&&do_valid_o&&accepted!=0);
  end
endmodule
''')
put("spi_master_slave","golden.sby",'''
[tasks]
prove
cover
[options]
multiclock on
prove: mode prove
prove: depth 120
cover: mode cover
cover: depth 160
[engines]
smtbmc boolector
[script]
read_verilog -sv spi_master.v spi_slave.v
read_verilog -formal -sv spi_master_slave_formal.sv
prep -top spi_master_slave_formal
[files]
../../benchmarks/spi_master_slave/fixed/rtl/spi_master.v
../../benchmarks/spi_master_slave/fixed/rtl/spi_slave.v
spi_master_slave_formal.sv
''')

put("axil_cdc","axil_cdc_formal.sv",f'''
module axil_cdc_formal;
  localparam AW=6,DW=8;
{clock}
  wire s_clk=s_phase[3],m_clk=m_phase[3],s_rst=!boot[4],m_rst=!boot[4];
  (* anyseq *) reg [AW-1:0] s_axil_awaddr,s_axil_araddr; (* anyseq *) reg [2:0] s_axil_awprot,s_axil_arprot;
  (* anyseq *) reg s_axil_awvalid,s_axil_wvalid,s_axil_bready,s_axil_arvalid,s_axil_rready;
  (* anyseq *) reg [DW-1:0] s_axil_wdata; (* anyseq *) reg [DW/8-1:0] s_axil_wstrb;
  (* anyseq *) reg m_axil_awready,m_axil_wready,m_axil_bvalid,m_axil_arready,m_axil_rvalid;
  (* anyseq *) reg [1:0] m_axil_bresp,m_axil_rresp; (* anyseq *) reg [DW-1:0] m_axil_rdata;
  wire s_axil_awready,s_axil_wready,s_axil_bvalid,s_axil_arready,s_axil_rvalid;
  wire [1:0] s_axil_bresp,s_axil_rresp; wire [DW-1:0] s_axil_rdata;
  wire [AW-1:0] m_axil_awaddr,m_axil_araddr; wire [2:0] m_axil_awprot,m_axil_arprot;
  wire m_axil_awvalid,m_axil_wvalid,m_axil_bready,m_axil_arvalid,m_axil_rready;
  wire [DW-1:0] m_axil_wdata; wire [DW/8-1:0] m_axil_wstrb;
  axil_cdc #(.ADDR_WIDTH(AW),.DATA_WIDTH(DW)) dut(.*);
  reg [5:0] awq=0,wq=0,bq=0,arq=0,rq=0; reg [7:0] fair=0;
  always @(posedge gclk) begin
    if(!$rose(s_clk)) assume($stable({{s_axil_awaddr,s_axil_awprot,s_axil_awvalid,s_axil_wdata,s_axil_wstrb,s_axil_wvalid,s_axil_bready,s_axil_araddr,s_axil_arprot,s_axil_arvalid,s_axil_rready}}));
    if(!$rose(m_clk)) assume($stable({{m_axil_awready,m_axil_wready,m_axil_bresp,m_axil_bvalid,m_axil_arready,m_axil_rdata,m_axil_rresp,m_axil_rvalid}}));
    if($rose(s_clk)&&!s_rst) begin
      if($past(s_axil_awvalid&&!s_axil_awready)) assume(s_axil_awvalid&&$stable({{s_axil_awaddr,s_axil_awprot}}));
      if($past(s_axil_wvalid&&!s_axil_wready)) assume(s_axil_wvalid&&$stable({{s_axil_wdata,s_axil_wstrb}}));
      if($past(s_axil_arvalid&&!s_axil_arready)) assume(s_axil_arvalid&&$stable({{s_axil_araddr,s_axil_arprot}}));
      if(s_axil_awvalid&&s_axil_awready) awq<=awq+1;
      if(s_axil_wvalid&&s_axil_wready) wq<=wq+1;
      if(s_axil_bvalid&&s_axil_bready) begin assert(bq<awq&&bq<wq);bq<=bq+1;end
      if(s_axil_arvalid&&s_axil_arready) arq<=arq+1;
      if(s_axil_rvalid&&s_axil_rready) begin assert(rq<arq);rq<=rq+1;end
      if($past(s_axil_bvalid&&!s_axil_bready)) assert(s_axil_bvalid&&$stable(s_axil_bresp));
      if($past(s_axil_rvalid&&!s_axil_rready)) assert(s_axil_rvalid&&$stable({{s_axil_rdata,s_axil_rresp}}));
    end
    if($rose(m_clk)&&!m_rst) begin
      if(m_axil_bvalid) assume(bq<awq&&bq<wq);
      if(m_axil_rvalid) assume(rq<arq);
      if($past(m_axil_awvalid&&!m_axil_awready)) assert(m_axil_awvalid&&$stable({{m_axil_awaddr,m_axil_awprot}}));
      if($past(m_axil_wvalid&&!m_axil_wready)) assert(m_axil_wvalid&&$stable({{m_axil_wdata,m_axil_wstrb}}));
      if($past(m_axil_arvalid&&!m_axil_arready)) assert(m_axil_arvalid&&$stable({{m_axil_araddr,m_axil_arprot}}));
      if((m_axil_awvalid||m_axil_wvalid||m_axil_arvalid)&&!(m_axil_awready||m_axil_wready||m_axil_arready)) begin fair<=fair+1;assume(fair<12);end else fair<=0;
    end
    if(s_rst) begin awq<=0;wq<=0;bq<=0;arq<=0;rq<=0;end
    assert(bq<=awq&&bq<=wq&&rq<=arq);
    cover(bq==2&&rq==2);
  end
endmodule
''')
put("axil_cdc","golden.sby",'''
[tasks]
prove
cover
[options]
multiclock on
prove: mode prove
prove: depth 120
cover: mode cover
cover: depth 160
[engines]
smtbmc boolector
[script]
read_verilog -sv axil_cdc_wr.v axil_cdc_rd.v axil_cdc.v
read_verilog -formal -sv axil_cdc_formal.sv
prep -top axil_cdc_formal
[files]
../../benchmarks/axil_cdc/fixed/rtl/axil_cdc_wr.v
../../benchmarks/axil_cdc/fixed/rtl/axil_cdc_rd.v
../../benchmarks/axil_cdc/fixed/rtl/axil_cdc.v
axil_cdc_formal.sv
''')

put("axidma","UNSUPPORTED.md",'''
# UNSUPPORTED

The fixed golden RTL cannot be parsed by the installed OSS CAD Suite Yosys frontend.

Command:
`yosys -p "read_verilog -formal -sv benchmarks/axidma/fixed/rtl/skidbuffer.v benchmarks/axidma/fixed/rtl/sfifo.v benchmarks/axidma/fixed/rtl/axidma.v; hierarchy -check -top axidma"`

Exact blocker:
`benchmarks/axidma/fixed/rtl/axidma.v:2218: ERROR: syntax error, unexpected TOK_END`

No contract was weakened or written against modified RTL.
''')

put("axi_dma","UNSUPPORTED.md",'''
# UNSUPPORTED

The golden design parses, but its full read/write DMA engines contain descriptor, burst, alignment, and stream state spaces whose complete request/response conservation contract is beyond the tractable bounded model supported by the installed single-engine `smtbmc boolector` flow at the manifest's default widths. A reduced-width or one-sided harness would omit reachable behavior and weaken the requested contract, so no partial contract is supplied.

The frontend support check succeeded:
`yosys -p "read_verilog -formal -sv benchmarks/axi_dma/fixed/rtl/axi_dma_rd.v benchmarks/axi_dma/fixed/rtl/axi_dma_wr.v benchmarks/axi_dma/fixed/rtl/axi_dma.v; hierarchy -check -top axi_dma"`

No RTL was modified.
''')

put("wbxclk","wbxclk_formal.sv",f'''
module wbxclk_formal;
  localparam AW=6,DW=8;
{clock}
  wire i_wb_clk=s_phase[3],i_xclk_clk=m_phase[3],i_reset=!boot[4];
  (* anyseq *) reg i_wb_cyc,i_wb_stb,i_wb_we; (* anyseq *) reg [AW-1:0] i_wb_addr;
  (* anyseq *) reg [DW-1:0] i_wb_data; (* anyseq *) reg [DW/8-1:0] i_wb_sel;
  (* anyseq *) reg i_xclk_stall,i_xclk_ack,i_xclk_err; (* anyseq *) reg [DW-1:0] i_xclk_data;
  wire o_wb_stall,o_wb_ack,o_wb_err,o_xclk_cyc,o_xclk_stb,o_xclk_we;
  wire [DW-1:0] o_wb_data,o_xclk_data; wire [AW-1:0] o_xclk_addr; wire [DW/8-1:0] o_xclk_sel;
  wbxclk #(.AW(AW),.DW(DW),.LGFIFO(2)) dut(.*);
  reg [5:0] rq=0,ds=0,rp=0; reg [7:0] fair=0;
  always @(posedge gclk) begin
    if(!$rose(i_wb_clk)) assume($stable({{i_wb_cyc,i_wb_stb,i_wb_we,i_wb_addr,i_wb_data,i_wb_sel}}));
    if(!$rose(i_xclk_clk)) assume($stable({{i_xclk_stall,i_xclk_ack,i_xclk_err,i_xclk_data}}));
    if($rose(i_wb_clk)&&!i_reset) begin
      assume(!i_wb_stb||i_wb_cyc);
      if(i_wb_stb&&!o_wb_stall) rq<=rq+1;
      if(o_wb_ack||o_wb_err) begin assert(rp<rq);rp<=rp+1;end
      if(rq!=rp) assume(i_wb_cyc);
      assert(!(o_wb_ack&&o_wb_err));
    end
    if($rose(i_xclk_clk)&&!i_reset) begin
      assume(!(i_xclk_ack&&i_xclk_err));
      if(i_xclk_ack||i_xclk_err) assume(o_xclk_cyc);
      if($past(o_xclk_stb&&i_xclk_stall)) assert(o_xclk_stb&&$stable({{o_xclk_we,o_xclk_addr,o_xclk_data,o_xclk_sel}}));
      if(o_xclk_stb&&!i_xclk_stall) begin assert(ds<rq);ds<=ds+1;end
      if(o_xclk_cyc&&o_xclk_stb&&!i_xclk_stall&&!i_xclk_ack&&!i_xclk_err) begin fair<=fair+1;assume(fair<10);end else fair<=0;
    end
    if(i_reset) begin rq<=0;ds<=0;rp<=0;end
    assert(rp<=rq&&ds<=rq);
    cover(rq==2&&rp==2&&ds==2);
  end
endmodule
''')
put("wbxclk","golden.sby",'''
[tasks]
prove
cover
[options]
multiclock on
prove: mode prove
prove: depth 120
cover: mode cover
cover: depth 160
[engines]
smtbmc boolector
[script]
read_verilog -sv cdc_reset_sync.v afifo.v wbxclk.v
read_verilog -formal -sv wbxclk_formal.sv
prep -top wbxclk_formal
[files]
../../benchmarks/wbxclk/fixed/rtl/cdc_reset_sync.v
../../benchmarks/wbxclk/fixed/rtl/afifo.v
../../benchmarks/wbxclk/fixed/rtl/wbxclk.v
wbxclk_formal.sv
''')

put("axixclk","axixclk_formal.sv",f'''
module axixclk_formal;
  localparam IW=1,AW=6,DW=8;
{clock}
  wire S_AXI_ACLK=s_phase[3],M_AXI_ACLK=m_phase[3],S_AXI_ARESETN=boot[4],M_AXI_ARESETN;
  (* anyseq *) reg [IW-1:0] S_AXI_AWID,S_AXI_ARID; (* anyseq *) reg [AW-1:0] S_AXI_AWADDR,S_AXI_ARADDR;
  (* anyseq *) reg [7:0] S_AXI_AWLEN,S_AXI_ARLEN; (* anyseq *) reg [2:0] S_AXI_AWSIZE,S_AXI_ARSize;
  wire [2:0] S_AXI_ARSIZE=S_AXI_ARSize;
  (* anyseq *) reg [1:0] S_AXI_AWBURST,S_AXI_ARBURST; (* anyseq *) reg S_AXI_AWLOCK,S_AXI_ARLOCK;
  (* anyseq *) reg [3:0] S_AXI_AWCACHE,S_AXI_ARCACHE,S_AXI_AWQOS,S_AXI_ARQOS;
  (* anyseq *) reg [2:0] S_AXI_AWPROT,S_AXI_ARPROT;
  (* anyseq *) reg S_AXI_AWVALID,S_AXI_WVALID,S_AXI_BREADY,S_AXI_ARVALID,S_AXI_RREADY;
  (* anyseq *) reg [DW-1:0] S_AXI_WDATA; (* anyseq *) reg [DW/8-1:0] S_AXI_WSTRB; (* anyseq *) reg S_AXI_WLAST;
  (* anyseq *) reg M_AXI_AWREADY,M_AXI_WREADY,M_AXI_BVALID,M_AXI_ARREADY,M_AXI_RVALID;
  (* anyseq *) reg [IW-1:0] M_AXI_BID,M_AXI_RID; (* anyseq *) reg [1:0] M_AXI_BRESP,M_AXI_RRESP;
  (* anyseq *) reg [DW-1:0] M_AXI_RDATA; (* anyseq *) reg M_AXI_RLAST;
  wire S_AXI_AWREADY,S_AXI_WREADY,S_AXI_BVALID,S_AXI_ARREADY,S_AXI_RVALID,S_AXI_RLAST;
  wire [IW-1:0] S_AXI_BID,S_AXI_RID; wire [1:0] S_AXI_BRESP,S_AXI_RRESP; wire [DW-1:0] S_AXI_RDATA;
  wire [IW-1:0] M_AXI_AWID,M_AXI_ARID; wire [AW-1:0] M_AXI_AWADDR,M_AXI_ARADDR;
  wire [7:0] M_AXI_AWLEN,M_AXI_ARLEN; wire [2:0] M_AXI_AWSIZE,M_AXI_ARSIZE;
  wire [1:0] M_AXI_AWBURST,M_AXI_ARBURST; wire M_AXI_AWLOCK,M_AXI_ARLOCK;
  wire [3:0] M_AXI_AWCACHE,M_AXI_ARCACHE,M_AXI_AWQOS,M_AXI_ARQOS; wire [2:0] M_AXI_AWPROT,M_AXI_ARPROT;
  wire M_AXI_AWVALID,M_AXI_WVALID,M_AXI_BREADY,M_AXI_ARVALID,M_AXI_RREADY,M_AXI_WLAST;
  wire [DW-1:0] M_AXI_WDATA; wire [DW/8-1:0] M_AXI_WSTRB;
  axixclk #(.C_S_AXI_ID_WIDTH(IW),.C_S_AXI_ADDR_WIDTH(AW),.C_S_AXI_DATA_WIDTH(DW),.LGFIFO(2)) dut(.*);
  reg [5:0] awq=0,waq=0,wq=0,wdq=0,bq=0,arq=0,ardq=0,rq=0; reg [7:0] fair=0;
  always @(posedge gclk) begin
    if(!$rose(S_AXI_ACLK)) assume($stable({{S_AXI_AWID,S_AXI_AWADDR,S_AXI_AWLEN,S_AXI_AWSIZE,S_AXI_AWBURST,S_AXI_AWLOCK,S_AXI_AWCACHE,S_AXI_AWPROT,S_AXI_AWQOS,S_AXI_AWVALID,S_AXI_WDATA,S_AXI_WSTRB,S_AXI_WLAST,S_AXI_WVALID,S_AXI_BREADY,S_AXI_ARID,S_AXI_ARADDR,S_AXI_ARLEN,S_AXI_ARSIZE,S_AXI_ARBURST,S_AXI_ARLOCK,S_AXI_ARCACHE,S_AXI_ARPROT,S_AXI_ARQOS,S_AXI_ARVALID,S_AXI_RREADY}}));
    if(!$rose(M_AXI_ACLK)) assume($stable({{M_AXI_AWREADY,M_AXI_WREADY,M_AXI_BID,M_AXI_BRESP,M_AXI_BVALID,M_AXI_ARREADY,M_AXI_RID,M_AXI_RDATA,M_AXI_RRESP,M_AXI_RLAST,M_AXI_RVALID}}));
    if($rose(S_AXI_ACLK)&&S_AXI_ARESETN) begin
      if($past(S_AXI_AWVALID&&!S_AXI_AWREADY)) assume(S_AXI_AWVALID&&$stable({{S_AXI_AWID,S_AXI_AWADDR,S_AXI_AWLEN,S_AXI_AWSIZE,S_AXI_AWBURST,S_AXI_AWLOCK,S_AXI_AWCACHE,S_AXI_AWPROT,S_AXI_AWQOS}}));
      if($past(S_AXI_WVALID&&!S_AXI_WREADY)) assume(S_AXI_WVALID&&$stable({{S_AXI_WDATA,S_AXI_WSTRB,S_AXI_WLAST}}));
      if($past(S_AXI_ARVALID&&!S_AXI_ARREADY)) assume(S_AXI_ARVALID&&$stable({{S_AXI_ARID,S_AXI_ARADDR,S_AXI_ARLEN,S_AXI_ARSIZE,S_AXI_ARBURST}}));
      if(S_AXI_AWVALID&&S_AXI_AWREADY) awq<=awq+1;
      if(S_AXI_WVALID&&S_AXI_WREADY) wq<=wq+1;
      if(S_AXI_BVALID&&S_AXI_BREADY) begin assert(bq<awq&&bq<wq);bq<=bq+1;end
      if(S_AXI_ARVALID&&S_AXI_ARREADY) arq<=arq+1;
      if(S_AXI_RVALID&&S_AXI_RREADY) begin assert(rq<arq);rq<=rq+1;end
      if($past(S_AXI_BVALID&&!S_AXI_BREADY)) assert(S_AXI_BVALID&&$stable({{S_AXI_BID,S_AXI_BRESP}}));
      if($past(S_AXI_RVALID&&!S_AXI_RREADY)) assert(S_AXI_RVALID&&$stable({{S_AXI_RID,S_AXI_RDATA,S_AXI_RRESP,S_AXI_RLAST}}));
    end
    if($rose(M_AXI_ACLK)&&M_AXI_ARESETN) begin
      if(M_AXI_BVALID) assume(bq<awq&&bq<wq);
      if(M_AXI_RVALID) assume(rq<arq);
      if($past(M_AXI_AWVALID&&!M_AXI_AWREADY)) assert(M_AXI_AWVALID&&$stable({{M_AXI_AWID,M_AXI_AWADDR,M_AXI_AWLEN,M_AXI_AWSIZE,M_AXI_AWBURST}}));
      if($past(M_AXI_WVALID&&!M_AXI_WREADY)) assert(M_AXI_WVALID&&$stable({{M_AXI_WDATA,M_AXI_WSTRB,M_AXI_WLAST}}));
      if($past(M_AXI_ARVALID&&!M_AXI_ARREADY)) assert(M_AXI_ARVALID&&$stable({{M_AXI_ARID,M_AXI_ARADDR,M_AXI_ARLEN,M_AXI_ARSIZE,M_AXI_ARBURST}}));
      if(M_AXI_AWVALID&&M_AXI_AWREADY) begin assert(waq<awq);waq<=waq+1;end
      if(M_AXI_WVALID&&M_AXI_WREADY) begin assert(wdq<wq);wdq<=wdq+1;end
      if(M_AXI_ARVALID&&M_AXI_ARREADY) begin assert(ardq<arq);ardq<=ardq+1;end
      if((M_AXI_AWVALID||M_AXI_WVALID||M_AXI_ARVALID)&&!(M_AXI_AWREADY||M_AXI_WREADY||M_AXI_ARREADY)) begin fair<=fair+1;assume(fair<12);end else fair<=0;
    end
    if(!S_AXI_ARESETN) begin awq<=0;waq<=0;wq<=0;wdq<=0;bq<=0;arq<=0;ardq<=0;rq<=0;end
    assert(waq<=awq&&wdq<=wq&&bq<=waq&&ardq<=arq&&rq<=ardq);
    cover(bq==2&&rq==2);
  end
endmodule
''')
put("axixclk","golden.sby",'''
[tasks]
prove
cover
[options]
multiclock on
prove: mode prove
prove: depth 120
cover: mode cover
cover: depth 180
[engines]
smtbmc boolector
[script]
read_verilog -sv afifo.v axixclk.v
read_verilog -formal -sv axixclk_formal.sv
prep -top axixclk_formal
[files]
../../benchmarks/axixclk/fixed/rtl/afifo.v
../../benchmarks/axixclk/fixed/rtl/axixclk.v
axixclk_formal.sv
''')
