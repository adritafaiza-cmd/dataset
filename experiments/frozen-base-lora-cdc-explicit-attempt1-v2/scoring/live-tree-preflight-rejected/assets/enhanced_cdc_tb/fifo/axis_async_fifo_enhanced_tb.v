`timescale 1ns/1ps

module axis_async_fifo_enhanced_tb;
    parameter COUNT = 64;

    reg s_clk, m_clk, s_rst, m_rst;
    reg [7:0] s_data;
    reg s_valid, s_last, m_ready;
    wire s_ready, m_valid, m_last;
    wire [7:0] m_data;
    reg [7:0] expected_data [0:COUNT-1];
    reg expected_last [0:COUNT-1];
    reg prev_stalled, score_enable;
    reg [7:0] prev_data;
    reg prev_last;
    integer errors, sent, received, i;

    axis_async_fifo #(
        .DEPTH(16), .DATA_WIDTH(8), .KEEP_ENABLE(0), .LAST_ENABLE(1),
        .ID_ENABLE(0), .DEST_ENABLE(0), .USER_ENABLE(0), .RAM_PIPELINE(1)
    ) dut (
        .s_clk(s_clk), .s_rst(s_rst), .s_axis_tdata(s_data),
        .s_axis_tkeep(1'b1), .s_axis_tvalid(s_valid),
        .s_axis_tready(s_ready), .s_axis_tlast(s_last),
        .s_axis_tid(8'b0), .s_axis_tdest(8'b0), .s_axis_tuser(1'b0),
        .m_clk(m_clk), .m_rst(m_rst), .m_axis_tdata(m_data),
        .m_axis_tkeep(), .m_axis_tvalid(m_valid),
        .m_axis_tready(m_ready), .m_axis_tlast(m_last),
        .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser(),
        .s_pause_req(1'b0), .s_pause_ack(),
        .m_pause_req(1'b0), .m_pause_ack(),
        .s_status_depth(), .s_status_depth_commit(),
        .s_status_overflow(), .s_status_bad_frame(),
        .s_status_good_frame(), .m_status_depth(),
        .m_status_depth_commit(), .m_status_overflow(),
        .m_status_bad_frame(), .m_status_good_frame()
    );

    always #5 s_clk = ~s_clk;
    always #8 m_clk = ~m_clk;

    task cdc_fail;
        input [8*80-1:0] rule_id;
        input [8*80-1:0] details;
        begin
            $display("CDC/RESET VIOLATION [%0s]: %0s at %0t",
                     rule_id, details, $time);
            errors = errors + 1;
        end
    endtask

    task protocol_fail;
        input [8*80-1:0] rule_id;
        input [8*80-1:0] details;
        begin
            $display("PROTOCOL VIOLATION [%0s]: %0s at %0t",
                     rule_id, details, $time);
            errors = errors + 1;
        end
    endtask

    task send_beat;
        input [7:0] value;
        input last_value;
        integer n;
        begin
            @(negedge s_clk);
            s_data = value;
            s_last = last_value;
            s_valid = 1;
            n = 0;
            #1;
            while (!s_ready && n < 160) begin
                n = n + 1;
                @(negedge s_clk);
                #1;
            end
            if (n == 160)
                cdc_fail("FIFO_HANDSHAKE_TIMEOUT", "source handshake TIMEOUT");
            else begin
                @(posedge s_clk);
                if (score_enable)
                    sent = sent + 1;
            end
            @(negedge s_clk);
            s_valid = 0;
            s_last = 0;
        end
    endtask

    task reset_midtraffic;
        begin
            @(negedge s_clk);
            s_valid = 0;
            s_rst = 1;
            repeat (2) @(negedge m_clk);
            m_ready = 0;
            m_rst = 1;
            repeat (4) @(posedge m_clk);
            m_rst = 0;
            repeat (3) @(posedge s_clk);
            s_rst = 0;
            repeat (8) @(posedge m_clk);
        end
    endtask

    always @(posedge s_clk) begin
        if (!s_rst) begin
            if ((^s_ready) === 1'bx)
                cdc_fail("FIFO_X_STATUS", "source ready is unknown");
            if (s_valid && ((^s_data) === 1'bx || (^s_last) === 1'bx))
                protocol_fail("FIFO_X_INPUT", "source payload contains unknown bits");
        end
    end

    always @(posedge m_clk) begin
        if (m_rst) begin
            #1;
            if (m_valid !== 1'b0)
                cdc_fail("FIFO_RESET_SAFETY", "destination valid remained asserted during reset");
            prev_stalled <= 0;
        end else begin
            if ((^m_valid) === 1'bx)
                cdc_fail("FIFO_X_STATUS", "destination valid is unknown");
            if (prev_stalled &&
                (!m_valid || m_data !== prev_data || m_last !== prev_last))
                cdc_fail("FIFO_BACKPRESSURE_STABILITY", "output changed while stalled");
            if (m_valid && ((^m_data) === 1'bx || (^m_last) === 1'bx))
                cdc_fail("FIFO_X_OUTPUT", "destination payload contains unknown bits");
            if (score_enable && m_valid && m_ready) begin
                if (received >= sent)
                    cdc_fail("FIFO_COHERENCY", "output observed without a corresponding accepted input");
                if (m_data !== expected_data[received] ||
                    m_last !== expected_last[received]) begin
                    $display("CDC/RESET VIOLATION [FIFO_DATA_ORDER]: index=%0d got_data=%h expected_data=%h got_last=%b expected_last=%b",
                             received, m_data, expected_data[received],
                             m_last, expected_last[received]);
                    errors = errors + 1;
                end
                received = received + 1;
            end
            prev_stalled <= m_valid && !m_ready;
            prev_data <= m_data;
            prev_last <= m_last;
        end
    end

    initial begin
        s_clk = 0; m_clk = 0; s_rst = 1; m_rst = 1;
        s_data = 0; s_valid = 0; s_last = 0; m_ready = 0;
        prev_stalled = 0; prev_data = 0; prev_last = 0;
        score_enable = 0; errors = 0; sent = 0; received = 0;

        repeat (5) @(posedge s_clk); s_rst = 0;
        repeat (4) @(posedge m_clk); m_rst = 0;
        repeat (5) @(posedge m_clk);
        for (i = 0; i < 6; i = i + 1)
            send_beat(8'he0 + i, i == 5);
        reset_midtraffic;

        sent = 0;
        received = 0;
        score_enable = 1;
        for (i = 0; i < COUNT; i = i + 1) begin
            expected_data[i] = 8'h29 ^ (i * 8'h37);
            expected_last[i] = ((i % 11) == 10) || (i == COUNT-1);
        end

        fork
            begin
                for (i = 0; i < COUNT; i = i + 1)
                    send_beat(expected_data[i], expected_last[i]);
            end
            begin
                repeat (5) @(posedge m_clk);
                while (received < COUNT) begin
                    @(negedge m_clk);
                    if ((received % 8) == 3) begin
                        m_ready = 0;
                        repeat (4) @(negedge m_clk);
                        /*
                         * Re-enable ready before re-testing received.  The
                         * count cannot advance while ready is low.
                         */
                        m_ready = 1;
                    end else
                        m_ready = 1;
                end
                m_ready = 0;
            end
        join

        if (sent != COUNT || received != COUNT)
            cdc_fail("FIFO_COHERENCY", "accepted and delivered transaction counts differ");
        if (errors == 0)
            $display("AXIS ASYNC FIFO ENHANCED: ALL TESTS PASSED");
        else
            $display("AXIS ASYNC FIFO ENHANCED: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #350000;
        $display("FIFO TEST TIMEOUT: axis_async_fifo global watchdog expired");
        $finish;
    end
endmodule
