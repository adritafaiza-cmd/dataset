`timescale 1ns/1ps

module axixclk_tb;
    localparam IDW = 2;
    localparam DW  = 32;
    localparam AW  = 8;

    reg s_clk = 0, m_clk = 0;
    reg s_rstn = 0;
    always #5 s_clk = ~s_clk;
    always #7 m_clk = ~m_clk;

    reg [IDW-1:0] S_AXI_AWID; reg [AW-1:0] S_AXI_AWADDR; reg [7:0] S_AXI_AWLEN; reg [2:0] S_AXI_AWSIZE; reg [1:0] S_AXI_AWBURST;
    reg S_AXI_AWLOCK; reg [3:0] S_AXI_AWCACHE; reg [2:0] S_AXI_AWPROT; reg [3:0] S_AXI_AWQOS; reg S_AXI_AWVALID; wire S_AXI_AWREADY;
    reg [DW-1:0] S_AXI_WDATA; reg [DW/8-1:0] S_AXI_WSTRB; reg S_AXI_WLAST; reg S_AXI_WVALID; wire S_AXI_WREADY;
    wire [IDW-1:0] S_AXI_BID; wire [1:0] S_AXI_BRESP; wire S_AXI_BVALID; reg S_AXI_BREADY;
    reg [IDW-1:0] S_AXI_ARID; reg [AW-1:0] S_AXI_ARADDR; reg [7:0] S_AXI_ARLEN; reg [2:0] S_AXI_ARSIZE; reg [1:0] S_AXI_ARBURST;
    reg S_AXI_ARLOCK; reg [3:0] S_AXI_ARCACHE; reg [2:0] S_AXI_ARPROT; reg [3:0] S_AXI_ARQOS; reg S_AXI_ARVALID; wire S_AXI_ARREADY;
    wire [IDW-1:0] S_AXI_RID; wire [DW-1:0] S_AXI_RDATA; wire [1:0] S_AXI_RRESP; wire S_AXI_RLAST; wire S_AXI_RVALID; reg S_AXI_RREADY;

    wire M_AXI_ARESETN;
    wire [IDW-1:0] M_AXI_AWID; wire [AW-1:0] M_AXI_AWADDR; wire [7:0] M_AXI_AWLEN; wire [2:0] M_AXI_AWSIZE; wire [1:0] M_AXI_AWBURST;
    wire M_AXI_AWLOCK; wire [3:0] M_AXI_AWCACHE; wire [2:0] M_AXI_AWPROT; wire [3:0] M_AXI_AWQOS; wire M_AXI_AWVALID; reg M_AXI_AWREADY;
    wire [DW-1:0] M_AXI_WDATA; wire [DW/8-1:0] M_AXI_WSTRB; wire M_AXI_WLAST; wire M_AXI_WVALID; reg M_AXI_WREADY;
    reg [IDW-1:0] M_AXI_BID; reg [1:0] M_AXI_BRESP; reg M_AXI_BVALID; wire M_AXI_BREADY;
    wire [IDW-1:0] M_AXI_ARID; wire [AW-1:0] M_AXI_ARADDR; wire [7:0] M_AXI_ARLEN; wire [2:0] M_AXI_ARSIZE; wire [1:0] M_AXI_ARBURST;
    wire M_AXI_ARLOCK; wire [3:0] M_AXI_ARCACHE; wire [2:0] M_AXI_ARPROT; wire [3:0] M_AXI_ARQOS; wire M_AXI_ARVALID; reg M_AXI_ARREADY;
    reg [IDW-1:0] M_AXI_RID; reg [DW-1:0] M_AXI_RDATA; reg [1:0] M_AXI_RRESP; reg M_AXI_RLAST; reg M_AXI_RVALID; wire M_AXI_RREADY;

    integer errors, i;
    reg [31:0] mem [0:63];
    reg [AW-1:0] awaddr_hold, araddr_hold;
    reg [7:0] awlen_hold, arlen_hold;
    reg [IDW-1:0] awid_hold, arid_hold;
    integer wbeat, rbeat;
    reg sending_r;

    axixclk #(.C_S_AXI_ID_WIDTH(IDW), .C_S_AXI_DATA_WIDTH(DW), .C_S_AXI_ADDR_WIDTH(AW), .LGFIFO(4)) dut (
        .S_AXI_ACLK(s_clk), .S_AXI_ARESETN(s_rstn),
        .S_AXI_AWID(S_AXI_AWID), .S_AXI_AWADDR(S_AXI_AWADDR), .S_AXI_AWLEN(S_AXI_AWLEN), .S_AXI_AWSIZE(S_AXI_AWSIZE), .S_AXI_AWBURST(S_AXI_AWBURST), .S_AXI_AWLOCK(S_AXI_AWLOCK), .S_AXI_AWCACHE(S_AXI_AWCACHE), .S_AXI_AWPROT(S_AXI_AWPROT), .S_AXI_AWQOS(S_AXI_AWQOS), .S_AXI_AWVALID(S_AXI_AWVALID), .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA), .S_AXI_WSTRB(S_AXI_WSTRB), .S_AXI_WLAST(S_AXI_WLAST), .S_AXI_WVALID(S_AXI_WVALID), .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BID(S_AXI_BID), .S_AXI_BRESP(S_AXI_BRESP), .S_AXI_BVALID(S_AXI_BVALID), .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARID(S_AXI_ARID), .S_AXI_ARADDR(S_AXI_ARADDR), .S_AXI_ARLEN(S_AXI_ARLEN), .S_AXI_ARSIZE(S_AXI_ARSIZE), .S_AXI_ARBURST(S_AXI_ARBURST), .S_AXI_ARLOCK(S_AXI_ARLOCK), .S_AXI_ARCACHE(S_AXI_ARCACHE), .S_AXI_ARPROT(S_AXI_ARPROT), .S_AXI_ARQOS(S_AXI_ARQOS), .S_AXI_ARVALID(S_AXI_ARVALID), .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RID(S_AXI_RID), .S_AXI_RDATA(S_AXI_RDATA), .S_AXI_RRESP(S_AXI_RRESP), .S_AXI_RLAST(S_AXI_RLAST), .S_AXI_RVALID(S_AXI_RVALID), .S_AXI_RREADY(S_AXI_RREADY),
        .M_AXI_ACLK(m_clk), .M_AXI_ARESETN(M_AXI_ARESETN),
        .M_AXI_AWID(M_AXI_AWID), .M_AXI_AWADDR(M_AXI_AWADDR), .M_AXI_AWLEN(M_AXI_AWLEN), .M_AXI_AWSIZE(M_AXI_AWSIZE), .M_AXI_AWBURST(M_AXI_AWBURST), .M_AXI_AWLOCK(M_AXI_AWLOCK), .M_AXI_AWCACHE(M_AXI_AWCACHE), .M_AXI_AWPROT(M_AXI_AWPROT), .M_AXI_AWQOS(M_AXI_AWQOS), .M_AXI_AWVALID(M_AXI_AWVALID), .M_AXI_AWREADY(M_AXI_AWREADY),
        .M_AXI_WDATA(M_AXI_WDATA), .M_AXI_WSTRB(M_AXI_WSTRB), .M_AXI_WLAST(M_AXI_WLAST), .M_AXI_WVALID(M_AXI_WVALID), .M_AXI_WREADY(M_AXI_WREADY),
        .M_AXI_BID(M_AXI_BID), .M_AXI_BRESP(M_AXI_BRESP), .M_AXI_BVALID(M_AXI_BVALID), .M_AXI_BREADY(M_AXI_BREADY),
        .M_AXI_ARID(M_AXI_ARID), .M_AXI_ARADDR(M_AXI_ARADDR), .M_AXI_ARLEN(M_AXI_ARLEN), .M_AXI_ARSIZE(M_AXI_ARSIZE), .M_AXI_ARBURST(M_AXI_ARBURST), .M_AXI_ARLOCK(M_AXI_ARLOCK), .M_AXI_ARCACHE(M_AXI_ARCACHE), .M_AXI_ARPROT(M_AXI_ARPROT), .M_AXI_ARQOS(M_AXI_ARQOS), .M_AXI_ARVALID(M_AXI_ARVALID), .M_AXI_ARREADY(M_AXI_ARREADY),
        .M_AXI_RID(M_AXI_RID), .M_AXI_RDATA(M_AXI_RDATA), .M_AXI_RRESP(M_AXI_RRESP), .M_AXI_RLAST(M_AXI_RLAST), .M_AXI_RVALID(M_AXI_RVALID), .M_AXI_RREADY(M_AXI_RREADY)
    );

    // Downstream AXI RAM model in M clock domain
    always @(posedge m_clk) begin
        if (!M_AXI_ARESETN) begin
            M_AXI_AWREADY<=0; M_AXI_WREADY<=0; M_AXI_BVALID<=0; M_AXI_BRESP<=0; M_AXI_BID<=0;
            M_AXI_ARREADY<=0; M_AXI_RVALID<=0; M_AXI_RDATA<=0; M_AXI_RRESP<=0; M_AXI_RLAST<=0; M_AXI_RID<=0;
            wbeat<=0; rbeat<=0; sending_r<=0;
        end else begin
            M_AXI_AWREADY<=1; M_AXI_WREADY<=1; M_AXI_ARREADY<=!sending_r;
            if (M_AXI_AWVALID && M_AXI_AWREADY) begin awaddr_hold<=M_AXI_AWADDR; awlen_hold<=M_AXI_AWLEN; awid_hold<=M_AXI_AWID; wbeat<=0; end
            if (M_AXI_WVALID && M_AXI_WREADY) begin
                mem[(awaddr_hold>>2)+wbeat] <= M_AXI_WDATA;
                wbeat <= wbeat + 1;
                if (M_AXI_WLAST) begin M_AXI_BVALID<=1; M_AXI_BRESP<=0; M_AXI_BID<=awid_hold; end
            end
            if (M_AXI_BVALID && M_AXI_BREADY) M_AXI_BVALID<=0;
            if (M_AXI_ARVALID && M_AXI_ARREADY) begin
                araddr_hold<=M_AXI_ARADDR; arlen_hold<=M_AXI_ARLEN; arid_hold<=M_AXI_ARID; rbeat<=0; sending_r<=1;
                M_AXI_RVALID<=1; M_AXI_RDATA<=mem[M_AXI_ARADDR>>2]; M_AXI_RLAST<=(M_AXI_ARLEN==0); M_AXI_RID<=M_AXI_ARID; M_AXI_RRESP<=0;
            end else if (M_AXI_RVALID && M_AXI_RREADY) begin
                if (M_AXI_RLAST) begin M_AXI_RVALID<=0; M_AXI_RLAST<=0; sending_r<=0; end
                else begin rbeat<=rbeat+1; M_AXI_RDATA<=mem[(araddr_hold>>2)+rbeat+1]; M_AXI_RLAST <= (rbeat+1 == arlen_hold); M_AXI_RID<=arid_hold; end
            end
        end
    end

    task s_axi_write_burst;
        input [AW-1:0] addr; input [7:0] len; input [31:0] base;
        integer n;
        begin
            @(negedge s_clk); S_AXI_AWID=1; S_AXI_AWADDR=addr; S_AXI_AWLEN=len; S_AXI_AWSIZE=3'b010; S_AXI_AWBURST=2'b01; S_AXI_AWVALID=1; S_AXI_BREADY=1;
            wait(S_AXI_AWREADY); @(negedge s_clk); S_AXI_AWVALID=0;
            for (n=0; n<=len; n=n+1) begin
                S_AXI_WDATA=base+n; S_AXI_WSTRB=4'hf; S_AXI_WLAST=(n==len); S_AXI_WVALID=1;
                wait(S_AXI_WREADY); @(negedge s_clk); S_AXI_WVALID=0; S_AXI_WLAST=0;
            end
            wait(S_AXI_BVALID); @(negedge s_clk); S_AXI_BREADY=0;
        end
    endtask

    task s_axi_read_burst_check;
        input [AW-1:0] addr; input [7:0] len; input [31:0] base;
        integer n;
        begin
            @(negedge s_clk); S_AXI_ARID=2; S_AXI_ARADDR=addr; S_AXI_ARLEN=len; S_AXI_ARSIZE=3'b010; S_AXI_ARBURST=2'b01; S_AXI_ARVALID=1; S_AXI_RREADY=1;
            wait(S_AXI_ARREADY); @(negedge s_clk); S_AXI_ARVALID=0;
            for (n=0; n<=len; n=n+1) begin
                wait(S_AXI_RVALID); if (S_AXI_RDATA !== base+n) begin $display("FAIL read addr=%h beat=%0d actual=%h expected=%h", addr,n,S_AXI_RDATA,base+n); errors=errors+1; end else $display("PASS read beat %0d data=%h", n, S_AXI_RDATA);
                if ((n==len) && !S_AXI_RLAST) begin $display("FAIL missing RLAST"); errors=errors+1; end
                @(negedge s_clk);
            end
            S_AXI_RREADY=0;
        end
    endtask

    initial begin
        errors=0; for (i=0; i<64; i=i+1) mem[i]=0;
        S_AXI_AWID=0; S_AXI_AWADDR=0; S_AXI_AWLEN=0; S_AXI_AWSIZE=3'b010; S_AXI_AWBURST=2'b01; S_AXI_AWLOCK=0; S_AXI_AWCACHE=0; S_AXI_AWPROT=0; S_AXI_AWQOS=0; S_AXI_AWVALID=0;
        S_AXI_WDATA=0; S_AXI_WSTRB=0; S_AXI_WLAST=0; S_AXI_WVALID=0; S_AXI_BREADY=0;
        S_AXI_ARID=0; S_AXI_ARADDR=0; S_AXI_ARLEN=0; S_AXI_ARSIZE=3'b010; S_AXI_ARBURST=2'b01; S_AXI_ARLOCK=0; S_AXI_ARCACHE=0; S_AXI_ARPROT=0; S_AXI_ARQOS=0; S_AXI_ARVALID=0; S_AXI_RREADY=0;
        repeat(6) @(posedge s_clk); s_rstn=1; repeat(20) @(posedge s_clk);
        $display("TEST AXIXCLK multiple bursts across clock domains");
        s_axi_write_burst(8'h10, 8'd3, 32'h1000_0000);
        s_axi_write_burst(8'h30, 8'd1, 32'h2000_0000);
        repeat(40) @(posedge s_clk);
        s_axi_read_burst_check(8'h10, 8'd3, 32'h1000_0000);
        s_axi_read_burst_check(8'h30, 8'd1, 32'h2000_0000);
        if (errors==0) $display("ALL TESTS PASSED"); else $display("TESTS FAILED: %0d errors", errors);
        $finish;
    end
endmodule
