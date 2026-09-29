module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              pclk_i,
    input              rst_i,
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output             spi_mosi_o,
    input              spi_miso_i,
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

    // Parallel interface registers
    reg [N-1:0] tx_data_pclk;
    reg tx_data_valid_pclk;
    reg tx_data_taken;

    // Synchronize tx_data_valid to sclk domain
    reg tx_data_valid_sync1, tx_data_valid_sync2;

    // SPI state machine
    localparam IDLE = 0;
    localparam TRANSMIT = 1;
    reg state;

    // Shift registers
    reg [N-1:0] shift_out;
    reg [N-1:0] shift_in;
    reg [7:0] bit_count;

    // SCK generation
    reg [15:0] clk_div_counter;
    reg sck_internal;

    // Synchronize tx_data_taken to pclk domain
    reg tx_data_taken_sync1, tx_data_taken_sync2;

    // Parallel interface logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_data_pclk <= 0;
            tx_data_valid_pclk <= 0;
            di_req_o <= 0;
            wr_ack_o <= 0;
            tx_data_taken_sync1 <= 0;
            tx_data_taken_sync2 <= 0;
        end else begin
            tx_data_taken_sync1 <= tx_data_taken;
            tx_data_taken_sync2 <= tx_data_taken_sync1;

            if (wren_i && !tx_data_valid_pclk) begin
                tx_data_pclk <= di_i;
                tx_data_valid_pclk <= 1;
                wr_ack_o <= 1;
            end

            if (tx_data_valid_pclk && tx_data_taken_sync2) begin
                tx_data_valid_pclk <= 0;
                di_req_o <= 1;
            end
        end
    end

    // Synchronize tx_data_valid to sclk domain
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            tx_data_valid_sync1 <= 0;
            tx_data_valid_sync2 <= 0;
        end else begin
            tx_data_valid_sync1 <= tx_data_valid_pclk;
            tx_data_valid_sync2 <= tx_data_valid_sync1;
        end
    end

    // SCK generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            clk_div_counter <= 0;
            sck_internal <= 0;
        end else begin
            if (clk_div_counter == SPI_2X_CLK_DIV - 1) begin
                clk_div_counter <= 0;
                sck_internal <= ~sck_internal;
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end

    assign spi_sck_o = sck_internal;

    // SPI state machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
            spi_ssel_o <= 1;
            shift_out <= 0;
            shift_in <= 0;
            bit_count <= 0;
            do_valid_o <= 0;
            do_o <= 0;
            tx_data_taken <= 0;
        end else begin
            do_valid_o <= 0;
            tx_data_taken <= 0;

            case (state)
                IDLE: begin
                    if (tx_data_valid_sync2) begin
                        shift_out <= tx_data_pclk;
                        spi_ssel_o <= 0;
                        bit_count <= N - 1;
                        state <= TRANSMIT;
                        tx_data_taken <= 1;
                    end
                end
                TRANSMIT: begin
                    if (sck_internal) begin // Rising edge
                        // Capture MISO on rising edge
                        shift_in <= {shift_in[N-2:0], spi_miso_i};
                        bit_count <= bit_count - 1;
                        if (bit_count == 0) begin
                            spi_ssel_o <= 1;
                            state <= IDLE;
                            do_o <= {shift_in[N-2:0], spi_miso_i};
                            do_valid_o <= 1;
                        end
                    end else begin // Falling edge
                        // Shift out next bit
                        shift_out <= {shift_out[N-2:0], 1'b0};
                    end
                end
            endcase
        end
    end

    assign spi_mosi_o = shift_out[N-1];

endmodule
