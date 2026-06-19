`timescale 1ns/1ps
`default_nettype none
module axilsafety_tb;
    localparam AW=8, DW=32;
    reg clk=0, rstn=0; always #5 clk=~clk;
    integer errors=0;
    wire wfault, rfault, m_rstn;
    reg s_awvalid; wire s_awready; reg [AW-1:0] s_awaddr; reg [2:0] s_awprot;
    reg s_wvalid; wire s_wready; reg [DW-1:0] s_wdata; reg [DW/8-1:0] s_wstrb;
    wire s_bvalid; reg s_bready; wire [1:0] s_bresp;
    reg s_arvalid; wire s_arready; reg [AW-1:0] s_araddr; reg [2:0] s_arprot;
    wire s_rvalid; reg s_rready; wire [DW-1:0] s_rdata; wire [1:0] s_rresp;
    wire m_awvalid; reg m_awready; wire [AW-1:0] m_awaddr; wire [2:0] m_awprot;
    wire m_wvalid; reg m_wready; wire [DW-1:0] m_wdata; wire [DW/8-1:0] m_wstrb;
    reg m_bvalid; wire m_bready; reg [1:0] m_bresp;
    wire m_arvalid; reg m_arready; wire [AW-1:0] m_araddr; wire [2:0] m_arprot;
    reg m_rvalid; wire m_rready; reg [DW-1:0] m_rdata; reg [1:0] m_rresp;

    axilsafety #(.C_AXI_ADDR_WIDTH(AW),.C_AXI_DATA_WIDTH(DW),.OPT_TIMEOUT(8),.OPT_SELF_RESET(1'b1)) dut(
        .o_write_fault(wfault),.o_read_fault(rfault),.S_AXI_ACLK(clk),.S_AXI_ARESETN(rstn),.M_AXI_ARESETN(m_rstn),
        .S_AXI_AWVALID(s_awvalid),.S_AXI_AWREADY(s_awready),.S_AXI_AWADDR(s_awaddr),.S_AXI_AWPROT(s_awprot),
        .S_AXI_WVALID(s_wvalid),.S_AXI_WREADY(s_wready),.S_AXI_WDATA(s_wdata),.S_AXI_WSTRB(s_wstrb),
        .S_AXI_BVALID(s_bvalid),.S_AXI_BREADY(s_bready),.S_AXI_BRESP(s_bresp),
        .S_AXI_ARVALID(s_arvalid),.S_AXI_ARREADY(s_arready),.S_AXI_ARADDR(s_araddr),.S_AXI_ARPROT(s_arprot),
        .S_AXI_RVALID(s_rvalid),.S_AXI_RREADY(s_rready),.S_AXI_RDATA(s_rdata),.S_AXI_RRESP(s_rresp),
        .M_AXI_AWVALID(m_awvalid),.M_AXI_AWREADY(m_awready),.M_AXI_AWADDR(m_awaddr),.M_AXI_AWPROT(m_awprot),
        .M_AXI_WVALID(m_wvalid),.M_AXI_WREADY(m_wready),.M_AXI_WDATA(m_wdata),.M_AXI_WSTRB(m_wstrb),
        .M_AXI_BVALID(m_bvalid),.M_AXI_BREADY(m_bready),.M_AXI_BRESP(m_bresp),
        .M_AXI_ARVALID(m_arvalid),.M_AXI_ARREADY(m_arready),.M_AXI_ARADDR(m_araddr),.M_AXI_ARPROT(m_arprot),
        .M_AXI_RVALID(m_rvalid),.M_AXI_RREADY(m_rready),.M_AXI_RDATA(m_rdata),.M_AXI_RRESP(m_rresp));

    task check; input cond; input [255:0] msg; begin if(!cond) begin $display("FAIL: %s",msg); errors=errors+1; end else $display("PASS: %s",msg); end endtask
    task good_write; begin
        @(negedge clk); s_awaddr=8'h10; s_awvalid=1; s_wdata=32'hA5A55A5A; s_wstrb=4'hf; s_wvalid=1; s_bready=1;
        fork begin wait(m_awvalid); m_awready=1; @(negedge clk); m_awready=0; end begin wait(m_wvalid); m_wready=1; @(negedge clk); m_wready=0; end join
        @(negedge clk); s_awvalid=0; s_wvalid=0; m_bresp=0; m_bvalid=1; wait(m_bready); @(negedge clk); m_bvalid=0;
        wait(s_bvalid); check(s_bresp==2'b00,"good AXIL write returns OKAY"); @(negedge clk); s_bready=0;
    end endtask
    task good_read; begin
        @(negedge clk); s_araddr=8'h20; s_arvalid=1; s_rready=1; wait(m_arvalid); m_arready=1; @(negedge clk); m_arready=0; s_arvalid=0;
        m_rdata=32'h12345678; m_rresp=0; m_rvalid=1; wait(m_rready); @(negedge clk); m_rvalid=0;
        wait(s_rvalid); check(s_rdata==32'h12345678 && s_rresp==0,"good AXIL read returns data"); @(negedge clk); s_rready=0;
    end endtask
    initial begin
        s_awvalid=0; s_awaddr=0; s_awprot=0; s_wvalid=0; s_wdata=0; s_wstrb=0; s_bready=0; s_arvalid=0; s_araddr=0; s_arprot=0; s_rready=0;
        m_awready=0; m_wready=0; m_bvalid=0; m_bresp=0; m_arready=0; m_rvalid=0; m_rdata=0; m_rresp=0;
        repeat(5) @(posedge clk); rstn=1; repeat(5) @(posedge clk);
        $display("TEST AXILSAFETY"); good_write; good_read;
        @(negedge clk); s_awaddr=8'h30; s_awvalid=1; s_wdata=32'h1; s_wstrb=4'hf; s_wvalid=1; s_bready=1; // downstream never ready => timeout
        repeat(25) @(posedge clk); check(wfault,"write fault asserted on timeout");
        $display(errors?"TESTS FAILED":"ALL TESTS PASSED"); $finish;
    end
endmodule
`default_nettype wire
