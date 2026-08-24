`timescale 1ns/1ps

module axi_dma_tb;
    integer errors = 0;

    reg clk = 0, rst = 1;
    wire read_ready, write_ready;
    always #5 clk = ~clk;

    axi_dma #(
        .AXI_DATA_WIDTH(32), .AXI_ADDR_WIDTH(16), .AXI_ID_WIDTH(8),
        .AXIS_DATA_WIDTH(32), .ENABLE_SG(0), .ENABLE_UNALIGNED(0)
    ) dut (
        .clk(clk), .rst(rst),
        .s_axis_read_desc_addr(16'h0), .s_axis_read_desc_len(20'd4),
        .s_axis_read_desc_tag(8'h0), .s_axis_read_desc_id(8'h0),
        .s_axis_read_desc_dest(8'h0), .s_axis_read_desc_user(1'b0),
        .s_axis_read_desc_valid(1'b0), .s_axis_read_desc_ready(read_ready),
        .m_axis_read_desc_status_tag(), .m_axis_read_desc_status_error(),
        .m_axis_read_desc_status_valid(),
        .m_axis_read_data_tdata(), .m_axis_read_data_tkeep(),
        .m_axis_read_data_tvalid(), .m_axis_read_data_tready(1'b1),
        .m_axis_read_data_tlast(), .m_axis_read_data_tid(),
        .m_axis_read_data_tdest(), .m_axis_read_data_tuser(),
        .s_axis_write_desc_addr(16'h0), .s_axis_write_desc_len(20'd4),
        .s_axis_write_desc_tag(8'h0), .s_axis_write_desc_valid(1'b0),
        .s_axis_write_desc_ready(write_ready),
        .m_axis_write_desc_status_len(), .m_axis_write_desc_status_tag(),
        .m_axis_write_desc_status_id(), .m_axis_write_desc_status_dest(),
        .m_axis_write_desc_status_user(), .m_axis_write_desc_status_error(),
        .m_axis_write_desc_status_valid(),
        .s_axis_write_data_tdata(32'h0), .s_axis_write_data_tkeep(4'hF),
        .s_axis_write_data_tvalid(1'b0), .s_axis_write_data_tready(),
        .s_axis_write_data_tlast(1'b0), .s_axis_write_data_tid(8'h0),
        .s_axis_write_data_tdest(8'h0), .s_axis_write_data_tuser(1'b0),
        .m_axi_awid(), .m_axi_awaddr(), .m_axi_awlen(), .m_axi_awsize(),
        .m_axi_awburst(), .m_axi_awlock(), .m_axi_awcache(), .m_axi_awprot(),
        .m_axi_awvalid(), .m_axi_awready(1'b1), .m_axi_wdata(), .m_axi_wstrb(),
        .m_axi_wlast(), .m_axi_wvalid(), .m_axi_wready(1'b1),
        .m_axi_bid(8'h0), .m_axi_bresp(2'b00), .m_axi_bvalid(1'b0),
        .m_axi_bready(),
        .m_axi_arid(), .m_axi_araddr(), .m_axi_arlen(), .m_axi_arsize(),
        .m_axi_arburst(), .m_axi_arlock(), .m_axi_arcache(), .m_axi_arprot(),
        .m_axi_arvalid(), .m_axi_arready(1'b1),
        .m_axi_rid(8'h0), .m_axi_rdata(32'h0), .m_axi_rresp(2'b00),
        .m_axi_rlast(1'b1), .m_axi_rvalid(1'b0), .m_axi_rready(),
        .read_enable(1'b1), .write_enable(1'b1), .write_abort(1'b0)
    );

    initial begin
        repeat (4) @(posedge clk); rst = 0;
        repeat (8) @(posedge clk);
        if (read_ready !== 1'b1 || write_ready !== 1'b1) begin
            $display("FAIL DMA not ready after reset");
            errors = errors + 1;
        end
        if (errors == 0) $display("AXI DMA: ALL TESTS PASSED");
        else $display("AXI DMA: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #20000;
        $display("AXI_DMA_TB: TIMEOUT");
        $finish;
    end
endmodule
