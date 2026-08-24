`timescale 1ns/1ps

module i2c_master_tb;
    integer errors = 0;

    reg clk = 0;
    reg rst = 1;
    always #5 clk = ~clk;

    wire scl_m_o, scl_m_t, sda_m_o, sda_m_t;
    wire scl_s_o, scl_s_t, sda_s_o, sda_s_t;
    // Open-drain bus: either side may pull the line low.
    wire scl = scl_m_o & scl_s_o;
    wire sda = sda_m_o & sda_s_o;

    reg  [6:0] cmd_addr = 7'h50;
    reg        cmd_write = 0;
    reg        cmd_stop = 0;
    reg        cmd_valid = 0;
    wire       cmd_ready;
    wire       busy, missed_ack;

    reg  [7:0] wr_data = 8'hA5;
    reg        wr_valid = 0;
    reg        wr_last = 0;
    wire       wr_ready;

    wire [7:0] slv_rx_data;
    wire       slv_rx_valid;
    integer    slv_got = 0;
    reg  [7:0] slv_byte = 8'h00;

    i2c_master dut (
        .clk(clk),
        .rst(rst),
        .s_axis_cmd_address(cmd_addr),
        .s_axis_cmd_start(1'b0),
        .s_axis_cmd_read(1'b0),
        .s_axis_cmd_write(cmd_write),
        .s_axis_cmd_write_multiple(1'b0),
        .s_axis_cmd_stop(cmd_stop),
        .s_axis_cmd_valid(cmd_valid),
        .s_axis_cmd_ready(cmd_ready),
        .s_axis_data_tdata(wr_data),
        .s_axis_data_tvalid(wr_valid),
        .s_axis_data_tready(wr_ready),
        .s_axis_data_tlast(wr_last),
        .m_axis_data_tdata(),
        .m_axis_data_tvalid(),
        .m_axis_data_tready(1'b1),
        .m_axis_data_tlast(),
        .scl_i(scl),
        .scl_o(scl_m_o),
        .scl_t(scl_m_t),
        .sda_i(sda),
        .sda_o(sda_m_o),
        .sda_t(sda_m_t),
        .busy(busy),
        .bus_control(),
        .bus_active(),
        .missed_ack(missed_ack),
        .prescale(16'd8),
        .stop_on_idle(1'b0)
    );

    i2c_slave #(.FILTER_LEN(1)) slave (
        .clk(clk),
        .rst(rst),
        .release_bus(1'b0),
        .s_axis_data_tdata(8'h00),
        .s_axis_data_tvalid(1'b0),
        .s_axis_data_tready(),
        .s_axis_data_tlast(1'b0),
        .m_axis_data_tdata(slv_rx_data),
        .m_axis_data_tvalid(slv_rx_valid),
        .m_axis_data_tready(1'b1),
        .m_axis_data_tlast(),
        .scl_i(scl),
        .scl_o(scl_s_o),
        .scl_t(scl_s_t),
        .sda_i(sda),
        .sda_o(sda_s_o),
        .sda_t(sda_s_t),
        .busy(),
        .bus_address(),
        .bus_addressed(),
        .bus_active(),
        .enable(1'b1),
        .device_address(7'h50),
        .device_address_mask(7'h7F)
    );

    always @(posedge clk) begin
        if (!rst && slv_rx_valid) begin
            slv_byte = slv_rx_data;
            slv_got = slv_got + 1;
        end
    end

    initial begin
        repeat (4) @(posedge clk);
        rst = 0;
        repeat (8) @(posedge clk);
        if (busy !== 1'b0) begin
            $display("FAIL master busy after reset");
            errors = errors + 1;
        end

        wr_data = 8'hA5;
        wr_last = 1;
        wr_valid = 1;
        cmd_write = 1;
        cmd_stop = 1;
        cmd_valid = 1;

        @(posedge clk);
        while (!cmd_ready) @(posedge clk);
        @(negedge clk);
        cmd_valid = 0;
        cmd_write = 0;
        cmd_stop = 0;
        while (wr_valid && !wr_ready) @(posedge clk);
        @(negedge clk);
        wr_valid = 0;
        wr_last = 0;

        wait (slv_got > 0);
        repeat (20) @(posedge clk);

        if (slv_byte !== 8'hA5) begin
            $display("FAIL slave received %h", slv_byte);
            errors = errors + 1;
        end
        if (missed_ack) begin
            $display("FAIL missed ACK");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("I2C MASTER: ALL TESTS PASSED");
        else
            $display("I2C MASTER: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #200000;
        $display("I2C_MASTER_TB: TIMEOUT");
        $finish;
    end
endmodule
