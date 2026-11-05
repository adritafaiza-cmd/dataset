`timescale 1ns/1ps

module axis_fifo_tb;
    integer errors = 0;

    reg clk = 0, rst = 1;
    reg [7:0] s_data = 0;
    reg s_valid = 0, s_last = 0;
    wire s_ready;
    wire [7:0] m_data;
    wire m_valid, m_last;
    reg m_ready = 0;
    integer received = 0;
    always #5 clk = ~clk;

    axis_fifo #(.DEPTH(16),
        .DATA_WIDTH(8), .KEEP_ENABLE(0), .LAST_ENABLE(1),
        .ID_ENABLE(0), .DEST_ENABLE(0), .USER_ENABLE(0)
    ) dut (
        .clk(clk), .rst(rst),
        .s_axis_tdata(s_data), .s_axis_tkeep(1'b1), .s_axis_tvalid(s_valid),
        .s_axis_tready(s_ready), .s_axis_tlast(s_last),
        .s_axis_tid(8'b0), .s_axis_tdest(8'b0), .s_axis_tuser(1'b0),
        .m_axis_tdata(m_data), .m_axis_tkeep(), .m_axis_tvalid(m_valid),
        .m_axis_tready(m_ready), .m_axis_tlast(m_last),
        .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser(),
        .pause_req(1'b0), .pause_ack(),
        .status_depth(), .status_depth_commit(),
        .status_overflow(), .status_bad_frame(), .status_good_frame()
    );

    integer i;
    initial begin
        repeat (4) @(posedge clk); rst = 0; m_ready = 1;
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            s_data = i[7:0];
            s_last = (i == 7);
            s_valid = 1;
            @(posedge clk);
            while (!s_ready) @(posedge clk);
            @(negedge clk);
            s_valid = 0; s_last = 0;
        end
        wait (received == 8);
        if (errors == 0) $display("AXIS FIFO: ALL TESTS PASSED");
        else $display("AXIS FIFO: TESTS FAILED (%0d)", errors);
        $finish;
    end

    always @(posedge clk) begin
        if (!rst && m_valid && m_ready) begin
            if (m_data !== received[7:0]) begin
                $display("FAIL beat=%0d got=%h", received, m_data);
                errors = errors + 1;
            end
            received = received + 1;
        end
    end

    initial begin
        #20000;
        $display("AXIS_FIFO_TB: TIMEOUT");
        $finish;
    end
endmodule
