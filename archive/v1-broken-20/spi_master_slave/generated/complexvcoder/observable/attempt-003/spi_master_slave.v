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

    // Clock domain crossing signals
    reg [N-1:0] di_i_reg;
    reg wren_i_reg;
    reg [3:0] spi_state_reg;
    reg [3:0] spi_state_next;
    reg [N-1:0] spi_tx_data_reg;
    reg [N-1:0] spi_rx_data_reg;
    reg spi_ssel_reg;
    reg spi_sck_reg;
    reg spi_mosi_reg;
    reg spi_miso_reg;

    // SPI state definitions
    parameter IDLE = 4'b0000;
    parameter SEND_DATA = 4'b0001;
    parameter RECEIVE_DATA = 4'b0010;

    // SPI controller
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_reg <= 1'b1;
            spi_sck_reg <= 1'b0;
            spi_mosi_reg <= 1'b0;
            spi_state_reg <= IDLE;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            di_i_reg <= 0;
            wren_i_reg <= 0;
        end else begin
            di_i_reg <= di_i;
            wren_i_reg <= wren_i;
            spi_state_reg <= spi_state_next;
            wr_ack_o <= (spi_state_reg == IDLE);
            do_valid_o <= (spi_state_reg == RECEIVE_DATA);
        end
    end

    // SPI state machine
    always @(*) begin
        spi_state_next = spi_state_reg;
        case (spi_state_reg)
            IDLE: begin
                if (wren_i_reg) begin
                    spi_state_next = SEND_DATA;
                    spi_tx_data_reg = di_i_reg;
                    spi_ssel_reg = 1'b0;
                end
            end
            SEND_DATA: begin
                if (spi_sck_reg) begin
                    spi_mosi_reg = spi_tx_data_reg[0];
                    spi_tx_data_reg = {spi_tx_data_reg[1:N-1], 1'b0};
                end
                if (!spi_sck_reg && spi_tx_data_reg == 0) begin
                    spi_state_next = RECEIVE_DATA;
                end
            end
            RECEIVE_DATA: begin
                if (spi_sck_reg) begin
                    spi_rx_data_reg = {spi_rx_data_reg[1:N-1], spi_miso_reg};
                end
                if (!spi_sck_reg && spi_rx_data_reg[N-1] == 1'b1) begin
                    spi_ssel_reg = 1'b1;
                    spi_state_next = IDLE;
                end
            end
        endcase
    end

    // SPI clock generation
    reg [SPI_2X_CLK_DIV-1:0] sclk_div_reg;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_reg <= 0;
            spi_sck_reg <= 1'b0;
        end else begin
            sclk_div_reg <= sclk_div_reg + 1'b1;
            if (sclk_div_reg == SPI_2X_CLK_DIV - 1) begin
                sclk_div_reg <= 0;
                spi_sck_reg <= ~spi_sck_reg;
            end
        end
    end

    // SPI interface
    assign spi_ssel_o = spi_ssel_reg;
    assign spi_sck_o = spi_sck_reg;
    assign spi_mosi_o = spi_mosi_reg;
    assign spi_miso_reg = spi_miso_i;

endmodule
