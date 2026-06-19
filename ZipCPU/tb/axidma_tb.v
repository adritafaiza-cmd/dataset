`timescale 1ns/1ps
`default_nettype none
module axidma_tb;
    localparam AW=8,DW=32,IW=1;
    reg clk=0,rstn=0; always #5 clk=~clk; integer errors=0; integer i;
    reg s_awvalid; wire s_awready; reg [4:0] s_awaddr; reg [2:0] s_awprot; reg s_wvalid; wire s_wready; reg [31:0] s_wdata; reg [3:0] s_wstrb; wire s_bvalid; reg s_bready; wire [1:0] s_bresp; reg s_arvalid; wire s_arready; reg [4:0] s_araddr; reg [2:0] s_arprot; wire s_rvalid; reg s_rready; wire [31:0] s_rdata; wire [1:0] s_rresp;
    wire m_awvalid; reg m_awready; wire [IW-1:0] m_awid; wire [AW-1:0] m_awaddr; wire [7:0] m_awlen; wire [2:0] m_awsize; wire [1:0] m_awburst; wire m_awlock; wire [3:0] m_awcache; wire [2:0] m_awprot; wire [3:0] m_awqos; wire m_wvalid; reg m_wready; wire [DW-1:0] m_wdata; wire [DW/8-1:0] m_wstrb; wire m_wlast; reg m_bvalid; wire m_bready; reg [IW-1:0] m_bid; reg [1:0] m_bresp; wire m_arvalid; reg m_arready; wire [IW-1:0] m_arid; wire [AW-1:0] m_araddr; wire [7:0] m_arlen; wire [2:0] m_arsize; wire [1:0] m_arburst; wire m_arlock; wire [3:0] m_arcache; wire [2:0] m_arprot; wire [3:0] m_arqos; reg m_rvalid; wire m_rready; reg [IW-1:0] m_rid; reg [DW-1:0] m_rdata; reg m_rlast; reg [1:0] m_rresp; wire o_int;
    reg [31:0] mem[0:63]; reg [AW-1:0] rd_addr, wr_addr; reg [7:0] rd_len, wr_len; integer rd_count, wr_count;
    axidma #(.C_AXI_ID_WIDTH(IW),.C_AXI_ADDR_WIDTH(AW),.C_AXI_DATA_WIDTH(DW),.OPT_UNALIGNED(1'b0),.OPT_WRAPMEM(1'b1),.LGMAXBURST(2),.LGFIFO(3),.LGLEN(AW)) dut(
        .S_AXI_ACLK(clk),.S_AXI_ARESETN(rstn),.S_AXIL_AWVALID(s_awvalid),.S_AXIL_AWREADY(s_awready),.S_AXIL_AWADDR(s_awaddr),.S_AXIL_AWPROT(s_awprot),.S_AXIL_WVALID(s_wvalid),.S_AXIL_WREADY(s_wready),.S_AXIL_WDATA(s_wdata),.S_AXIL_WSTRB(s_wstrb),.S_AXIL_BVALID(s_bvalid),.S_AXIL_BREADY(s_bready),.S_AXIL_BRESP(s_bresp),.S_AXIL_ARVALID(s_arvalid),.S_AXIL_ARREADY(s_arready),.S_AXIL_ARADDR(s_araddr),.S_AXIL_ARPROT(s_arprot),.S_AXIL_RVALID(s_rvalid),.S_AXIL_RREADY(s_rready),.S_AXIL_RDATA(s_rdata),.S_AXIL_RRESP(s_rresp),
        .M_AXI_AWVALID(m_awvalid),.M_AXI_AWREADY(m_awready),.M_AXI_AWID(m_awid),.M_AXI_AWADDR(m_awaddr),.M_AXI_AWLEN(m_awlen),.M_AXI_AWSIZE(m_awsize),.M_AXI_AWBURST(m_awburst),.M_AXI_AWLOCK(m_awlock),.M_AXI_AWCACHE(m_awcache),.M_AXI_AWPROT(m_awprot),.M_AXI_AWQOS(m_awqos),.M_AXI_WVALID(m_wvalid),.M_AXI_WREADY(m_wready),.M_AXI_WDATA(m_wdata),.M_AXI_WSTRB(m_wstrb),.M_AXI_WLAST(m_wlast),.M_AXI_BVALID(m_bvalid),.M_AXI_BREADY(m_bready),.M_AXI_BID(m_bid),.M_AXI_BRESP(m_bresp),.M_AXI_ARVALID(m_arvalid),.M_AXI_ARREADY(m_arready),.M_AXI_ARID(m_arid),.M_AXI_ARADDR(m_araddr),.M_AXI_ARLEN(m_arlen),.M_AXI_ARSIZE(m_arsize),.M_AXI_ARBURST(m_arburst),.M_AXI_ARLOCK(m_arlock),.M_AXI_ARCACHE(m_arcache),.M_AXI_ARPROT(m_arprot),.M_AXI_ARQOS(m_arqos),.M_AXI_RVALID(m_rvalid),.M_AXI_RREADY(m_rready),.M_AXI_RID(m_rid),.M_AXI_RDATA(m_rdata),.M_AXI_RLAST(m_rlast),.M_AXI_RRESP(m_rresp),.o_int(o_int));
    task check; input cond; input [255:0] msg; begin if(!cond) begin $display("FAIL: %s",msg); errors=errors+1; end else $display("PASS: %s",msg); end endtask
    task axil_write; input [4:0] addr; input [31:0] data; begin @(negedge clk); s_awaddr=addr; s_wdata=data; s_wstrb=4'hf; s_awvalid=1; s_wvalid=1; s_bready=1; wait(s_awready && s_wready); @(negedge clk); s_awvalid=0; s_wvalid=0; wait(s_bvalid); @(negedge clk); s_bready=0; end endtask
    task axil_read; input [4:0] addr; output [31:0] data; begin @(negedge clk); s_araddr=addr; s_arvalid=1; s_rready=1; wait(s_arready); @(negedge clk); s_arvalid=0; wait(s_rvalid); data=s_rdata; @(negedge clk); s_rready=0; end endtask
    reg [31:0] status;
    always @(posedge clk) begin
        m_awready <= 0; m_wready <= 0; m_arready <= 0;
        if (rstn && m_arvalid && !m_arready) begin m_arready <= 1; rd_addr <= m_araddr; rd_len <= m_arlen; rd_count <= 0; end
        if (rstn && m_awvalid && !m_awready) begin m_awready <= 1; wr_addr <= m_awaddr; wr_len <= m_awlen; wr_count <= 0; end
        if (rstn && m_wvalid) begin m_wready <= 1; mem[wr_addr[AW-1:2]] <= m_wdata; wr_addr <= wr_addr + 4; if (m_wlast) begin m_bvalid <= 1; m_bresp <= 0; m_bid <= m_awid; end end
        if (m_bvalid && m_bready) m_bvalid <= 0;
        if (!m_rvalid && rstn && (rd_count <= rd_len) && (m_arready || rd_count!=0)) begin m_rvalid <= 1; m_rdata <= mem[rd_addr[AW-1:2]]; m_rresp <= 0; m_rid <= m_arid; m_rlast <= (rd_count == rd_len); end
        if (m_rvalid && m_rready) begin m_rvalid <= 0; rd_addr <= rd_addr + 4; rd_count <= rd_count + 1; end
    end
    initial begin
        s_awvalid=0; s_awaddr=0; s_awprot=0; s_wvalid=0; s_wdata=0; s_wstrb=0; s_bready=0; s_arvalid=0; s_araddr=0; s_arprot=0; s_rready=0; m_bvalid=0; m_bresp=0; m_bid=0; m_rvalid=0; m_rid=0; m_rdata=0; m_rlast=0; m_rresp=0; rd_count=99; wr_count=0; for(i=0;i<64;i=i+1) mem[i]=0; mem[0]=32'h11111111; mem[1]=32'h22222222; mem[2]=32'h33333333; mem[3]=32'h44444444;
        repeat(5) @(posedge clk); rstn=1; repeat(5) @(posedge clk); $display("TEST AXIDMA");
        axil_write(5'h08, 32'h00000000); // SRCLO byte address 0x08 => src address 0
        axil_write(5'h10, 32'h00000040); // DSTLO byte address 0x10 => dst address 0x40
        axil_write(5'h18, 32'h00000010); // LENLO byte address 0x18 => 16 bytes
        axil_write(5'h00, 32'h00000001); // start
        repeat(200) @(posedge clk); axil_read(5'h00,status); check(status[0]==0,"DMA no longer busy"); check(mem[16]==32'h11111111 && mem[17]==32'h22222222 && mem[18]==32'h33333333 && mem[19]==32'h44444444,"DMA copied 4 words");
        $display(errors?"TESTS FAILED":"ALL TESTS PASSED"); $finish;
    end
endmodule
`default_nettype wire
