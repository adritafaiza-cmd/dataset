`timescale 1ns/1ps

module axil_cdc_tb;
    integer errors = 0;

    reg s_clk = 0, m_clk = 0, s_rst = 1, m_rst = 1;
    always #5 s_clk = ~s_clk;
    always #8 m_clk = ~m_clk;

    reg [7:0] s_awaddr = 0, s_araddr = 0;
    reg [31:0] s_wdata = 0;
    reg s_awvalid = 0, s_wvalid = 0, s_bready = 0, s_arvalid = 0, s_rready = 0;
    wire s_awready, s_wready, s_bvalid, s_arready, s_rvalid;
    wire [1:0] s_bresp, s_rresp;
    wire [31:0] s_rdata;

    wire [7:0] m_awaddr, m_araddr;
    wire [31:0] m_wdata, m_rdata;
    wire [3:0] m_wstrb;
    wire [2:0] m_awprot, m_arprot;
    wire m_awvalid, m_awready, m_wvalid, m_wready, m_bvalid, m_bready;
    wire m_arvalid, m_arready, m_rvalid, m_rready;
    wire [1:0] m_bresp, m_rresp;

    reg [31:0] mem [0:15];
    integer i;
    initial for (i = 0; i < 16; i = i + 1) mem[i] = 32'h0;

    assign m_awready = 1'b1;
    assign m_wready = 1'b1;
    assign m_arready = 1'b1;
    assign m_bresp = 2'b00;
    assign m_rresp = 2'b00;
    assign m_rdata = mem[m_araddr[5:2]];

    reg b_pend = 0, r_pend = 0;
    always @(posedge m_clk) begin
        if (m_rst) begin
            b_pend <= 1'b0;
            r_pend <= 1'b0;
        end else begin
            if (m_awvalid && m_wvalid && m_awready && m_wready)
                mem[m_awaddr[5:2]] <= m_wdata;
            if (m_awvalid && m_wvalid && m_awready && m_wready)
                b_pend <= 1'b1;
            else if (m_bvalid && m_bready)
                b_pend <= 1'b0;
            if (m_arvalid && m_arready)
                r_pend <= 1'b1;
            else if (m_rvalid && m_rready)
                r_pend <= 1'b0;
        end
    end
    assign m_bvalid = b_pend;
    assign m_rvalid = r_pend;

    axil_cdc #(.DATA_WIDTH(32), .ADDR_WIDTH(8)) dut (
        .s_clk(s_clk), .s_rst(s_rst),
        .s_axil_awaddr(s_awaddr), .s_axil_awprot(3'b000),
        .s_axil_awvalid(s_awvalid), .s_axil_awready(s_awready),
        .s_axil_wdata(s_wdata), .s_axil_wstrb(4'hF),
        .s_axil_wvalid(s_wvalid), .s_axil_wready(s_wready),
        .s_axil_bresp(s_bresp), .s_axil_bvalid(s_bvalid), .s_axil_bready(s_bready),
        .s_axil_araddr(s_araddr), .s_axil_arprot(3'b000),
        .s_axil_arvalid(s_arvalid), .s_axil_arready(s_arready),
        .s_axil_rdata(s_rdata), .s_axil_rresp(s_rresp),
        .s_axil_rvalid(s_rvalid), .s_axil_rready(s_rready),
        .m_clk(m_clk), .m_rst(m_rst),
        .m_axil_awaddr(m_awaddr), .m_axil_awprot(m_awprot),
        .m_axil_awvalid(m_awvalid), .m_axil_awready(m_awready),
        .m_axil_wdata(m_wdata), .m_axil_wstrb(m_wstrb),
        .m_axil_wvalid(m_wvalid), .m_axil_wready(m_wready),
        .m_axil_bresp(m_bresp), .m_axil_bvalid(m_bvalid), .m_axil_bready(m_bready),
        .m_axil_araddr(m_araddr), .m_axil_arprot(m_arprot),
        .m_axil_arvalid(m_arvalid), .m_axil_arready(m_arready),
        .m_axil_rdata(m_rdata), .m_axil_rresp(m_rresp),
        .m_axil_rvalid(m_rvalid), .m_axil_rready(m_rready)
    );

    initial begin
        repeat (4) @(posedge s_clk); s_rst = 0;
        repeat (4) @(posedge m_clk); m_rst = 0;
        repeat (4) @(posedge s_clk);

        @(negedge s_clk);
        s_awaddr = 8'h08; s_wdata = 32'hDEAD_BEEF;
        s_awvalid = 1; s_wvalid = 1; s_bready = 1;
        while (!(s_awready && s_wready)) @(negedge s_clk);
        @(negedge s_clk);
        s_awvalid = 0; s_wvalid = 0;
        while (!s_bvalid) @(negedge s_clk);
        @(negedge s_clk);
        s_bready = 0;

        @(negedge s_clk);
        s_araddr = 8'h08; s_arvalid = 1; s_rready = 1;
        while (!s_arready) @(negedge s_clk);
        @(negedge s_clk);
        s_arvalid = 0;
        while (!s_rvalid) @(negedge s_clk);
        if (s_rdata !== 32'hDEAD_BEEF) begin
            $display("FAIL AXIL CDC readback %h", s_rdata);
            errors = errors + 1;
        end
        @(negedge s_clk);
        s_rready = 0;

        if (errors == 0)
            $display("AXIL CDC: ALL TESTS PASSED");
        else
            $display("AXIL CDC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #80000;
        $display("AXIL CDC: TIMEOUT");
        $finish;
    end
endmodule
