`timescale 1ns/1ps

module axis_async_fifo_adapter_smoke_tb;
    reg s_clk = 0, m_clk = 0;
    reg s_rst = 1, m_rst = 1;
    always #5 s_clk = ~s_clk;
    always #7 m_clk = ~m_clk;

    reg [63:0] s_data = 0;
    reg [7:0] s_keep = 0;
    reg s_valid = 0, s_last = 0;
    wire s_ready;

    wire [7:0] m_data;
    wire m_keep, m_valid, m_last;
    reg m_ready = 0;

    integer errors = 0;
    integer received = 0;

    axis_async_fifo_adapter #(
        .DEPTH(32),
        .S_DATA_WIDTH(64),
        .S_KEEP_ENABLE(1),
        .S_KEEP_WIDTH(8),
        .M_DATA_WIDTH(8),
        .M_KEEP_ENABLE(0),
        .M_KEEP_WIDTH(1),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .RAM_PIPELINE(1)
    ) dut (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(s_data),
        .s_axis_tkeep(s_keep),
        .s_axis_tvalid(s_valid),
        .s_axis_tready(s_ready),
        .s_axis_tlast(s_last),
        .s_axis_tid(8'b0),
        .s_axis_tdest(8'b0),
        .s_axis_tuser(1'b0),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(m_data),
        .m_axis_tkeep(m_keep),
        .m_axis_tvalid(m_valid),
        .m_axis_tready(m_ready),
        .m_axis_tlast(m_last),
        .m_axis_tid(),
        .m_axis_tdest(),
        .m_axis_tuser(),
        .s_pause_req(1'b0),
        .s_pause_ack(),
        .m_pause_req(1'b0),
        .m_pause_ack(),
        .s_status_depth(),
        .s_status_depth_commit(),
        .s_status_overflow(),
        .s_status_bad_frame(),
        .s_status_good_frame(),
        .m_status_depth(),
        .m_status_depth_commit(),
        .m_status_overflow(),
        .m_status_bad_frame(),
        .m_status_good_frame()
    );

    always @(posedge m_clk) begin
        if (!m_rst && m_valid && m_ready) begin
            if (m_data !== received[7:0]) begin
                $display("FAIL ADAPTER beat=%0d actual=%h expected=%h",
                    received, m_data, received[7:0]);
                errors = errors + 1;
            end
            if (m_last !== (received == 7)) begin
                $display("FAIL ADAPTER TLAST beat=%0d actual=%b",
                    received, m_last);
                errors = errors + 1;
            end
            received = received + 1;
        end
    end

    initial begin
        repeat (5) @(posedge s_clk);
        s_rst = 0;
        repeat (5) @(posedge m_clk);
        m_rst = 0;
        m_ready = 1;

        @(negedge s_clk);
        s_data = 64'h0706050403020100;
        s_keep = 8'hff;
        s_last = 1;
        s_valid = 1;
        @(posedge s_clk);
        while (!s_ready) @(posedge s_clk);
        @(negedge s_clk);
        s_valid = 0;
        s_last = 0;

        wait (received == 8);
        repeat (3) @(posedge m_clk);
        if (errors == 0)
            $display("AXIS ASYNC FIFO ADAPTER: ALL TESTS PASSED");
        else
            $display("AXIS ASYNC FIFO ADAPTER: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #10000;
        $display("AXIS ASYNC FIFO ADAPTER: TIMEOUT");
        $finish;
    end
endmodule
