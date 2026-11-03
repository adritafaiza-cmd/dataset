module uart_top (
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire [2:0] wb_adr_i,
    input wire [7:0] wb_dat_i,
    output reg [7:0] wb_dat_o,
    input wire wb_we_i,
    input wire wb_stb_i,
    input wire wb_cyc_i,
    output reg wb_ack_o,
    input wire wb_sel_i,
    output reg int_o,
    output reg stx_pad_o,
    input wire srx_pad_i,
    output reg rts_pad_o,
    input wire cts_pad_i,
    output reg dtr_pad_o,
    input wire dsr_pad_i,
    input wire ri_pad_i,
    input wire dcd_pad_i
);

    // Internal signals
    reg [7:0] rx_data;
    reg rx_ready;
    reg tx_ready;
    reg tx_empty;
    reg [7:0] divisor_latch;
    reg divisor_latch_latch;
    reg divisor_latch_load;
    reg [7:0] line_control;
    reg [7:0] modem_control;
    reg [7:0] line_status;
    reg [7:0] modem_status;
    reg [7:0] interrupt_enable;
    reg [7:0] interrupt_identification;
    reg [7:0] fifo_control;
    reg [7:0] fifo_status;

    // Instantiate Wishbone Slave Interface
    wishbone_slave wb_slave_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(wb_adr_i),
        .dat_i(wb_dat_i),
        .dat_o(wb_dat_o),
        .we_i(wb_we_i),
        .stb_i(wb_stb_i),
        .cyc_i(wb_cyc_i),
        .ack_o(wb_ack_o),
        .sel_i(wb_sel_i),
        .divisor_latch(divisor_latch),
        .divisor_latch_latch(divisor_latch_latch),
        .divisor_latch_load(divisor_latch_load),
        .line_control(line_control),
        .modem_control(modem_control),
        .line_status(line_status),
        .modem_status(modem_status),
        .interrupt_enable(interrupt_enable),
        .interrupt_identification(interrupt_identification),
        .fifo_control(fifo_control),
        .fifo_status(fifo_status)
    );

    // Instantiate UART Transmitter
    uart_transmitter tx_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .tx_o(stx_pad_o),
        .tx_data(wb_dat_i),
        .tx_ready(tx_ready),
        .tx_empty(tx_empty),
        .divisor_latch(divisor_latch),
        .line_control(line_control)
    );

    // Instantiate UART Receiver
    uart_receiver rx_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .rx_i(srx_pad_i),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .divisor_latch(divisor_latch),
        .line_control(line_control)
    );

    // Instantiate Modem Control
    modem_control modem_control_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .rts_o(rts_pad_o),
        .cts_i(cts_pad_i),
        .dtr_o(dtr_pad_o),
        .dsr_i(dsr_pad_i),
        .ri_i(ri_pad_i),
        .dcd_i(dcd_pad_i),
        .modem_control(modem_control),
        .modem_status(modem_status)
    );

    // Instantiate Interrupt Generator
    interrupt_generator int_gen_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .int_o(int_o),
        .rx_ready(rx_ready),
        .tx_empty(tx_empty),
        .interrupt_enable(interrupt_enable),
        .interrupt_identification(interrupt_identification)
    );

endmodule

// Wishbone Slave Interface
module wishbone_slave (
    input wire clk_i,
    input wire rst_i,
    input wire [2:0] adr_i,
    input wire [7:0] dat_i,
    output reg [7:0] dat_o,
    input wire we_i,
    input wire stb_i,
    input wire cyc_i,
    output reg ack_o,
    input wire sel_i,
    output reg [7:0] divisor_latch,
    input wire divisor_latch_latch,
    output reg divisor_latch_load,
    output reg [7:0] line_control,
    output reg [7:0] modem_control,
    input wire [7:0] line_status,
    input wire [7:0] modem_status,
    output reg [7:0] interrupt_enable,
    input wire [7:0] interrupt_identification,
    output reg [7:0] fifo_control,
    input wire [7:0] fifo_status
);

    reg [7:0] reg_divisor_latch;
    reg [7:0] reg_line_control;
    reg [7:0] reg_modem_control;
    reg [7:0] reg_interrupt_enable;
    reg [7:0] reg_fifo_control;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            reg_divisor_latch <= 0;
            reg_line_control <= 0;
            reg_modem_control <= 0;
            reg_interrupt_enable <= 0;
            reg_fifo_control <= 0;
            divisor_latch_load <= 0;
            ack_o <= 0;
        end else begin
            divisor_latch_load <= 0;
            ack_o <= 0;
            if (stb_i && cyc_i && sel_i) begin
                case (adr_i)
                    3'b000: begin // Divisor Latch (LSB)
                        if (we_i) begin
                            reg_divisor_latch[7:0] <= dat_i;
                            divisor_latch_load <= 1;
                        end else begin
                            dat_o <= reg_divisor_latch[7:0];
                            ack_o <= 1;
                        end
                    end
                    3'b001: begin // Divisor Latch (MSB)
                        if (we_i) begin
                            reg_divisor_latch[15:8] <= dat_i;
                            divisor_latch_load <= 1;
                        end else begin
                            dat_o <= reg_divisor_latch[15:8];
                            ack_o <= 1;
                        end
                    end
                    3'b002: begin // Interrupt Enable Register
                        if (we_i) begin
                            reg_interrupt_enable <= dat_i;
                        end else begin
                            dat_o <= reg_interrupt_enable;
                            ack_o <= 1;
                        end
                    end
                    3'b003: begin // Line Control Register
                        if (we_i) begin
                            reg_line_control <= dat_i;
                        end else begin
                            dat_o <= reg_line_control;
                            ack_o <= 1;
                        end
                    end
                    3'b004: begin // Modem Control Register
                        if (we_i) begin
                            reg_modem_control <= dat_i;
                        end else begin
                            dat_o <= reg_modem_control;
                            ack_o <= 1;
                        end
                    end
                    3'b005: begin // Line Status Register (Read-only)
                        if (!we_i) begin
                            dat_o <= line_status;
                            ack_o <= 1;
                        end
                    end
                    3'b006: begin // Modem Status Register (Read-only)
                        if (!we_i) begin
                            dat_o <= modem_status;
                            ack_o <= 1;
                        end
                    end
                    3'b007: begin // Scratch Register
                        if (we_i) begin
                            reg_fifo_control <= dat_i;
                        end else begin
                            dat_o <= reg_fifo_control;
                            ack_o <= 1;
                        end
                    end
                    default: begin
                        dat_o <= 8'b0;
                        ack_o <= 0;
                    end
                endcase
            end
        end
    end

    assign divisor_latch = divisor_latch_latch ? reg_divisor_latch : 8'b0;
    assign line_control = reg_line_control;
    assign modem_control = reg_modem_control;
    assign interrupt_enable = reg_interrupt_enable;
    assign fifo_control = reg_fifo_control;

endmodule

// UART Transmitter
module uart_transmitter (
    input wire clk_i,
    input wire rst_i,
    output reg tx_o,
    input wire [7:0] tx_data,
    input wire tx_ready,
    input wire tx_empty,
    input wire [15:0] divisor_latch,
    input wire [7:0] line_control
);

    reg [7:0] shift_reg;
    reg [3:0] bit_count;
    reg [15:0] baud_count;
    reg [15:0] baud_divisor;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_o <= 1;
            shift_reg <= 8'b0;
            bit_count <= 4'b0;
            baud_count <= 16'b0;
            baud_divisor <= 16'b0;
        end else begin
            if (tx_ready && tx_empty) begin
                shift_reg <= {1'b0, tx_data, 1'b1}; // Start bit + data + stop bit
                bit_count <= 4'd0;
                baud_count <= 16'b0;
                baud_divisor <= divisor_latch;
                tx_o <= 1'b0; // Start bit
            end else if (baud_count == baud_divisor) begin
                baud_count <= 16'b0;
                bit_count <= bit_count + 1;
                if (bit_count < 4'd9) begin
                    tx_o <= shift_reg[0];
                    shift_reg <= {1'b0, shift_reg[7:1]};
                end else begin
                    tx_o <= 1'b1; // Stop bit
                end
            end else begin
                baud_count <= baud_count + 1;
            end
        end
    end

endmodule

// UART Receiver
module uart_receiver (
    input wire clk_i,
    input wire rst_i,
    input wire rx_i,
    output reg [7:0] rx_data,
    output reg rx_ready,
    input wire [15:0] divisor_latch,
    input wire [7:0] line_control
);

    reg [7:0] shift_reg;
    reg [3:0] bit_count;
    reg [15:0] baud_count;
    reg [15:0] baud_divisor;
    reg rx_sample;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            rx_data <= 8'b0;
            rx_ready <= 0;
            shift_reg <= 8'b0;
            bit_count <= 4'b0;
            baud_count <= 16'b0;
            baud_divisor <= 16'b0;
            rx_sample <= 1'b1;
        end else begin
            rx_sample <= rx_i;
            if (baud_count == baud_divisor) begin
                baud_count <= 16'b0;
                if (bit_count == 4'd0) begin
                    if (!rx_sample) begin // Start bit detected
                        shift_reg <= 8'b0;
                        bit_count <= bit_count + 1;
                    end
                end else if (bit_count < 4'd9) begin
                    baud_count <= baud_count + 1;
                    bit_count <= bit_count + 1;
                    if (bit_count < 4'd9) begin
                        shift_reg <= {rx_sample, shift_reg[7:1]};
                    end else begin
                        rx_data <= shift_reg;
                        rx_ready <= 1;
                    end
                end else begin
                    rx_ready <= 0;
                    bit_count <= 4'b0;
                end
            end else begin
                baud_count <= baud_count + 1;
            end
        end
    end

endmodule

// Modem Control
module modem_control (
    input wire clk_i,
    input wire rst_i,
    output reg rts_o,
    input wire cts_i,
    output reg dtr_o,
    input wire dsr_i,
    input wire ri_i,
    input wire dcd_i,
    input wire [7:0] modem_control,
    input wire [7:0] modem_status
);

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            rts_o <= 0;
            dtr_o <= 0;
        end else begin
            rts_o <= modem_control[1]; // RTS bit
            dtr_o <= modem_control[0]; // DTR bit
        end
    end

endmodule

// Interrupt Generator
module interrupt_generator (
    input wire clk_i,
    input wire rst_i,
    output reg int_o,
    input wire rx_ready,
    input wire tx_empty,
    input wire [7:0] interrupt_enable,
    input wire [7:0] interrupt_identification
);

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            int_o <= 0;
        end else begin
            int_o <= (rx_ready && interrupt_enable[2]) || (tx_empty && interrupt_enable[1]);
        end
    end

endmodule
