`timescale 1ns/1ps

module axidma_tb;
    integer errors = 0;

    reg clk = 0, rstn = 0;
    wire awready, wready, arready;
    always #5 clk = ~clk;

    axidma #(
        .C_AXI_ID_WIDTH(1), .C_AXI_ADDR_WIDTH(32), .C_AXI_DATA_WIDTH(32),
        .OPT_UNALIGNED(1'b0)
    ) dut (
        .S_AXI_ACLK(clk), .S_AXI_ARESETN(rstn),
        .S_AXIL_AWVALID(1'b0), .S_AXIL_AWREADY(awready),
        .S_AXIL_AWADDR(5'h0), .S_AXIL_AWPROT(3'b0),
        .S_AXIL_WVALID(1'b0), .S_AXIL_WREADY(wready),
        .S_AXIL_WDATA(32'h0), .S_AXIL_WSTRB(4'h0),
        .S_AXIL_BVALID(), .S_AXIL_BREADY(1'b1), .S_AXIL_BRESP(),
        .S_AXIL_ARVALID(1'b0), .S_AXIL_ARREADY(arready),
        .S_AXIL_ARADDR(5'h0), .S_AXIL_ARPROT(3'b0),
        .S_AXIL_RVALID(), .S_AXIL_RREADY(1'b1),
        .S_AXIL_RDATA(), .S_AXIL_RRESP(),
        .M_AXI_AWVALID(), .M_AXI_AWREADY(1'b1), .M_AXI_AWID(),
        .M_AXI_AWADDR(), .M_AXI_AWLEN(), .M_AXI_AWSIZE(),
        .M_AXI_AWBURST(), .M_AXI_AWLOCK(), .M_AXI_AWCACHE(),
        .M_AXI_AWPROT(), .M_AXI_AWQOS(),
        .M_AXI_WVALID(), .M_AXI_WREADY(1'b1), .M_AXI_WDATA(),
        .M_AXI_WSTRB(), .M_AXI_WLAST(),
        .M_AXI_BVALID(1'b0), .M_AXI_BREADY(), .M_AXI_BID(1'b0),
        .M_AXI_BRESP(2'b00),
        .M_AXI_ARVALID(), .M_AXI_ARREADY(1'b1), .M_AXI_ARID(),
        .M_AXI_ARADDR(), .M_AXI_ARLEN(), .M_AXI_ARSIZE(),
        .M_AXI_ARBURST(), .M_AXI_ARLOCK(), .M_AXI_ARCACHE(),
        .M_AXI_ARPROT(), .M_AXI_ARQOS(),
        .M_AXI_RVALID(1'b0), .M_AXI_RREADY(), .M_AXI_RID(1'b0),
        .M_AXI_RDATA(32'h0), .M_AXI_RRESP(2'b00), .M_AXI_RLAST(1'b1),
        .o_int()
    );

    initial begin
        repeat (4) @(posedge clk); rstn = 1;
        repeat (8) @(posedge clk);
        if (awready !== 1'b1) begin
            $display("FAIL AXI-lite not ready");
            errors = errors + 1;
        end
        if (errors == 0) $display("AXIDMA: ALL TESTS PASSED");
        else $display("AXIDMA: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("AXIDMA_TB: TIMEOUT");
        $finish;
    end
endmodule
