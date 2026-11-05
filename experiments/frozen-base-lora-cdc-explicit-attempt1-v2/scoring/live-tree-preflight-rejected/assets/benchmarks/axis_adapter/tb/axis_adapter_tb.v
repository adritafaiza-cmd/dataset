`timescale 1ns/1ps

module axis_adapter_tb;
    integer errors = 0;

    reg clk = 0, rst = 1;
    reg [7:0] s_data = 0;
    reg s_valid = 0, s_last = 0;
    wire s_ready;
    wire [31:0] m_data;
    wire [3:0] m_keep;
    wire m_valid, m_last;
    reg m_ready = 0;
    integer received = 0;
    always #5 clk = ~clk;

    axis_adapter #(
        .S_DATA_WIDTH(8), .S_KEEP_ENABLE(0),
        .M_DATA_WIDTH(32), .M_KEEP_ENABLE(1),
        .ID_ENABLE(0), .DEST_ENABLE(0), .USER_ENABLE(0)
    ) dut (
        .clk(clk), .rst(rst),
        .s_axis_tdata(s_data), .s_axis_tkeep(1'b1), .s_axis_tvalid(s_valid),
        .s_axis_tready(s_ready), .s_axis_tlast(s_last),
        .s_axis_tid(8'b0), .s_axis_tdest(8'b0), .s_axis_tuser(1'b0),
        .m_axis_tdata(m_data), .m_axis_tkeep(m_keep), .m_axis_tvalid(m_valid),
        .m_axis_tready(m_ready), .m_axis_tlast(m_last),
        .m_axis_tid(), .m_axis_tdest(), .m_axis_tuser()
    );

    integer i;
    initial begin
        repeat (4) @(posedge clk); rst = 0; m_ready = 1;
        for (i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            s_data = 8'h10 + i[7:0];
            s_last = ((i % 4) == 3);
            s_valid = 1;
            @(posedge clk);
            while (!s_ready) @(posedge clk);
            @(negedge clk);
            s_valid = 0; s_last = 0;
        end
        wait (received == 2);
        if (errors == 0) $display("AXIS ADAPTER: ALL TESTS PASSED");
        else $display("AXIS ADAPTER: TESTS FAILED (%0d)", errors);
        $finish;
    end

    always @(posedge clk) begin
        if (!rst && m_valid && m_ready) begin
            received = received + 1;
            if (!m_last) begin
                $display("FAIL expected tlast on packed word");
                errors = errors + 1;
            end
        end
    end

    initial begin
        #20000;
        $display("AXIS_ADAPTER_TB: TIMEOUT");
        $finish;
    end
endmodule
