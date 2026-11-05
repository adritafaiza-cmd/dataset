`timescale 1ns/1ps

module axis_switch_tb;
    integer errors = 0;

    reg clk = 0, rst = 1;
    reg [7:0] s_data = 0;
    reg s_valid = 0, s_last = 0;
    reg [1:0] s_dest = 0;
    wire [1:0] s_ready;
    wire [15:0] m_data;
    wire [1:0] m_valid, m_last;
    reg [1:0] m_ready = 2'b11;
    integer got1 = 0;
    always #5 clk = ~clk;

    axis_switch #(
        .S_COUNT(2), .M_COUNT(2), .DATA_WIDTH(8),
        .KEEP_ENABLE(0), .ID_ENABLE(0), .USER_ENABLE(0),
        .M_DEST_WIDTH(1), .S_DEST_WIDTH(1),
        .S_REG_TYPE(0), .M_REG_TYPE(0)
    ) dut (
        .clk(clk), .rst(rst),
        .s_axis_tdata({8'h00, s_data}), .s_axis_tkeep(2'b11),
        .s_axis_tvalid({1'b0, s_valid}), .s_axis_tready(s_ready),
        .s_axis_tlast({1'b0, s_last}), .s_axis_tid(16'b0),
        .s_axis_tdest({1'b0, s_dest[0]}), .s_axis_tuser(2'b0),
        .m_axis_tdata(m_data), .m_axis_tkeep(), .m_axis_tvalid(m_valid),
        .m_axis_tready(m_ready), .m_axis_tlast(m_last),
        .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser()
    );

    initial begin
        repeat (4) @(posedge clk); rst = 0;
        @(negedge clk);
        s_data = 8'hA5; s_dest = 2'd1; s_last = 1; s_valid = 1;
        @(posedge clk);
        while (!s_ready[0]) @(posedge clk);
        @(negedge clk);
        s_valid = 0; s_last = 0;
        repeat (20) @(posedge clk);
        if (!got1) begin
            $display("FAIL packet did not reach port 1");
            errors = errors + 1;
        end
        if (errors == 0) $display("AXIS SWITCH: ALL TESTS PASSED");
        else $display("AXIS SWITCH: TESTS FAILED (%0d)", errors);
        $finish;
    end

    always @(posedge clk)
        if (!rst && m_valid[1] && m_ready[1] && m_data[15:8] === 8'hA5)
            got1 = 1;

    initial begin
        #20000;
        $display("AXIS_SWITCH_TB: TIMEOUT");
        $finish;
    end
endmodule
