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

    reg [N-1:0] shift_reg;
    reg [N-1:0] bit_cnt;
    reg [SPI_2X_CLK_DIV-1:0] sclk_div_cnt;
    reg spi_sck;
    reg spi_ssel;
    reg spi_mosi;
    reg di_req;
    reg wr_ack;
    reg do_valid;
    reg [N-1:0] do_reg;
    reg shift_reg_load;
    reg shift_reg_shift;
    reg do_valid_pulse;
    reg wr_ack_pulse;
    reg spi_sck_toggle;
    reg spi_ssel_toggle;

    // Parallel clock domain logic
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            shift_reg <= 0;
            bit_cnt <= 0;
            di_req_o <= 1;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
            shift_reg_load <= 0;
            shift_reg_shift <= 0;
            do_valid_pulse <= 0;
            wr_ack_pulse <= 0;
        end else begin
            // Load new data into shift register
            if (wren_i && !wr_ack) begin
                shift_reg <= di_i;
                shift_reg_load <= 1;
                wr_ack_pulse <= 1;
            end else begin
                shift_reg_load <= 0;
                wr_ack_pulse <= 0;
            end

            // Shift register shift control
            shift_reg_shift <= spi_sck && spi_ssel;

            // Bit count increment and reset
            if (spi_sck && !spi_sck_toggle && spi_ssel) begin
                bit_cnt <= bit_cnt + 1;
            end

            // Transaction completion
            if (bit_cnt == N-1 && spi_sck && !spi_sck_toggle && spi_ssel) begin
                spi_ssel_toggle <= 1;
                do_valid_pulse <= 1;
                di_req <= 1;
            end else if (spi_sck_toggle) begin
                spi_ssel_toggle <= 0;
                do_valid_pulse <= 0;
                di_req <= 0;
                bit_cnt <= 0;
            end

            // Update outputs
            wr_ack_o <= wr_ack_pulse;
            do_valid_o <= do_valid_pulse;
            do_o <= do_reg;
            di_req_o <= di_req;
        end
    end

    // Serial clock domain logic
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_sck <= 0;
            spi_ssel <= 0;
            spi_mosi <= 0;
            do_reg <= 0;
            spi_sck_toggle <= 0;
        end else begin
            // SPI SCK toggle logic
            if (sclk_div_cnt == SPI_2X_CLK_DIV-1) begin
                spi_sck <= ~spi_sck;
                spi_sck_toggle <= ~spi_sck_toggle;
                sclk_div_cnt <= 0;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end

            // SPI SSEL toggle logic
            if (shift_reg_load) begin
                spi_ssel <= 1;
            end else if (spi_ssel_toggle) begin
                spi_ssel <= 0;
            end

            // Shift register and MOSI output
            if (shift_reg_shift) begin
                spi_mosi <= shift_reg[N-1];
                shift_reg <= {shift_reg[N-2:0], 1'b0};
            end

            // MISO input capture
            if (spi_sck && spi_ssel) begin
                do_reg <= {do_reg[N-2:0], spi_miso_i};
            end
        end
    end

    // Continuous assignments
    assign spi_ssel_o = spi_ssel;
    assign spi_sck_o = spi_sck;
    assign spi_mosi_o = spi_mosi;

endmodule
