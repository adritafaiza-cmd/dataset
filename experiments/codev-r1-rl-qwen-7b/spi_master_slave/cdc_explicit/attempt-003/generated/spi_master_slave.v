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

// PCLK domain signals
reg [N-1:0] data_p;
reg data_valid_p;
reg di_req_p;
reg wr_ack_p;

// CDC synchronization from PCLK to SCLK
reg data_valid_sync1, data_valid_sync2;

// CDC synchronization from SCLK to PCLK for done
reg done_s_reg;
reg done_sync1_p, done_sync2_p;

// SCLK domain signals
reg [N-1:0] shift_reg;
reg [N-1:0] miso_shift;
reg [31:0] bit_counter;
reg state;
reg sck_reg;
reg [15:0] clk_div_counter;

localparam IDLE = 0, TRANSFER = 1;

// PCLK domain logic
always @(posedge pclk_i) begin
    if (rst_i) begin
        data_valid_p <= 0;
        di_req_p <= 1;
        data_p <= 0;
        wr_ack_p <= 0;
    end else begin
        wr_ack_p <= 0;
        done_s_reg <= 0;

        // Handle data write
        if (wren_i && di_req_p) begin
            data_p <= di_i;
            data_valid_p <= 1;
            di_req_p <= 0;
            wr_ack_p <= 1;
        end

        // Handle done signal from SCLK domain
        if (done_sync2_p) begin
            data_valid_p <= 0;
            di_req_p <= 1;
        end
    end
end

assign wr_ack_o = wr_ack_p;
assign di_req_o = di_req_p;

// CDC: data_valid_p to SCLK domain
always @(posedge sclk_i) begin
    if (rst_i) begin
        data_valid_sync1 <= 0;
        data_valid_sync2 <= 0;
    end else begin
        data_valid_sync1 <= data_valid_p;
        data_valid_sync2 <= data_valid_sync1;
    end
end

// SCLK domain logic
always @(posedge sclk_i) begin
    if (rst_i) begin
        state <= IDLE;
        spi_ssel_o <= 1;
        shift_reg <= 0;
        miso_shift <= 0;
        bit_counter <= 0;
        done_s_reg <= 0;
        sck_reg <= 0;
        clk_div_counter <= 0;
        do_o <= 0;
        do_valid_o <= 0;
    end else begin
        done_s_reg <= 0;
        do_valid_o <= 0;

        // CDC: done_s_reg to PCLK domain
        done_sync1_p <= done_s_reg;
        done_sync2_p <= done_sync1_p;

        case (state)
            IDLE: begin
                if (data_valid_sync2) begin
                    spi_ssel_o <= 0;
                    shift_reg <= data_p;
                    miso_shift <= 0;
                    bit_counter <= N;
                    state <= TRANSFER;
                    clk_div_counter <= 0;
                    sck_reg <= 0;
                end
            end
            TRANSFER: begin
                if (clk_div_counter == SPI_2X_CLK_DIV -1) begin
                    clk_div_counter <= 0;
                    sck_reg <= ~sck_reg;

                    if (sck_reg) begin // Falling edge, shift data out
                        shift_reg <= shift_reg << 1;
                    end else begin // Rising edge, sample MISO
                        miso_shift <= {miso_shift[N-2:0], spi_miso_i};
                    end

                    bit_counter <= bit_counter - 1;

                    if (bit_counter == 1) begin
                        state <= IDLE;
                        spi_ssel_o <= 1;
                        do_o <= {miso_shift[N-2:0], spi_miso_i};
                        do_valid_o <= 1;
                        done_s_reg <= 1;
                    end
                end else begin
                    clk_div_counter <= clk_div_counter + 1;
                end
            end
        endcase
    end
end

assign spi_sck_o = sck_reg;
assign spi_mosi_o = shift_reg[N-1]; // MSB first

endmodule
