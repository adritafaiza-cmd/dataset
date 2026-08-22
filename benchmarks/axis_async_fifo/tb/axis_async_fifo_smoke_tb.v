`timescale 1ns/1ps

module axis_async_fifo_smoke_tb;
    localparam DEPTH = 16;

    reg s_clk = 0, m_clk = 0;
    reg s_rst = 1, m_rst = 1;
    always #5 s_clk = ~s_clk;
    always #7 m_clk = ~m_clk;

    reg [7:0] s_data = 0;
    reg s_valid = 0, s_last = 0;
    wire s_ready;

    wire [7:0] m_data;
    wire m_valid, m_last;
    reg m_ready = 0;

    integer errors = 0;
    integer received = 0;

    axis_async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(8),
        .KEEP_ENABLE(0),
        .LAST_ENABLE(1),
        .ID_ENABLE(0),
        .DEST_ENABLE(0),
        .USER_ENABLE(0),
        .RAM_PIPELINE(1)
    ) dut (
        .s_clk(s_clk),
        .s_rst(s_rst),
        .s_axis_tdata(s_data),
        .s_axis_tkeep(1'b1),
        .s_axis_tvalid(s_valid),
        .s_axis_tready(s_ready),
        .s_axis_tlast(s_last),
        .s_axis_tid(8'b0),
        .s_axis_tdest(8'b0),
        .s_axis_tuser(1'b0),
        .m_clk(m_clk),
        .m_rst(m_rst),
        .m_axis_tdata(m_data),
        .m_axis_tkeep(),
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

    task send_byte;
        input [7:0] value;
        input is_last;
        begin
            @(negedge s_clk);
            s_data = value;
            s_last = is_last;
            s_valid = 1;
            @(posedge s_clk);
            while (!s_ready) @(posedge s_clk);
            @(negedge s_clk);
            s_valid = 0;
            s_last = 0;
        end
    endtask

    always @(posedge m_clk) begin
        if (!m_rst && m_valid && m_ready) begin
            if (m_data !== received[7:0]) begin
                $display("FAIL FIFO beat=%0d actual=%h expected=%h",
                    received, m_data, received[7:0]);
                errors = errors + 1;
            end
            if (m_last !== (received == 7)) begin
                $display("FAIL FIFO TLAST beat=%0d actual=%b",
                    received, m_last);
                errors = errors + 1;
            end
            received = received + 1;
        end
    end

    integer i;
    initial begin
        repeat (5) @(posedge s_clk);
        s_rst = 0;
        repeat (5) @(posedge m_clk);
        m_rst = 0;
        m_ready = 1;

        for (i = 0; i < 8; i = i + 1)
            send_byte(i[7:0], i == 7);

        wait (received == 8);
        repeat (3) @(posedge m_clk);
        if (errors == 0)
            $display("AXIS ASYNC FIFO: ALL TESTS PASSED");
        else
            $display("AXIS ASYNC FIFO: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #10000;
        $display("AXIS ASYNC FIFO: TIMEOUT");
        $finish;
    end
endmodule
